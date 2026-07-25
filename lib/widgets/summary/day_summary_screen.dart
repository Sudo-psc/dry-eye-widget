import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../providers/settings_provider.dart';
import '../../services/daily_insight.dart';
import '../../services/dvrs_storage_service.dart';
import '../../services/storage_service.dart';
import '../../ui/app_theme.dart';
import '../../utils/constants.dart';
import '../common/panel_entrance.dart';
import '../common/panel_header.dart';
import '../liquid_glass.dart';

/// Hub “Resumo do dia”: adesão de hoje, streak, último DVRS, insight e CTAs.
///
/// Concentra a descoberta das funções de saúde sem exigir navegação profunda
/// no menu linear. Todos os dados são locais.
class DaySummaryScreen extends StatefulWidget {
  const DaySummaryScreen({
    super.key,
    required this.onClose,
    required this.onStartBreak,
    required this.onDvrs,
    required this.onProgress,
    required this.onDashboard,
    required this.onSnoozeDvrsNudge,
    this.embedded = false,
  });

  final VoidCallback onClose;
  final VoidCallback onStartBreak;
  final VoidCallback onDvrs;
  final VoidCallback onProgress;
  final VoidCallback onDashboard;
  final Future<void> Function() onSnoozeDvrsNudge;

  /// Quando true, renderiza só o corpo (sem Scaffold/vidro/header) para o hub.
  final bool embedded;

  @override
  State<DaySummaryScreen> createState() => _DaySummaryScreenState();
}

class _DaySummaryScreenState extends State<DaySummaryScreen> {
  DaySummarySnapshot? _snap;
  bool _snoozing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  void _reload() {
    if (!mounted) return;
    final settings = context.read<SettingsProvider>().value;
    final strings = context.read<SettingsProvider>().strings;
    final storage = context.read<StorageService>();
    final dvrs = context.read<DvrsStorageService>();
    final stats = storage.loadBreakStats();
    final now = DateTime.now();
    setState(() {
      _snap = DailyInsightEngine.buildSnapshot(
        strings: strings,
        stats: stats,
        now: now,
        lastDvrs: dvrs.getLatestDvrsResult(),
        snoozedUntil: storage.loadDvrsNudgeSnoozedUntil(),
        dvrsReminderEnabled: settings.dvrsReminderEnabled,
        intervalDays: AppDefaults.dvrsReminderDays,
      );
    });
  }

  Future<void> _snooze() async {
    if (_snoozing) return;
    setState(() => _snoozing = true);
    try {
      await widget.onSnoozeDvrsNudge();
      if (mounted) _reload();
    } catch (_) {
      if (mounted) {
        final s = context.read<SettingsProvider>().strings;
        ScaffoldMessenger.maybeOf(
          context,
        )?.showSnackBar(SnackBar(content: Text(s.daySummaryNudgeError)));
      }
    } finally {
      if (mounted) setState(() => _snoozing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = context.watch<SettingsProvider>().strings;
    final snap = _snap;

    final content = Column(
      children: [
        if (!widget.embedded)
          PanelHeader(
            title: s.daySummaryTitle,
            onLeading: widget.onClose,
            leadingTooltip: s.close,
            trailingIcon: Icons.wb_sunny_outlined,
          ),
        Expanded(
          child: snap == null
              ? const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                )
              : _body(theme, s, snap),
        ),
      ],
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: LiquidGlass(
          fillOpacity: 0.8,
          blur: 20,
          child: PanelEntrance(child: content),
        ),
      ),
    );
  }

  Widget _body(ThemeData theme, AppStrings s, DaySummarySnapshot snap) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _statsRow(theme, s, snap),
        const SizedBox(height: 14),
        _dvrsCard(theme, s, snap),
        if (snap.dvrsNudgeDue) ...[
          const SizedBox(height: 14),
          _nudgeBanner(theme, s, snap),
        ],
        const SizedBox(height: 14),
        _insightCard(theme, s, snap),
        const SizedBox(height: 18),
        _primaryAction(s, snap),
        const SizedBox(height: 10),
        _secondaryActions(s, snap),
        const SizedBox(height: 16),
        Text(
          s.daySummaryDisclaimer,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: AppTypography.supporting,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _statsRow(ThemeData theme, AppStrings s, DaySummarySnapshot snap) {
    final todayValue = snap.todayReminders == 0
        ? '—'
        : '${snap.todayCompleted}/${snap.todayReminders}';
    final adhValue = snap.hasAdherence7
        ? '${(snap.adherence7 * 100).round()}%'
        : '—';

    return Row(
      children: [
        Expanded(
          child: _miniStat(
            theme,
            icon: Icons.today_outlined,
            color: AppColors.idleBall,
            label: s.daySummaryTodayLabel,
            value: todayValue,
            hint: s.daySummaryTodayHint,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _miniStat(
            theme,
            icon: Icons.local_fire_department_outlined,
            color: const Color(0xFFFF8C00),
            label: s.progressStreakCurrentLabel,
            value: s.progressDaysCount(snap.streak),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _miniStat(
            theme,
            icon: Icons.percent,
            color: const Color(0xFF50C878),
            label: s.progressAdherence7Label,
            value: adhValue,
          ),
        ),
      ],
    );
  }

  Widget _miniStat(
    ThemeData theme, {
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    String? hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: AppTypography.supporting,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
            ),
          ),
          if (hint != null)
            Text(
              hint,
              style: TextStyle(
                fontSize: AppTypography.minimumReadable,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dvrsCard(ThemeData theme, AppStrings s, DaySummarySnapshot snap) {
    final last = snap.lastDvrs;
    final title = s.daySummaryDvrsLabel;
    final body = last == null
        ? s.daySummaryDvrsNever
        : s.daySummaryDvrsLastText(
            last.totalScore,
            last.classificationLabel,
            snap.daysSinceDvrs ?? 0,
          );

    final radius = BorderRadius.circular(14);
    return Semantics(
      button: true,
      label: '$title. $body',
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.35),
            borderRadius: radius,
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.16),
            ),
          ),
          child: InkWell(
            key: const ValueKey('day-summary-dvrs-card'),
            borderRadius: radius,
            onTap: widget.onDvrs,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.idleBall.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.assignment_outlined,
                      color: AppColors.idleBall,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.76,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          body,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.3,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.92,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.idleBall,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _nudgeBanner(ThemeData theme, AppStrings s, DaySummarySnapshot snap) {
    final body = snap.lastDvrs == null
        ? s.daySummaryNudgeBodyNever
        : s.daySummaryNudgeBodyDue;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFF8C00).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFF8C00).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notifications_active_outlined,
                color: Color(0xFFFF8C00),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.daySummaryNudgeTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFF8C00),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: _snoozing ? null : _snooze,
              icon: const Icon(Icons.snooze_rounded, size: 18),
              label: Text(s.daySummaryNudgeDismiss),
            ),
          ),
        ],
      ),
    );
  }

  Widget _insightCard(ThemeData theme, AppStrings s, DaySummarySnapshot snap) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.idleBall.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.idleBall.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: AppColors.idleBall,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.progressInsightLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: AppColors.idleBall,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  snap.insight.message,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryAction(AppStrings s, DaySummarySnapshot snap) {
    final dvrsDue = snap.dvrsNudgeDue;
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        key: const ValueKey('day-summary-primary-action'),
        onPressed: dvrsDue ? widget.onDvrs : widget.onStartBreak,
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        icon: Icon(
          dvrsDue ? Icons.assignment_outlined : Icons.play_circle_outline,
          size: 19,
        ),
        label: Text(dvrsDue ? s.daySummaryNudgeDo : s.daySummaryCtaBreak),
      ),
    );
  }

  Widget _secondaryActions(AppStrings s, DaySummarySnapshot snap) {
    return Row(
      children: [
        Expanded(
          child: TextButton.icon(
            onPressed: snap.dvrsNudgeDue ? widget.onStartBreak : widget.onDvrs,
            icon: Icon(
              snap.dvrsNudgeDue
                  ? Icons.play_circle_outline
                  : Icons.assignment_outlined,
              size: 17,
            ),
            label: Text(
              snap.dvrsNudgeDue ? s.daySummaryCtaBreak : s.daySummaryCtaDvrs,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextButton.icon(
            onPressed: widget.onProgress,
            icon: const Icon(Icons.trending_up, size: 17),
            label: Text(s.daySummaryCtaProgress),
          ),
        ),
      ],
    );
  }
}
