import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/dry_eye_health_dashboard.dart';
import '../services/healthkit_dashboard_service.dart';
import '../utils/constants.dart';
import 'liquid_glass.dart';

class HealthDashboardDialog extends StatefulWidget {
  const HealthDashboardDialog({
    super.key,
    required this.strings,
    required this.onClose,
    this.service = const HealthKitDashboardService(),
    this.now,
  });

  final AppStrings strings;
  final VoidCallback onClose;
  final HealthKitDashboardService service;
  final DateTime Function()? now;

  @override
  State<HealthDashboardDialog> createState() => _HealthDashboardDialogState();
}

class _HealthDashboardDialogState extends State<HealthDashboardDialog> {
  bool _checkingAvailability = true;
  bool _loadingMetrics = false;
  bool? _available;
  HealthKitAuthorizationResult? _authorization;
  List<DryEyeDashboardPeriod> _periods = const [];

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    final available = await widget.service.isAvailable();
    if (!mounted) return;
    setState(() {
      _available = available;
      _checkingAvailability = false;
    });
  }

  Future<void> _authorizeAndLoad() async {
    setState(() => _loadingMetrics = true);
    final authorization = await widget.service.requestAuthorization();
    if (!mounted) return;
    setState(() => _authorization = authorization);
    if (authorization.authorized) {
      await _loadMetrics();
    } else if (mounted) {
      setState(() => _loadingMetrics = false);
    }
  }

  Future<void> _loadMetrics() async {
    setState(() => _loadingMetrics = true);
    final today = _today();
    final periods = await widget.service.fetchDailyHealthMetrics(
      start: today.subtract(const Duration(days: 6)),
      end: today.add(const Duration(days: 1)),
    );
    if (!mounted) return;
    setState(() {
      _periods = periods.reversed.toList(growable: false);
      _loadingMetrics = false;
    });
  }

  DateTime _today() {
    final now = widget.now?.call() ?? DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return LiquidGlass(
      width: 640,
      constraints: const BoxConstraints(maxHeight: 760),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  s.healthDashboardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textPrimary),
                onPressed: widget.onClose,
              ),
            ],
          ),
          Text(
            s.healthDashboardSubtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          _permissionCard(s),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed:
                    _loadingMetrics ||
                        _checkingAvailability ||
                        _available == false
                    ? null
                    : _authorizeAndLoad,
                icon: const Icon(Icons.favorite_border, size: 18),
                label: Text(s.healthDashboardAuthorize),
              ),
              TextButton.icon(
                onPressed: _loadingMetrics ? null : _loadMetrics,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(s.healthDashboardRefresh),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            s.healthDashboardLastSevenDays,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Flexible(
            child: _loadingMetrics
                ? const Center(child: CircularProgressIndicator())
                : _periods.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Center(child: _hint(s.healthDashboardNoData)),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        for (final period in _periods) _dayRow(s, period),
                      ],
                    ),
                  ),
          ),
          const Divider(color: AppColors.glassBorder),
          Text(
            s.healthDashboardPrivacyNote,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _permissionCard(AppStrings s) {
    final status = _statusText(s);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.idleBall.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.idleBall.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.health_and_safety_outlined,
            color: AppColors.idleBall,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.healthDashboardPermissionTitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusText(AppStrings s) {
    if (_checkingAvailability) return s.updateChecking;
    if (_available == false) return s.healthDashboardUnavailable;
    final authorization = _authorization;
    if (authorization == null) return s.healthDashboardPermissionBody;
    if (authorization.authorized) return s.healthDashboardAuthorized;
    return authorization.reason ?? s.healthDashboardDenied;
  }

  Widget _dayRow(AppStrings s, DryEyeDashboardPeriod period) {
    final values = period.byKind;
    final sleep = values[DryEyeMetricKind.sleep];
    final heartRate = values[DryEyeMetricKind.averageHeartRate];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            child: Text(
              _dateLabel(s, period.start),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: _metricChip(
              icon: Icons.bedtime_outlined,
              label: s.healthDashboardSleep,
              value: _metricText(s, sleep),
              available: sleep?.hasData == true,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _metricChip(
              icon: Icons.monitor_heart_outlined,
              label: s.healthDashboardHeartRate,
              value: _metricText(s, heartRate),
              available: heartRate?.hasData == true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricChip({
    required IconData icon,
    required String label,
    required String value,
    required bool available,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: available ? AppColors.idleBall : AppColors.textSecondary,
          size: 18,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: available
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: available ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _hint(String text) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
    );
  }

  String _metricText(AppStrings s, DryEyeMetricValue? value) {
    if (value == null || !value.hasData) {
      return value?.absenceReason ?? s.healthDashboardNoData;
    }
    final numeric = value.numericValue;
    if (numeric == null) return value.textValue ?? s.healthDashboardNoData;
    return switch (value.kind) {
      DryEyeMetricKind.sleep => _formatSeconds(s, numeric.round()),
      DryEyeMetricKind.averageHeartRate => '${numeric.round()} bpm',
      _ => numeric.toStringAsFixed(0),
    };
  }

  String _formatSeconds(AppStrings s, int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours <= 0) return '$minutes ${s.unitMin}';
    if (minutes <= 0) return '$hours ${s.unitHour}';
    return '$hours ${s.unitHour} $minutes ${s.unitMin}';
  }

  String _dateLabel(AppStrings s, DateTime date) {
    final weekday = s.weekdayShort[date.weekday - 1];
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$weekday $day/$month';
  }
}
