import 'package:dry_eye_widget/models/checklist.dart';
import 'package:dry_eye_widget/services/checklist_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

ChecklistResult _result({
  required String id,
  required ChecklistType type,
  required DateTime createdAt,
  int totalScore = 0,
  ChecklistRiskLevel level = ChecklistRiskLevel.low,
}) {
  return ChecklistResult(
    id: id,
    type: type,
    createdAt: createdAt,
    answers: const [],
    totalScore: totalScore,
    riskLevel: level,
    classification: 'classe',
    feedback: 'feedback educativo',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ChecklistStorageService', () {
    test('round-trip save/get preserva os campos', () async {
      final storage = await ChecklistStorageService.init();
      final r = _result(
        id: 'a',
        type: ChecklistType.visualSymptoms,
        createdAt: DateTime.utc(2026, 6, 1),
        totalScore: 12,
        level: ChecklistRiskLevel.attention,
      );
      await storage.saveChecklistResult(r);

      final history = storage.getChecklistHistory();
      expect(history, hasLength(1));
      final loaded = history.single;
      expect(loaded.id, 'a');
      expect(loaded.type, ChecklistType.visualSymptoms);
      expect(loaded.totalScore, 12);
      expect(loaded.riskLevel, ChecklistRiskLevel.attention);
      expect(loaded.createdAt, DateTime.utc(2026, 6, 1));
    });

    test('histórico ordenado por data', () async {
      final storage = await ChecklistStorageService.init();
      await storage.saveChecklistResult(_result(
        id: 'newer',
        type: ChecklistType.breakHabits,
        createdAt: DateTime.utc(2026, 6, 10),
      ));
      await storage.saveChecklistResult(_result(
        id: 'older',
        type: ChecklistType.breakHabits,
        createdAt: DateTime.utc(2026, 6, 1),
      ));
      final history = storage.getChecklistHistory();
      expect(history.map((r) => r.id).toList(), ['older', 'newer']);
    });

    test('filtro por tipo', () async {
      final storage = await ChecklistStorageService.init();
      await storage.saveChecklistResult(_result(
        id: 'sym',
        type: ChecklistType.visualSymptoms,
        createdAt: DateTime.utc(2026, 6, 1),
      ));
      await storage.saveChecklistResult(_result(
        id: 'env',
        type: ChecklistType.screenEnvironment,
        createdAt: DateTime.utc(2026, 6, 2),
      ));
      final symptoms =
          storage.getChecklistHistory(type: ChecklistType.visualSymptoms);
      expect(symptoms, hasLength(1));
      expect(symptoms.single.id, 'sym');
    });

    test('latestByType retorna o mais recente', () async {
      final storage = await ChecklistStorageService.init();
      await storage.saveChecklistResult(_result(
        id: 'old',
        type: ChecklistType.visualErgonomics,
        createdAt: DateTime.utc(2026, 5, 1),
      ));
      await storage.saveChecklistResult(_result(
        id: 'new',
        type: ChecklistType.visualErgonomics,
        createdAt: DateTime.utc(2026, 6, 1),
      ));
      final latest = storage.latestByType(ChecklistType.visualErgonomics);
      expect(latest?.id, 'new');
      expect(storage.latestByType(ChecklistType.warningSigns), isNull);
    });

    test('save com mesmo id substitui', () async {
      final storage = await ChecklistStorageService.init();
      await storage.saveChecklistResult(_result(
        id: 'x',
        type: ChecklistType.breakHabits,
        createdAt: DateTime.utc(2026, 6, 1),
        totalScore: 1,
      ));
      await storage.saveChecklistResult(_result(
        id: 'x',
        type: ChecklistType.breakHabits,
        createdAt: DateTime.utc(2026, 6, 2),
        totalScore: 9,
      ));
      final history = storage.getChecklistHistory();
      expect(history, hasLength(1));
      expect(history.single.totalScore, 9);
    });

    test('delete remove o resultado', () async {
      final storage = await ChecklistStorageService.init();
      await storage.saveChecklistResult(_result(
        id: 'a',
        type: ChecklistType.breakHabits,
        createdAt: DateTime.utc(2026, 6, 1),
      ));
      await storage.deleteChecklistResult('a');
      expect(storage.getChecklistHistory(), isEmpty);
    });

    test('clearAll esvazia tudo', () async {
      final storage = await ChecklistStorageService.init();
      await storage.saveChecklistResult(_result(
        id: 'a',
        type: ChecklistType.breakHabits,
        createdAt: DateTime.utc(2026, 6, 1),
      ));
      await storage.clearAll();
      expect(storage.getChecklistHistory(), isEmpty);
    });

    test('retenção limita a maxRetainedResults', () async {
      final storage = await ChecklistStorageService.init();
      final total = ChecklistStorageService.maxRetainedResults + 10;
      for (var i = 0; i < total; i++) {
        await storage.saveChecklistResult(_result(
          id: 'id_$i',
          type: ChecklistType.visualSymptoms,
          createdAt: DateTime.utc(2026, 1, 1).add(Duration(minutes: i)),
        ));
      }
      final history = storage.getChecklistHistory();
      expect(history, hasLength(ChecklistStorageService.maxRetainedResults));
      // Os mais antigos foram descartados; o último deve permanecer.
      expect(history.last.id, 'id_${total - 1}');
      expect(history.first.id, 'id_10');
    });
  });
}
