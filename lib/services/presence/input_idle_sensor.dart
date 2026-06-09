import '../idle_service.dart';
import 'presence_sensor.dart';

/// Sensor de presença baseado na ociosidade global do SO (teclado/mouse).
/// Sozinho nunca decide ausência — apenas reporta atividade recente; a
/// decisão de limiar fica no [PresenceController]. Exposto como sensor para
/// uniformidade e testes.
class InputIdleSensor implements PresenceSensor {
  InputIdleSensor(this._idle, {this.activityWindowSeconds = 2});

  final IdleService _idle;
  final int activityWindowSeconds;

  @override
  Future<Presence> sample() async {
    final idle = await _idle.idleSeconds();
    return idle < activityWindowSeconds ? Presence.present : Presence.unknown;
  }
}
