import 'package:flutter/foundation.dart';
import 'package:local_notifier/local_notifier.dart';

/// Notificações nativas do sistema (macOS / Windows) via local_notifier.
class NotificationService {
  bool enabled = true;
  bool _ready = false;

  /// Inicializa o local_notifier. Deve ser chamado no boot, após
  /// [WidgetsFlutterBinding.ensureInitialized].
  Future<void> init() async {
    try {
      await localNotifier.setup(
        appName: 'Dry Eye Widget',
        // Em Windows o GUID é opcional para notificações simples.
        shortcutPolicy: ShortcutPolicy.requireCreate,
      );
      _ready = true;
    } catch (e) {
      debugPrint('NotificationService: setup falhou ($e).');
      _ready = false;
    }
  }

  Future<void> show(String title, String body) async {
    if (!enabled || !_ready) return;
    try {
      final notification = LocalNotification(title: title, body: body);
      await notification.show();
    } catch (e) {
      debugPrint('NotificationService: falha ao exibir notificação ($e).');
    }
  }

  /// Notificação de início da pausa.
  Future<void> notifyBreakStart() =>
      show('Hora da pausa 👀', 'Descanse os olhos por alguns segundos.');

  /// Notificação ao concluir o ciclo de pausas.
  Future<void> notifyBreakDone() =>
      show('Pausa concluída ✅', 'Lágrimas renovadas! Voltando ao trabalho.');
}
