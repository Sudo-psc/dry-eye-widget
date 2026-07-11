import 'package:dry_eye_widget/services/activity_monitor_service.dart';
import 'package:dry_eye_widget/services/activity_stats_service.dart';
import 'package:dry_eye_widget/services/dvrs_storage_service.dart';
import 'package:dry_eye_widget/services/health_data_service.dart';
import 'package:dry_eye_widget/services/screen_time_service.dart';
import 'package:dry_eye_widget/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'apagar histórico não permite restaurar atividade pelo próximo flush',
    () async {
      final storage = await StorageService.init();
      final dvrs = await DvrsStorageService.init();
      final screenTime = ScreenTimeService(storage: storage);
      final activity = ActivityStatsService(
        storage: storage,
        monitor: const ActivityMonitorService(),
      );
      final day = DateTime(2026, 7, 11, 10);

      activity.applySample(
        const ActivitySample(clicks: 12, keys: 30, frontApp: 'Browser'),
        day,
      );
      await activity.flush(day);

      final service = HealthDataService(
        storage: storage,
        dvrs: dvrs,
        screenTime: screenTime,
        activity: activity,
      );
      await service.clearHealthHistory();
      await activity.flush(day);

      expect(activity.data.clicksForDay(day), 0);
      expect(storage.loadActivityStats().clicksForDay(day), 0);

      await activity.dispose();
      screenTime.dispose();
    },
  );

  test('exportação inclui atividade atual ainda não persistida', () async {
    final storage = await StorageService.init();
    final dvrs = await DvrsStorageService.init();
    final screenTime = ScreenTimeService(storage: storage);
    final activity = ActivityStatsService(
      storage: storage,
      monitor: const ActivityMonitorService(),
    );
    final day = DateTime(2026, 7, 11, 10);
    activity.applySample(
      const ActivitySample(clicks: 7, keys: 11, frontApp: 'Editor'),
      day,
    );

    final service = HealthDataService(
      storage: storage,
      dvrs: dvrs,
      screenTime: screenTime,
      activity: activity,
    );
    final exported = service.buildExportMap(now: day);
    final activityMap = Map<String, dynamic>.from(
      exported['activityStats'] as Map,
    );
    final dayMap = Map<String, dynamic>.from(activityMap['2026-07-11'] as Map);

    expect(dayMap['c'], 7);
    expect(dayMap['k'], 11);

    await activity.dispose();
    screenTime.dispose();
  });
}
