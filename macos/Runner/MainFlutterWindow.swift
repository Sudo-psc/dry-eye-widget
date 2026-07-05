import AVFoundation
import ApplicationServices
import Cocoa
import CoreGraphics
import FlutterMacOS
import Security
import Vision

class MainFlutterWindow: NSWindow {
  private var faceDetector: FaceDetector?
  private let activityMonitor = ActivityMonitor()

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // Canal de tempo ocioso do sistema (segundos desde a última entrada do
    // usuário — mouse, cliques, teclas — em todo o sistema).
    let idleChannel = FlutterMethodChannel(
      name: "dry_eye_widget/idle",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    idleChannel.setMethodCallHandler { (call, result) in
      if call.method == "idleSeconds" {
        let types: [CGEventType] = [
          .mouseMoved, .leftMouseDown, .rightMouseDown, .keyDown,
          .scrollWheel, .leftMouseDragged, .rightMouseDragged, .otherMouseDown,
        ]
        let idle = types
          .map { CGEventSource.secondsSinceLastEventType(.hidSystemState, eventType: $0) }
          .min() ?? 0
        result(idle)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    // Canal de armazenamento seguro: o Keychain cifra os valores em repouso.
    // Guarda apenas o estado agregado do modelo de presença (sem histórico).
    let secureChannel = FlutterMethodChannel(
      name: "dry_eye_widget/secure_store",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    let service = "dry_eye_widget"
    secureChannel.setMethodCallHandler { (call, result) in
      let args = call.arguments as? [String: Any]
      guard let key = args?["key"] as? String else {
        result(FlutterError(code: "bad_args", message: "key ausente", details: nil))
        return
      }
      let base: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: service,
        kSecAttrAccount as String: key,
      ]
      switch call.method {
      case "read":
        var query = base
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecSuccess, let data = item as? Data {
          result(String(data: data, encoding: .utf8))
        } else {
          result(nil)
        }
      case "write":
        guard let value = args?["value"] as? String else {
          result(FlutterError(code: "bad_args", message: "value ausente", details: nil))
          return
        }
        SecItemDelete(base as CFDictionary)
        var add = base
        add[kSecValueData as String] = value.data(using: .utf8)
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(add as CFDictionary, nil)
        result(nil)
      case "delete":
        SecItemDelete(base as CFDictionary)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    // Canal de detecção de presença por rosto (Vision, on-device). Captura 1
    // frame, detecta rosto e descarta a imagem; nada é gravado nem enviado.
    let visionChannel = FlutterMethodChannel(
      name: "dry_eye_widget/vision",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    visionChannel.setMethodCallHandler { [weak self] (call, result) in
      if call.method == "hasFace" {
        // Uma detecção por vez: se já houver uma em andamento, responde "sem
        // rosto" em vez de sobrescrever o detector ativo.
        guard self?.faceDetector == nil else {
          result(false)
          return
        }
        let detector = FaceDetector()
        self?.faceDetector = detector
        detector.detect { hasFace in
          result(hasFace)
          self?.faceDetector = nil
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    // Canal de detecção de tela cheia: indica se o app em primeiro plano (que
    // não seja este widget) ocupa uma tela inteira. Lê apenas metadados de
    // janela (CGWindowList) — não captura conteúdo, então não exige permissão
    // de gravação de tela.
    let displayChannel = FlutterMethodChannel(
      name: "dry_eye_widget/display",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    displayChannel.setMethodCallHandler { (call, result) in
      if call.method == "frontmostFullscreen" {
        result(MainFlutterWindow.frontmostAppIsFullscreen())
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    // Canal de monitoramento de atividade (opt-in): conta cliques e teclas
    // (apenas QUANTIDADES — nunca quais teclas) e o app em primeiro plano.
    // Cliques e app em foco não exigem permissão; a contagem de teclas usa um
    // monitor global de eventos, que requer permissão de Acessibilidade.
    let activityChannel = FlutterMethodChannel(
      name: "dry_eye_widget/activity",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    activityChannel.setMethodCallHandler { [weak self] (call, result) in
      guard let monitor = self?.activityMonitor else {
        result(FlutterMethodNotImplemented)
        return
      }
      switch call.method {
      case "start":
        monitor.start()
        result(nil)
      case "stop":
        monitor.stop()
        result(nil)
      case "poll":
        result(monitor.poll())
      case "hasKeyPermission":
        result(AXIsProcessTrusted())
      case "openPermissionSettings":
        if let url = URL(
          string:
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
        {
          NSWorkspace.shared.open(url)
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    super.awakeFromNib()
  }

  /// Heurística de tela cheia: o app frontmost tem uma janela de nível normal
  /// (layer 0) que cobre uma tela inteira — incluindo a faixa da barra de
  /// menus, o que a distingue de uma janela apenas maximizada. Usa só metadados
  /// de janela; não acessa o conteúdo de nenhuma janela.
  static func frontmostAppIsFullscreen() -> Bool {
    guard let frontApp = NSWorkspace.shared.frontmostApplication else { return false }
    let pid = frontApp.processIdentifier
    // Ignora o próprio widget.
    if pid == ProcessInfo.processInfo.processIdentifier { return false }
    guard let infoList = CGWindowListCopyWindowInfo(
      [.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
      as? [[String: Any]] else { return false }
    let screenSizes = NSScreen.screens.map { $0.frame.size }
    for info in infoList {
      // Os números do CGWindowList chegam como NSNumber; `as? Int` faz o bridge
      // de forma confiável (`as? pid_t`/Int32 retornaria nil).
      guard let ownerPID = info[kCGWindowOwnerPID as String] as? Int,
        ownerPID == Int(pid),
        let layer = info[kCGWindowLayer as String] as? Int,
        layer == 0,
        let boundsDict = info[kCGWindowBounds as String] as? [String: Any],
        let bounds = CGRect(dictionaryRepresentation: boundsDict as CFDictionary)
      else { continue }
      for size in screenSizes {
        if bounds.width >= size.width - 1 && bounds.height >= size.height - 1 {
          return true
        }
      }
    }
    return false
  }

  // Janela transparente, sem fundo, sempre no topo e em todos os Spaces.
  // Boa parte é redundante com o window_manager, mas garante o comportamento
  // já no primeiro frame, evitando "flash" de fundo opaco.
  override var canBecomeKey: Bool { return true }
  override var canBecomeMain: Bool { return true }

  override func order(_ place: NSWindow.OrderingMode, relativeTo otherWin: Int) {
    super.order(place, relativeTo: otherWin)
    self.isOpaque = false
    self.backgroundColor = .clear
    self.hasShadow = false
    self.level = .floating
    self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
  }
}

/// Monitor de atividade local: acumula contagens de cliques e teclas (apenas
/// QUANTIDADES — jamais quais teclas) e o nome do app em primeiro plano.
///
/// Privacidade: nada é gravado nem enviado; os contadores vivem em memória e
/// são zerados a cada `poll`. Cliques e app em foco usam APIs que não exigem
/// permissão; a contagem de teclas usa um monitor GLOBAL de eventos, que só
/// funciona com permissão de Acessibilidade concedida pelo usuário.
final class ActivityMonitor {
  private var clickMonitor: Any?
  private var keyMonitor: Any?
  private var clicks = 0
  private var keys = 0
  private let lock = NSLock()

  func start() {
    stop()
    // Cliques do mouse (esquerdo/direito/outros), globalmente.
    clickMonitor = NSEvent.addGlobalMonitorForEvents(
      matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
    ) { [weak self] _ in
      guard let self = self else { return }
      self.lock.lock(); self.clicks += 1; self.lock.unlock()
    }
    // Teclas pressionadas — SÓ conta; nunca inspeciona qual tecla. Exige
    // permissão de Acessibilidade (senão o monitor simplesmente não dispara).
    keyMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) {
      [weak self] _ in
      guard let self = self else { return }
      self.lock.lock(); self.keys += 1; self.lock.unlock()
    }
  }

  func stop() {
    if let m = clickMonitor { NSEvent.removeMonitor(m); clickMonitor = nil }
    if let m = keyMonitor { NSEvent.removeMonitor(m); keyMonitor = nil }
  }

  /// Devolve as contagens acumuladas + o app em foco, e ZERA os contadores.
  func poll() -> [String: Any] {
    lock.lock()
    let c = clicks
    let k = keys
    clicks = 0
    keys = 0
    lock.unlock()
    var frontApp = ""
    if let app = NSWorkspace.shared.frontmostApplication,
      app.processIdentifier != ProcessInfo.processInfo.processIdentifier
    {
      frontApp = app.localizedName ?? ""
    }
    return ["clicks": c, "keys": k, "frontApp": frontApp]
  }

  deinit { stop() }
}

/// Detecta presença de rosto capturando um único frame da webcam e rodando o
/// framework Vision. A sessão é encerrada e a imagem descartada após a
/// detecção; nada é persistido em disco nem enviado pela rede.
final class FaceDetector: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
  private let session = AVCaptureSession()
  private let queue = DispatchQueue(label: "dry_eye_widget.vision")
  private var completion: ((Bool) -> Void)?
  private var finished = false

  func detect(completion: @escaping (Bool) -> Void) {
    self.completion = completion
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
      configureAndStart()
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
        granted ? self?.configureAndStart() : self?.finish(false)
      }
    default:
      finish(false)
    }
  }

  private func configureAndStart() {
    queue.async {
      guard let device = AVCaptureDevice.default(for: .video),
        let input = try? AVCaptureDeviceInput(device: device),
        self.session.canAddInput(input)
      else {
        self.finish(false)
        return
      }
      self.session.addInput(input)
      let output = AVCaptureVideoDataOutput()
      output.setSampleBufferDelegate(self, queue: self.queue)
      guard self.session.canAddOutput(output) else {
        self.finish(false)
        return
      }
      self.session.addOutput(output)
      self.session.startRunning()
      // Segurança: se nenhum frame chegar em 3 s, encerra como "sem rosto".
      self.queue.asyncAfter(deadline: .now() + 3.0) { self.finish(false) }
    }
  }

  func captureOutput(
    _ output: AVCaptureOutput,
    didOutput sampleBuffer: CMSampleBuffer,
    from connection: AVCaptureConnection
  ) {
    if finished { return }
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
    let request = VNDetectFaceRectanglesRequest()
    let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
    try? handler.perform([request])
    let hasFace = !(request.results?.isEmpty ?? true)
    finish(hasFace)
  }

  private func finish(_ value: Bool) {
    queue.async {
      if self.finished { return }
      self.finished = true
      if self.session.isRunning { self.session.stopRunning() }
      let callback = self.completion
      self.completion = nil
      DispatchQueue.main.async { callback?(value) }
    }
  }
}
