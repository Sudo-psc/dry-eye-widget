import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_notifier/local_notifier.dart';

/// Notificações nativas; MSIX usa a identidade informada pelo próprio Windows.
class NotificationService {
  NotificationService({TargetPlatform? platform})
    : _platform = platform ?? defaultTargetPlatform;

  static const _windowsStore = MethodChannel('dry_eye_widget/windows_store');
  final TargetPlatform _platform;
  bool enabled = true;
  bool _ready = false;
  bool _packaged = false;

  /// Deve ser chamado após [WidgetsFlutterBinding.ensureInitialized].
  Future<void> init() async {
    _ready = false;
    try {
      if (!kIsWeb && _platform == TargetPlatform.windows) {
        final packaged = await _windowsStore.invokeMethod<bool>('isPackaged');
        if (packaged == null) {
          throw StateError('Windows did not return its package identity');
        }
        _packaged = packaged;
        if (_packaged) {
          _ready =
              await _windowsStore.invokeMethod<bool>(
                'initializeNotifications',
              ) ??
              false;
          return;
        }
      }
      await localNotifier.setup(
        appName: 'Dry Eye Widget',
        shortcutPolicy: ShortcutPolicy.requireCreate,
      );
      _ready = true;
    } catch (e) {
      debugPrint('NotificationService: setup falhou ($e).');
      _ready = false;
    }
  }

  Future<void> show(String title, String body, {bool force = false}) async {
    if ((!enabled && !force) || !_ready) return;
    try {
      if (_packaged) {
        await _windowsStore.invokeMethod<bool>('showNotification', {
          'title': title,
          'body': body,
        });
      } else {
        final notification = LocalNotification(title: title, body: body);
        await notification.show();
      }
    } catch (e) {
      debugPrint('NotificationService: falha ao exibir notificação ($e).');
    }
  }

  /// Ignora a preferência interna, respeitando bloqueios do sistema.
  /// Usado quando o overlay não pode aparecer, como em tela cheia.
  Future<void> showForced(String title, String body) =>
      show(title, body, force: true);

  Future<void> notifyBreakStart(String title, String body) => show(title, body);

  Future<void> notifyBreakDone(String title, String body) => show(title, body);
}
