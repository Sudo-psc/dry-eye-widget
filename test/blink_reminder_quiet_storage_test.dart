import 'package:dry_eye_widget/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('persiste e remove o fim do silêncio temporário', () async {
    final storage = await StorageService.init();
    final until = DateTime.utc(2026, 7, 17, 18, 45);

    expect(storage.loadBlinkRemindersQuietUntil(), isNull);

    await storage.saveBlinkRemindersQuietUntil(until);
    expect(storage.loadBlinkRemindersQuietUntil(), until);

    await storage.saveBlinkRemindersQuietUntil(null);
    expect(storage.loadBlinkRemindersQuietUntil(), isNull);
  });

  test('valor inválido degrada para nulo', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'blink_reminders_quiet_until': 'inválido',
    });
    final storage = await StorageService.init();

    expect(storage.loadBlinkRemindersQuietUntil(), isNull);
  });
}
