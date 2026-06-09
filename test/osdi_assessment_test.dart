import 'package:dry_eye_widget/models/osdi_assessment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OsdiAssessment', () {
    test('calcula a pontuação OSDI ignorando respostas não aplicáveis', () {
      final assessment = OsdiAssessment.fromAnswers(const [
        4,
        3,
        2,
        1,
        0,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
      ], completedAt: DateTime.utc(2026, 6, 9, 12));

      expect(assessment.answeredCount, 5);
      expect(assessment.rawScore, 10);
      expect(assessment.score, 50);
      expect(assessment.severity, OsdiSeverity.severe);
    });

    test('classifica severidade pelas faixas padronizadas do OSDI', () {
      expect(OsdiAssessment.severityForScore(12), OsdiSeverity.normal);
      expect(OsdiAssessment.severityForScore(13), OsdiSeverity.mild);
      expect(OsdiAssessment.severityForScore(22), OsdiSeverity.mild);
      expect(OsdiAssessment.severityForScore(23), OsdiSeverity.moderate);
      expect(OsdiAssessment.severityForScore(32), OsdiSeverity.moderate);
      expect(OsdiAssessment.severityForScore(33), OsdiSeverity.severe);
    });

    test('serializa e restaura histórico preservando respostas e data', () {
      final original = OsdiAssessment.fromAnswers(const [
        0,
        1,
        2,
        3,
        4,
        null,
        1,
        null,
        2,
        3,
        4,
        0,
      ], completedAt: DateTime.utc(2026, 6, 9, 18, 30));

      final encoded = OsdiAssessment.encodeHistory([original]);
      final restored = OsdiAssessment.decodeHistory(encoded);

      expect(restored, hasLength(1));
      expect(restored.single.answers, original.answers);
      expect(restored.single.completedAt, original.completedAt);
      expect(restored.single.score, original.score);
    });

    test('rejeita avaliação sem nenhuma pergunta respondida', () {
      expect(
        () => OsdiAssessment.fromAnswers(List<int?>.filled(12, null)),
        throwsArgumentError,
      );
    });
  });
}
