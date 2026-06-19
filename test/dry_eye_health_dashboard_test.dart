import 'package:dry_eye_widget/models/dry_eye_health_dashboard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DryEyeHealthDashboard model', () {
    test('declares every dashboard metric exactly once', () {
      final kinds = dryEyeDashboardMetricDefinitions.map((d) => d.kind).toSet();

      expect(kinds, DryEyeMetricKind.values.toSet());
      expect(dryEyeDashboardMetricDefinitions, hasLength(kinds.length));
    });

    test('maps HealthKit MVP to sleep and heart rate only', () {
      final healthKitKinds = dryEyeDashboardMetricDefinitions
          .where((d) => d.preferredSource == DryEyeMetricSource.healthKit)
          .map((d) => d.kind)
          .toSet();

      expect(healthKitKinds, {
        DryEyeMetricKind.sleep,
        DryEyeMetricKind.averageHeartRate,
      });
      expect(
        definitionFor(DryEyeMetricKind.sleep).healthKitIdentifier,
        'HKCategoryTypeIdentifierSleepAnalysis',
      );
      expect(
        definitionFor(DryEyeMetricKind.averageHeartRate).healthKitIdentifier,
        'HKQuantityTypeIdentifierHeartRate',
      );
    });

    test('keeps screen time as an app metric, not a HealthKit metric', () {
      final screenTime = definitionFor(DryEyeMetricKind.screenTime);

      expect(screenTime.preferredSource, DryEyeMetricSource.app);
      expect(screenTime.healthKitIdentifier, isNull);
      expect(healthKitImportPlan.screenTimeHealthKitIdentifier, isNull);
    });

    test('represents missing values explicitly', () {
      final day = DateTime(2026, 6, 19);
      final value = DryEyeMetricValue.unavailable(
        kind: DryEyeMetricKind.sleep,
        source: DryEyeMetricSource.healthKit,
        start: day,
        end: day.add(const Duration(days: 1)),
        availability: DryEyeAvailability.permissionDenied,
        reason: 'HealthKit permission denied.',
      );

      expect(value.hasData, isFalse);
      expect(value.absenceReason, 'HealthKit permission denied.');
    });

    test('indexes period values by metric kind', () {
      final day = DateTime(2026, 6, 19);
      final period = DryEyeDashboardPeriod(
        start: day,
        end: day.add(const Duration(days: 1)),
        grain: DryEyeTimeGrain.day,
        values: [
          DryEyeMetricValue(
            kind: DryEyeMetricKind.osdi,
            source: DryEyeMetricSource.app,
            start: day,
            end: day.add(const Duration(days: 1)),
            availability: DryEyeAvailability.available,
            numericValue: 23,
          ),
        ],
      );

      expect(period.byKind[DryEyeMetricKind.osdi]?.numericValue, 23);
      expect(period.missingValues, isEmpty);
    });
  });
}
