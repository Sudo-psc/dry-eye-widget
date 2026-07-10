import 'package:dry_eye_widget/models/dvrs_assessment.dart';
import 'package:dry_eye_widget/services/dvrs_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('rascunho DVRS salva, carrega e limpa', () async {
    final storage = await DvrsStorageService.init();
    expect(storage.hasDraft, isFalse);

    await storage.saveDraft({'q1': 2, 'q2': 1});
    expect(storage.hasDraft, isTrue);
    expect(storage.loadDraft()['q1'], 2);

    await storage.clearDraft();
    expect(storage.hasDraft, isFalse);
  });

  test('novos resultados gravam versão do instrumento 1.1', () {
    expect(DvrsResult.dvrsVersion, 'DVRS_v1.1');
  });
}
