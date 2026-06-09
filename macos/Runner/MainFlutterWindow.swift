import AVFoundation
import Cocoa
import CoreGraphics
import FlutterMacOS
import Security
import Vision

class MainFlutterWindow: NSWindow {
  private var faceDetector: FaceDetector?

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

    super.awakeFromNib()
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
