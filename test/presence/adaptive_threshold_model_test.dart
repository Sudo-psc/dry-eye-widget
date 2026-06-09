import 'package:flutter_test/flutter_test.dart';
import 'package:dry_eye_widget/services/presence/adaptive_threshold_model.dart';

void main() {
  group('AdaptiveThresholdModel', () {
    test('cold start retorna o limiar padrão antes de observações', () {
      final m = AdaptiveThresholdModel();
      expect(m.thresholdForHour(10), 120);
    });

    test('aprende o P85 das durações observadas no bucket', () {
      final m = AdaptiveThresholdModel(minObservations: 5);
      // 10 gaps de presença ~ 30..120s no bucket da tarde (12-18h).
      for (final g in [30, 45, 60, 60, 75, 90, 90, 105, 120, 120]) {
        m.observePresentGap(14, g.toDouble());
      }
      final t = m.thresholdForHour(14);
      // P85 de 10 amostras -> bin superior na faixa 120..150, clamp [60,600].
      expect(t, inInclusiveRange(120, 150));
    });

    test('respeita o clamp mínimo de 60s', () {
      final m = AdaptiveThresholdModel(minObservations: 1);
      m.observePresentGap(3, 5);
      expect(m.thresholdForHour(3), 60);
    });

    test('respeita o clamp máximo de 600s', () {
      final m = AdaptiveThresholdModel(minObservations: 1);
      for (var i = 0; i < 20; i++) {
        m.observePresentGap(3, 5000);
      }
      // 5000 > maxLearnableGap(900) -> não aprende -> ainda cold start? Não:
      // counts permanece 0, então cold start. Ajuste: usar gaps aprendíveis.
      m.observePresentGap(3, 880);
      expect(m.thresholdForHour(3), inInclusiveRange(600, 600));
    });

    test('buckets horários são independentes', () {
      final m = AdaptiveThresholdModel(minObservations: 1);
      m.observePresentGap(2, 300); // madrugada
      // tarde nunca observou -> cold start.
      expect(m.thresholdForHour(14), 120);
      expect(m.thresholdForHour(2), greaterThan(120));
    });

    test('gaps acima do máximo aprendível são ignorados', () {
      final m = AdaptiveThresholdModel(minObservations: 1);
      m.observePresentGap(14, 5000);
      expect(m.thresholdForHour(14), 120); // continua cold start
    });

    test('round-trip toMap/fromMap preserva o estado aprendido', () {
      final m = AdaptiveThresholdModel(minObservations: 1);
      m.observePresentGap(14, 200);
      final restored = AdaptiveThresholdModel.fromMap(m.toMap());
      expect(restored.thresholdForHour(14), m.thresholdForHour(14));
    });
  });
}
