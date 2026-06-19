import 'package:dry_eye_widget/models/dry_eye_health_dashboard.dart';
import 'package:dry_eye_widget/services/healthkit_dashboard_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HealthKitDashboardService', () {
    late MethodChannel channel;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    setUp(() {
      channel = const MethodChannel('dry_eye_widget/healthkit_dashboard_test');
    });

    tearDown(() {
      messenger.setMockMethodCallHandler(channel, null);
    });

    test('short-circuits when platform is not macOS', () async {
      final service = HealthKitDashboardService(
        channel: channel,
        isMacOS: () => false,
      );

      expect(await service.isAvailable(), isFalse);
      final auth = await service.requestAuthorization();
      expect(auth.available, isFalse);
      expect(auth.authorized, isFalse);
    });

    test('requests native authorization on macOS', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'requestAuthorization');
        return <String, Object?>{'available': true, 'authorized': true};
      });
      final service = HealthKitDashboardService(
        channel: channel,
        isMacOS: () => true,
      );

      final auth = await service.requestAuthorization();

      expect(auth.available, isTrue);
      expect(auth.authorized, isTrue);
    });

    test('maps native daily summaries to dashboard periods', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'fetchDailySummaries');
        return <Map<String, Object?>>[
          {
            'date': '2026-06-19',
            'sleepSeconds': 25200.0,
            'averageHeartRateBpm': 68.5,
          },
          {'date': '2026-06-20', 'heartRateAbsenceReason': 'No samples.'},
        ];
      });
      final service = HealthKitDashboardService(
        channel: channel,
        isMacOS: () => true,
      );

      final periods = await service.fetchDailyHealthMetrics(
        start: DateTime(2026, 6, 19),
        end: DateTime(2026, 6, 21),
      );

      expect(periods, hasLength(2));
      expect(periods.first.byKind[DryEyeMetricKind.sleep]?.numericValue, 25200);
      expect(
        periods.first.byKind[DryEyeMetricKind.averageHeartRate]?.numericValue,
        68.5,
      );
      expect(
        periods.last.byKind[DryEyeMetricKind.sleep]?.availability,
        DryEyeAvailability.unavailable,
      );
      expect(
        periods.last.byKind[DryEyeMetricKind.averageHeartRate]?.absenceReason,
        'No samples.',
      );
    });
  });
}
