import 'presence_sensor.dart';
import 'adaptive_threshold_model.dart';

/// Decide presença/ausência combinando o limiar adaptativo (input) com um
/// sensor de câmera opcional, e alimenta o modelo nos eventos de retomada.
class PresenceController {
  PresenceController({
    required this.model,
    required Future<double> Function() idleSource,
    this.cameraSensor,
    bool Function()? cameraEnabled,
  })  : _idleSource = idleSource,
        cameraEnabled = cameraEnabled ?? (() => false);

  final AdaptiveThresholdModel model;
  final PresenceSensor? cameraSensor;
  final bool Function() cameraEnabled;
  final Future<double> Function() _idleSource;

  /// Ociosidade global do SO (segundos). Delega à fonte injetada.
  Future<double> idleSeconds() => _idleSource();

  int? _lastObservedGap;
  int? get lastObservedGap => _lastObservedGap;

  /// Limiar vigente para a hora (exposto para diagnóstico/integração).
  int thresholdAt(DateTime now) => model.thresholdForHour(now.hour);

  /// Avalia o estado atual dado o tempo ocioso do SO.
  Future<Presence> evaluate({
    required double idleSeconds,
    required DateTime now,
  }) async {
    final threshold = model.thresholdForHour(now.hour);
    if (idleSeconds < threshold) return Presence.present;

    // Cruzou o limiar: desempata pela câmera, se habilitada.
    final cam = cameraSensor;
    if (cameraEnabled() && cam != null) {
      final p = await cam.sample();
      if (p == Presence.present) {
        // Confirmação direta de presença parada: aprende este gap.
        model.observePresentGap(now.hour, idleSeconds);
        _lastObservedGap = idleSeconds.round();
        return Presence.present;
      }
    }
    return Presence.absent;
  }

  /// Chamado quando o input retoma após um período ocioso. O gap anterior é
  /// tratado como "presença parada" e alimenta o modelo.
  void onResume({required double previousIdleSeconds, required DateTime now}) {
    model.observePresentGap(now.hour, previousIdleSeconds);
    _lastObservedGap = previousIdleSeconds.round();
  }
}
