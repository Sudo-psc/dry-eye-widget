import 'package:dry_eye_widget/models/osdi_assessment.dart';
import 'package:dry_eye_widget/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('StorageService OSDI', () {
    test('salva e recarrega o histórico OSDI localmente', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      final assessment = OsdiAssessment.fromAnswers(const [
        4,
        4,
        4,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
      ], completedAt: DateTime.utc(2026, 6, 9, 9));

      await storage.addOsdiAssessment(assessment);

      final history = storage.loadOsdiHistory();
      expect(history, hasLength(1));
      expect(history.single.answers, assessment.answers);
      expect(history.single.score, assessment.score);
    });

    test('mantém no máximo os resultados mais recentes', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();

      for (var i = 0; i < 55; i++) {
        await storage.addOsdiAssessment(
          OsdiAssessment.fromAnswers([
            i % 5,
            ...List<int?>.filled(11, null),
          ], completedAt: DateTime.utc(2026, 6, 1 + i)),
        );
      }

      final history = storage.loadOsdiHistory();
      expect(history, hasLength(50));
      expect(history.first.completedAt, DateTime.utc(2026, 6, 6));
      expect(history.last.completedAt, DateTime.utc(2026, 7, 25));
    });
  });
}
