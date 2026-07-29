import 'package:flutter_test/flutter_test.dart';

import 'package:dry_eye_widget/models/dvrs_assessment.dart';
import 'package:dry_eye_widget/services/dvrs_engine.dart';

/// Layout canônico dos domínios do DVRS por índice (0-based):
/// Q1–Q6 sintomas, Q7–Q9 funcional, Q10–Q12 exposição, Q13–Q15 ambiente,
/// Q16 sinais de alerta.
DvrsDomain _domainForIndex(int i) {
  if (i < 6) return DvrsDomain.symptoms;
  if (i < 9) return DvrsDomain.functional;
  if (i < 12) return DvrsDomain.exposure;
  if (i < 15) return DvrsDomain.environment;
  return DvrsDomain.warning;
}

/// Constrói as 16 respostas a partir de 16 valores (0–4).
List<DvrsAnswer> _answers(List<int> values) {
  assert(values.length == 16);
  return [
    for (var i = 0; i < 16; i++)
      DvrsAnswer(
        questionId: 'q${i + 1}',
        domain: _domainForIndex(i),
        value: values[i],
        label: 'opt',
      ),
  ];
}

List<int> _filled(int v) => List<int>.filled(16, v);

void main() {
  group('calculateDvrsDomainScores', () {
    test('todas as respostas em 0 zeram os domínios', () {
      final scores = calculateDvrsDomainScores(_answers(_filled(0)));
      expect(scores.symptoms, 0);
      expect(scores.functional, 0);
      expect(scores.exposure, 0);
      expect(scores.environment, 0);
      expect(scores.warning, 0);
    });

    test('todas as respostas no máximo (4) normalizam para 100', () {
      final scores = calculateDvrsDomainScores(_answers(_filled(4)));
      expect(scores.symptoms, 100);
      expect(scores.functional, 100);
      expect(scores.exposure, 100);
      expect(scores.environment, 100);
      expect(scores.warning, 100);
    });

    test('normaliza cada domínio pela soma / (nº perguntas * 4) * 100', () {
      // Sintomas soma 12 de 24 => 50; funcional 6 de 12 => 50; exposição 6 => 50;
      // ambiente 6 => 50; alerta 2 de 4 => 50.
      final values = [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2];
      final scores = calculateDvrsDomainScores(_answers(values));
      expect(scores.symptoms, 50);
      expect(scores.functional, 50);
      expect(scores.exposure, 50);
      expect(scores.environment, 50);
      expect(scores.warning, 50);
    });
  });

  group('calculateDvrsTotalScore', () {
    test('domínios todos 0 => total 0', () {
      final scores = calculateDvrsDomainScores(_answers(_filled(0)));
      expect(calculateDvrsTotalScore(scores), 0);
    });

    test('domínios todos 100 => total 100', () {
      final scores = calculateDvrsDomainScores(_answers(_filled(4)));
      expect(calculateDvrsTotalScore(scores), 100);
    });

    test('aplica os pesos 0.35/0.25/0.20/0.15/0.05', () {
      // Todos normalizados em 50 => 50.
      final scores = calculateDvrsDomainScores(
        _answers(List<int>.filled(16, 2)),
      );
      expect(calculateDvrsTotalScore(scores), 50);
    });

    test('apenas sinais de alerta no máximo => total ≈ 5 (peso 0.05)', () {
      final values = _filled(0)..[15] = 4; // só Q16 = 4
      final scores = calculateDvrsDomainScores(_answers(values));
      expect(calculateDvrsTotalScore(scores), 5);
    });

    test('arredonda para inteiro e mantém 0..100', () {
      final scores = const DvrsDomainScores(
        symptoms: 33,
        functional: 33,
        exposure: 33,
        environment: 33,
        warning: 33,
      );
      // 0.35*33+0.25*33+0.20*33+0.15*33+0.05*33 = 33
      expect(calculateDvrsTotalScore(scores), 33);
    });
  });

  group('classifyDvrs (faixas 0-19 / 20-39 / 40-59 / 60-79 / 80-100)', () {
    test('0 e 19 => low', () {
      expect(classifyDvrs(0), DvrsClassification.low);
      expect(classifyDvrs(19), DvrsClassification.low);
    });
    test('20 e 39 => mildAttention', () {
      expect(classifyDvrs(20), DvrsClassification.mildAttention);
      expect(classifyDvrs(39), DvrsClassification.mildAttention);
    });
    test('40 e 59 => moderateRisk', () {
      expect(classifyDvrs(40), DvrsClassification.moderateRisk);
      expect(classifyDvrs(59), DvrsClassification.moderateRisk);
    });
    test('60 e 79 => highRisk', () {
      expect(classifyDvrs(60), DvrsClassification.highRisk);
      expect(classifyDvrs(79), DvrsClassification.highRisk);
    });
    test('80 e 100 => veryHighRisk', () {
      expect(classifyDvrs(80), DvrsClassification.veryHighRisk);
      expect(classifyDvrs(100), DvrsClassification.veryHighRisk);
    });
  });

  group('getDvrsSafetyAlert (independente do score total)', () {
    test('Q16 = 0 => nenhum alerta', () {
      final alert = getDvrsSafetyAlert(0);
      expect(alert.level, DvrsSafetyAlertLevel.none);
    });
    test('Q16 = 1 => nenhum alerta', () {
      expect(getDvrsSafetyAlert(1).level, DvrsSafetyAlertLevel.none);
    });
    test('Q16 = 2 => atenção', () {
      final alert = getDvrsSafetyAlert(2);
      expect(alert.level, DvrsSafetyAlertLevel.attention);
    });
    test('Q16 = 3 => avaliação médica', () {
      final alert = getDvrsSafetyAlert(3);
      expect(alert.level, DvrsSafetyAlertLevel.medicalEvaluation);
    });
    test('Q16 = 4 => avaliação prioritária', () {
      final alert = getDvrsSafetyAlert(4);
      expect(alert.level, DvrsSafetyAlertLevel.priorityEvaluation);
    });
  });

  group('evaluateDvrs (resultado completo)', () {
    final now = DateTime(2026, 6, 30, 10);

    test(
      'monta DvrsResult com versão, score, classificação e isDiagnostic false',
      () {
        final result = evaluateDvrs(
          answers: _answers(List<int>.filled(16, 2)),
          id: 'r1',
          now: now,
        );
        expect(result.version, 'DVRS_v1.1');
        expect(result.totalScore, 50);
        expect(result.classification, DvrsClassification.moderateRisk);
        expect(result.classificationLabel, 'Carga relatada moderada');
        expect(result.isDiagnostic, isFalse);
        expect(result.createdAt, now);
        expect(result.answers.length, 16);
      },
    );

    test('alerta de segurança vem da Q16 e independe do score total', () {
      // Score baixo (tudo 0) mas Q16 = 4 => alerta prioritário.
      final values = _filled(0)..[15] = 4;
      final result = evaluateDvrs(
        answers: _answers(values),
        id: 'r2',
        now: now,
      );
      expect(result.totalScore, 5);
      expect(result.classification, DvrsClassification.low);
      expect(result.safetyAlertLevel, DvrsSafetyAlertLevel.priorityEvaluation);
    });

    test('exige exatamente 16 respostas', () {
      expect(
        () => evaluateDvrs(
          answers: _answers(_filled(0)).sublist(0, 15),
          id: 'r3',
          now: now,
        ),
        throwsArgumentError,
      );
    });
  });
}
