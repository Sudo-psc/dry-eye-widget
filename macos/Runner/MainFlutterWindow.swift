import Cocoa
import CoreGraphics
import FlutterMacOS

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
