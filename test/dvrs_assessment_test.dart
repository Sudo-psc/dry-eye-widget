import 'package:flutter_test/flutter_test.dart';

import 'package:dry_eye_widget/models/dvrs_assessment.dart';
import 'package:dry_eye_widget/services/dvrs_engine.dart';

DvrsDomain _domainForIndex(int i) {
  if (i < 6) return DvrsDomain.symptoms;
  if (i < 9) return DvrsDomain.functional;
  if (i < 12) return DvrsDomain.exposure;
  if (i < 15) return DvrsDomain.environment;
  return DvrsDomain.warning;
}

List<DvrsAnswer> _answers(List<int> values) => [
      for (var i = 0; i < 16; i++)
        DvrsAnswer(
          questionId: 'q${i + 1}',
          domain: _domainForIndex(i),
          value: values[i],
          label: 'opt',
        ),
    ];

void main() {
  group('ids estáveis de enums', () {
    test('DvrsDomain id/fromId round-trip', () {
      for (final d in DvrsDomain.values) {
        expect(DvrsDomainId.fromId(d.id), d);
      }
    });
    test('DvrsClassification id/fromId round-trip', () {
      for (final c in DvrsClassification.values) {
        expect(DvrsClassificationId.fromId(c.id), c);
      }
    });
    test('DvrsSafetyAlertLevel id/fromId round-trip', () {
      for (final l in DvrsSafetyAlertLevel.values) {
        expect(DvrsSafetyAlertLevelId.fromId(l.id), l);
      }
    });
  });

  group('DvrsResult serialização', () {
    test('toJson/fromJson preserva os campos', () {
      final now = DateTime(2026, 6, 30, 8, 15);
      final original = evaluateDvrs(
        answers: _answers(List<int>.filled(16, 3)),
        id: 'abc',
        now: now,
        userId: 'user-1',
      );

      final restored = DvrsResult.fromJson(original.toJson());
      expect(restored, isNotNull);
      expect(restored!.id, 'abc');
      expect(restored.userId, 'user-1');
      expect(restored.createdAt, now);
      expect(restored.version, 'DVRS_v1.1');
      expect(restored.totalScore, original.totalScore);
      expect(restored.classification, original.classification);
      expect(restored.classificationLabel, original.classificationLabel);
      expect(restored.safetyAlertLevel, original.safetyAlertLevel);
      expect(restored.isDiagnostic, isFalse);
      expect(restored.answers.length, 16);
      expect(restored.answers.first.domain, DvrsDomain.symptoms);
      expect(restored.domainScores.symptoms, original.domainScores.symptoms);
    });

    test('fromJson devolve null para entrada inválida', () {
      expect(DvrsResult.fromJson(''), isNull);
      expect(DvrsResult.fromJson('not json'), isNull);
    });
  });
}
