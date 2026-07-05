import 'package:dry_eye_widget/models/activity_stats_data.dart';
import 'package:dry_eye_widget/services/activity_monitor_service.dart';
import 'package:dry_eye_widget/services/activity_stats_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dry_eye_widget/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<StorageService> newStorage() => StorageService.init();

  test('sample acumula cliques/teclas e tempo do app em foco', () async {
    final storage = await newStorage();
    final svc = ActivityStatsService(
      storage: storage,
      monitor: const ActivityMonitorService(),
      pollIntervalSeconds: 5,
    );
    final now = DateTime(2026, 7, 5, 10);

    svc.applySample(
      const ActivitySample(clicks: 12, keys: 40, frontApp: 'Safari'),
      now,
    );
    svc.applySample(
      const ActivitySample(clicks: 3, keys: 10, frontApp: 'Safari'),
      now,
    );
    svc.applySample(
      const ActivitySample(clicks: 1, frontApp: 'Xcode'),
      now,
    );

    expect(svc.data.clicksForDay(now), 16);
    expect(svc.data.keysForDay(now), 50);
    // Cada sample atribui pollIntervalSeconds ao app em foco.
    expect(svc.data.appSecondsForDay(now)['Safari'], 10);
    expect(svc.data.appSecondsForDay(now)['Xcode'], 5);

    await svc.dispose();
  });

  test('flush persiste e recarrega', () async {
    final storage = await newStorage();
    final svc = ActivityStatsService(
      storage: storage,
      monitor: const ActivityMonitorService(),
      pollIntervalSeconds: 5,
    );
    final now = DateTime(2026, 7, 5, 10);
    svc.applySample(
      const ActivitySample(clicks: 5, keys: 20, frontApp: 'Mail'),
      now,
    );
    await svc.flush(now);

    final reloaded = ActivityStatsData.fromJson(storage.loadActivityStats().toJson());
    expect(reloaded.clicksForDay(now), 5);
    expect(reloaded.appSecondsForDay(now)['Mail'], 5);
    await svc.dispose();
  });

  test('clear zera os dados', () async {
    final storage = await newStorage();
    final svc = ActivityStatsService(
      storage: storage,
      monitor: const ActivityMonitorService(),
      pollIntervalSeconds: 5,
    );
    final now = DateTime(2026, 7, 5, 10);
    svc.applySample(const ActivitySample(clicks: 9, frontApp: 'X'), now);
    await svc.clear();
    expect(svc.data.clicksForDay(now), 0);
    await svc.dispose();
  });
}
