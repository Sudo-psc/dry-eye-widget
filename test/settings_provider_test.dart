import 'package:dry_eye_widget/models/widget_settings.dart';
import 'package:dry_eye_widget/providers/settings_provider.dart';
import 'package:dry_eye_widget/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ignora atualização idêntica e evita reconstrução redundante', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    final provider = SettingsProvider(storage: storage);
    var notifications = 0;
    provider.addListener(() => notifications++);

    await provider.update(WidgetSettings.fromMap(provider.value.toMap()));
    expect(notifications, 0);

    await provider.update(provider.value.copyWith(cycleMinutes: 30));
    expect(notifications, 1);
    expect(provider.value.cycleMinutes, 30);
  });
}
