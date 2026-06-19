import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/dry_eye_health_dashboard.dart';

@immutable
class HealthKitAuthorizationResult {
  const HealthKitAuthorizationResult({
    required this.available,
    required this.authorized,
    this.reason,
  });

  final bool available;
  final bool authorized;
  final String? reason;
}

class HealthKitDashboardService {
  const HealthKitDashboardService({
    this.channel = const MethodChannel('dry_eye_widget/healthkit_dashboard'),
    bool Function()? isMacOS,
  }) : _isMacOS = isMacOS ?? _defaultIsMacOS;

  final MethodChannel channel;
  final bool Function() _isMacOS;

  static bool _defaultIsMacOS() => Platform.isMacOS;

  Future<bool> isAvailable() async {
    if (!_isMacOS()) return false;
    try {
      return await channel.invokeMethod<bool>('isAvailable') ?? false;
    } catch (e) {
      debugPrint('HealthKitDashboardService indisponivel ($e).');
      return false;
    }
  }

  Future<HealthKitAuthorizationResult> requestAuthorization() async {
    if (!_isMacOS()) {
      return const HealthKitAuthorizationResult(
        available: false,
        authorized: false,
        reason: 'HealthKit is only wired for macOS in this build.',
      );
    }
    try {
      final raw = await channel.invokeMapMethod<String, Object?>(
        'requestAuthorization',
      );
      return HealthKitAuthorizationResult(
        available: raw?['available'] == true,
        authorized: raw?['authorized'] == true,
        reason: raw?['reason'] as String?,
      );
    } catch (e) {
      debugPrint('HealthKitDashboardService: autorizacao falhou ($e).');
      return HealthKitAuthorizationResult(
        available: false,
        authorized: false,
        reason: e.toString(),
      );
    }
  }

  Future<List<DryEyeDashboardPeriod>> fetchDailyHealthMetrics({
    required DateTime start,
    required DateTime end,
  }) async {
    final days = _daysBetween(start, end);
    if (!_isMacOS()) {
      return [
        for (final day in days)
          _unavailablePeriod(day, 'HealthKit unavailable.'),
      ];
    }
    try {
      final raw = await channel
          .invokeMethod<List<Object?>>('fetchDailySummaries', <String, Object?>{
            'startMillis': start.millisecondsSinceEpoch,
            'endMillis': end.millisecondsSinceEpoch,
          });
      final rows = <String, Map<Object?, Object?>>{};
      for (final item in raw ?? const <Object?>[]) {
        if (item is Map<Object?, Object?>) {
          final date = item['date'];
          if (date is String) rows[date] = item;
        }
      }
      return [
        for (final day in days)
          _periodFromNative(day, rows[ScreenTimeDayKey.forDate(day)]),
      ];
    } catch (e) {
      debugPrint('HealthKitDashboardService: leitura falhou ($e).');
      return [
        for (final day in days)
          _unavailablePeriod(day, 'HealthKit read failed: $e'),
      ];
    }
  }

  static List<DateTime> _daysBetween(DateTime start, DateTime end) {
    final first = DateTime(start.year, start.month, start.day);
    final lastExclusive = DateTime(end.year, end.month, end.day);
    final count = lastExclusive.difference(first).inDays;
    if (count <= 0) return const [];
    return List<DateTime>.generate(count, (i) => first.add(Duration(days: i)));
  }

  static DryEyeDashboardPeriod _periodFromNative(
    DateTime day,
    Map<Object?, Object?>? raw,
  ) {
    final end = day.add(const Duration(days: 1));
    final sleepSeconds = (raw?['sleepSeconds'] as num?)?.toDouble();
    final heartRate = (raw?['averageHeartRateBpm'] as num?)?.toDouble();
    final sleepReason = raw?['sleepAbsenceReason'] as String?;
    final heartReason = raw?['heartRateAbsenceReason'] as String?;

    return DryEyeDashboardPeriod(
      start: day,
      end: end,
      grain: DryEyeTimeGrain.day,
      values: [
        if (sleepSeconds != null)
          DryEyeMetricValue(
            kind: DryEyeMetricKind.sleep,
            source: DryEyeMetricSource.healthKit,
            start: day,
            end: end,
            availability: DryEyeAvailability.available,
            numericValue: sleepSeconds,
          )
        else
          DryEyeMetricValue.unavailable(
            kind: DryEyeMetricKind.sleep,
            source: DryEyeMetricSource.healthKit,
            start: day,
            end: end,
            availability: DryEyeAvailability.unavailable,
            reason:
                sleepReason ??
                definitionFor(DryEyeMetricKind.sleep).absenceLabel!,
          ),
        if (heartRate != null)
          DryEyeMetricValue(
            kind: DryEyeMetricKind.averageHeartRate,
            source: DryEyeMetricSource.healthKit,
            start: day,
            end: end,
            availability: DryEyeAvailability.available,
            numericValue: heartRate,
          )
        else
          DryEyeMetricValue.unavailable(
            kind: DryEyeMetricKind.averageHeartRate,
            source: DryEyeMetricSource.healthKit,
            start: day,
            end: end,
            availability: DryEyeAvailability.unavailable,
            reason:
                heartReason ??
                definitionFor(DryEyeMetricKind.averageHeartRate).absenceLabel!,
          ),
      ],
    );
  }

  static DryEyeDashboardPeriod _unavailablePeriod(DateTime day, String reason) {
    final end = day.add(const Duration(days: 1));
    return DryEyeDashboardPeriod(
      start: day,
      end: end,
      grain: DryEyeTimeGrain.day,
      values: [
        DryEyeMetricValue.unavailable(
          kind: DryEyeMetricKind.sleep,
          source: DryEyeMetricSource.healthKit,
          start: day,
          end: end,
          availability: DryEyeAvailability.unavailable,
          reason: reason,
        ),
        DryEyeMetricValue.unavailable(
          kind: DryEyeMetricKind.averageHeartRate,
          source: DryEyeMetricSource.healthKit,
          start: day,
          end: end,
          availability: DryEyeAvailability.unavailable,
          reason: reason,
        ),
      ],
    );
  }
}

class ScreenTimeDayKey {
  ScreenTimeDayKey._();

  static String forDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
