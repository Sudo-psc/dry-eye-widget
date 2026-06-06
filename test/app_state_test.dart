import 'package:flutter_test/flutter_test.dart';
import 'package:dry_eye_widget/models/app_state.dart';
import 'package:dry_eye_widget/utils/constants.dart';

void main() {
  group('AppState', () {
    test('apenas IDLE é inativo (bolinha azul)', () {
      expect(AppState.idle.isActive, isFalse);
      for (final s in AppState.values.where((s) => s != AppState.idle)) {
        expect(s.isActive, isTrue, reason: '$s deveria ser ativo');
      }
    });

    test('há uma única fase de pausa', () {
      final fases = AppState.values.where((s) => s.showsCountdown).toList();
      expect(fases, [AppState.fase1]);
    });

    test('countdown aparece somente na fase de pausa', () {
      expect(AppState.fase1.showsCountdown, isTrue);
      expect(AppState.alerta.showsCountdown, isFalse);
      expect(AppState.conclusao.showsCountdown, isFalse);
      expect(AppState.idle.showsCountdown, isFalse);
    });

    test('textos de cada estado batem com as constantes', () {
      expect(AppState.fase1.title, AppTexts.phaseTitle);
      expect(AppState.fase1.subtitle, contains('piscar'));
      expect(AppState.conclusao.title, AppTexts.doneTitle);
      expect(AppState.idle.title, isEmpty);
    });
  });

  group('BallCorner', () {
    test('todos os cantos têm rótulo legível', () {
      for (final c in BallCorner.values) {
        expect(c.label, isNotEmpty);
      }
    });
  });

  group('Constantes', () {
    test('durações padrão seguem a regra 20-20-20', () {
      expect(AppDurations.defaultCycle, const Duration(minutes: 20));
      expect(AppDurations.defaultPhase, const Duration(seconds: 20));
    });
  });
}
