import 'package:dry_eye_widget/l10n/app_strings.dart';
import 'package:dry_eye_widget/models/dry_eye_health_dashboard.dart';
import 'package:dry_eye_widget/services/healthkit_dashboard_service.dart';
import 'package:dry_eye_widget/widgets/health_dashboard_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mostra HealthKit indisponivel sem quebrar o painel', (
    tester,
  ) async {
    final service = _FakeHealthKitDashboardService(available: false);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HealthDashboardDialog(
            strings: ptStrings,
            service: service,
            onClose: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(ptStrings.healthDashboardTitle), findsOneWidget);
    expect(find.text(ptStrings.healthDashboardUnavailable), findsOneWidget);
  });

  testWidgets('solicita permissao e renderiza resumo diario HealthKit', (
    tester,
  ) async {
    final day = DateTime(2026, 6, 21);
    final service = _FakeHealthKitDashboardService(
      available: true,
      authorized: true,
      periods: [
        DryEyeDashboardPeriod(
          start: day,
          end: day.add(const Duration(days: 1)),
          grain: DryEyeTimeGrain.day,
          values: [
            DryEyeMetricValue(
              kind: DryEyeMetricKind.sleep,
              source: DryEyeMetricSource.healthKit,
              start: day,
              end: day.add(const Duration(days: 1)),
              availability: DryEyeAvailability.available,
              numericValue: 25200,
            ),
            DryEyeMetricValue(
              kind: DryEyeMetricKind.averageHeartRate,
              source: DryEyeMetricSource.healthKit,
              start: day,
              end: day.add(const Duration(days: 1)),
              availability: DryEyeAvailability.available,
              numericValue: 68,
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HealthDashboardDialog(
            strings: ptStrings,
            service: service,
            now: () => day,
            onClose: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text(ptStrings.healthDashboardAuthorize));
    await tester.pumpAndSettle();

    expect(service.authorizationRequests, 1);
    expect(service.readRequests, 1);
    expect(find.text(ptStrings.healthDashboardAuthorized), findsOneWidget);
    expect(find.text('7 h'), findsOneWidget);
    expect(find.text('68 bpm'), findsOneWidget);
  });
}

class _FakeHealthKitDashboardService extends HealthKitDashboardService {
  _FakeHealthKitDashboardService({
    required this.available,
    this.authorized = false,
    this.periods = const [],
  });

  final bool available;
  final bool authorized;
  final List<DryEyeDashboardPeriod> periods;
  int authorizationRequests = 0;
  int readRequests = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<HealthKitAuthorizationResult> requestAuthorization() async {
    authorizationRequests++;
    return HealthKitAuthorizationResult(
      available: available,
      authorized: authorized,
      reason: authorized ? null : 'Denied',
    );
  }

  @override
  Future<List<DryEyeDashboardPeriod>> fetchDailyHealthMetrics({
    required DateTime start,
    required DateTime end,
  }) async {
    readRequests++;
    return periods;
  }
}
