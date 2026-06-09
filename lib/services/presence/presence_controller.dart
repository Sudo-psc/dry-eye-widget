import 'presence_sensor.dart';
import 'adaptive_threshold_model.dart';
import 'presence_store.dart';

/// Decide presença/ausência combinando o limiar adaptativo (input) com um
/// sensor de câmera opcional, e alimenta o modelo nos eventos de retomada.
class PresenceController {
  PresenceController({
    required this.model,
    required this.idleSource,
    this.cameraSensor,
    this.store,
    this.saveEveryN = 5,
    bool Function()? cameraEnabled,
  }) : cameraEnabled = cameraEnabled ?? (() => false);

  final AdaptiveThresholdModel model;
  final PresenceSensor? cameraSensor;
  final bool Function() cameraEnabled;

  /// Fonte de ociosidade global do SO (segundos).
  final Future<double> Function() idleSource;

  /// Persistência opcional do estado agregado (cifrada). Quando ausente, o
  /// modelo vive só em memória (reaprende a cada sessão).
  final PresenceStore? store;

  /// Salva o estado a cada N observações novas, para limitar gravações.
  final int saveEveryN;
  int _obsSinceSave = 0;

  /// Ociosidade global do SO (segundos). Delega à fonte injetada.
  Future<double> idleSeconds() => idleSource();

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
        _persistSoon();
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
    _persistSoon();
  }

  /// Carrega o estado persistido (se houver) para dentro do modelo.
  Future<void> hydrate() async {
    final saved = await store?.load();
    if (saved != null) model.loadFrom(saved);
  }

  /// Apaga todo o aprendizado, em memória e no armazenamento.
  Future<void> reset() async {
    model.reset();
    _obsSinceSave = 0;
    await store?.clear();
  }

  /// Persiste o estado após acumular [saveEveryN] observações (fire-and-forget).
  void _persistSoon() {
    if (store == null) return;
    if (++_obsSinceSave < saveEveryN) return;
    _obsSinceSave = 0;
    store!.save(model.toMap());
  }
}
