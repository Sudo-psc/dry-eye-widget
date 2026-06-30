import 'package:dry_eye_widget/models/dvrs_assessment.dart';
import 'package:dry_eye_widget/services/dvrs_engine.dart';
import 'package:dry_eye_widget/services/dvrs_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

DvrsResult _result({
  required String id,
  required DateTime createdAt,
  int value = 2,
}) {
  final answers = [
    for (var i = 0; i < 16; i++)
      DvrsAnswer(
        questionId: 'q${i + 1}',
        domain: i < 6
            ? DvrsDomain.symptoms
            : i < 9
                ? DvrsDomain.functional
                : i < 12
                    ? DvrsDomain.exposure
                    : i < 15
                        ? DvrsDomain.environment
                        : DvrsDomain.warning,
        value: value,
        label: 'opt',
      ),
  ];
  return evaluateDvrs(answers: answers, id: id, now: createdAt);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DvrsStorageService', () {
    test('round-trip save/get preserva os campos', () async {
      final storage = await DvrsStorageService.init();
      final r = _result(id: 'a', createdAt: DateTime.utc(2026, 6, 1));
      await storage.saveDvrsResult(r);

      final history = storage.getDvrsHistory();
      expect(history, hasLength(1));
      expect(history.first.id, 'a');
      expect(history.first.totalScore, r.totalScore);
      expect(history.first.version, 'DVRS_v1.0');
    });

    test('histórico ordenado por data (mais antigo → mais recente)', () async {
      final storage = await DvrsStorageService.init();
      await storage.saveDvrsResult(_result(id: 'b', createdAt: DateTime.utc(2026, 6, 2)));
      await storage.saveDvrsResult(_result(id: 'a', createdAt: DateTime.utc(2026, 6, 1)));
      await storage.saveDvrsResult(_result(id: 'c', createdAt: DateTime.utc(2026, 6, 3)));

      final ids = storage.getDvrsHistory().map((r) => r.id).toList();
      expect(ids, ['a', 'b', 'c']);
    });

    test('getLatestDvrsResult devolve o mais recente', () async {
      final storage = await DvrsStorageService.init();
      await storage.saveDvrsResult(_result(id: 'old', createdAt: DateTime.utc(2026, 6, 1)));
      await storage.saveDvrsResult(_result(id: 'new', createdAt: DateTime.utc(2026, 6, 5)));
      expect(storage.getLatestDvrsResult()?.id, 'new');
    });

    test('getLatestDvrsResult devolve null sem histórico', () async {
      final storage = await DvrsStorageService.init();
      expect(storage.getLatestDvrsResult(), isNull);
    });

    test('salvar com id existente substitui', () async {
      final storage = await DvrsStorageService.init();
      await storage.saveDvrsResult(_result(id: 'x', createdAt: DateTime.utc(2026, 6, 1), value: 0));
      await storage.saveDvrsResult(_result(id: 'x', createdAt: DateTime.utc(2026, 6, 1), value: 4));
      final history = storage.getDvrsHistory();
      expect(history, hasLength(1));
      expect(history.first.totalScore, 100);
    });

    test('deleteDvrsResult remove pelo id', () async {
      final storage = await DvrsStorageService.init();
      await storage.saveDvrsResult(_result(id: 'a', createdAt: DateTime.utc(2026, 6, 1)));
      await storage.saveDvrsResult(_result(id: 'b', createdAt: DateTime.utc(2026, 6, 2)));
      await storage.deleteDvrsResult('a');
      final ids = storage.getDvrsHistory().map((r) => r.id).toList();
      expect(ids, ['b']);
    });

    test('clearAll esvazia o histórico', () async {
      final storage = await DvrsStorageService.init();
      await storage.saveDvrsResult(_result(id: 'a', createdAt: DateTime.utc(2026, 6, 1)));
      await storage.clearAll();
      expect(storage.getDvrsHistory(), isEmpty);
    });

    test('retém no máximo maxRetainedResults (descarta os mais antigos)', () async {
      final storage = await DvrsStorageService.init();
      final n = DvrsStorageService.maxRetainedResults + 5;
      for (var i = 0; i < n; i++) {
        await storage.saveDvrsResult(
          _result(id: 'id$i', createdAt: DateTime.utc(2026, 1, 1).add(Duration(days: i))),
        );
      }
      final history = storage.getDvrsHistory();
      expect(history.length, DvrsStorageService.maxRetainedResults);
      // Os 5 mais antigos foram descartados.
      expect(history.first.id, 'id5');
    });
  });
}
