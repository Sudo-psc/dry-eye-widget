import Cocoa
import CoreGraphics
import FlutterMacOS
import Security

class MainFlutterWindow: NSWindow {
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
