import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../providers/settings_provider.dart';
import '../../services/daily_insight.dart';
import '../../services/dvrs_storage_service.dart';
import '../../services/storage_service.dart';
import '../../utils/constants.dart';
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
    await widget.onSnoozeDvrsNudge();
    if (!mounted) return;
    setState(() => _snoozing = false);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = context.watch<SettingsProvider>().strings;
    final snap = _snap;

    final content = Column(
      children: [
        if (!widget.embedded) _header(theme, s),
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
          child: content,
        ),
      ),
    );
  }

  Widget _header(ThemeData theme, AppStrings s) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.55),
          border: Border(
            bottom: BorderSide(color: AppColors.divider),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 14, 6),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: widget.onClose,
                tooltip: s.close,
                style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  s.daySummaryTitle,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.idleBall.withValues(alpha: 0.16),
                ),
                child: const Icon(
                  Icons.wb_sunny_outlined,
                  color: AppColors.idleBall,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      );

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
        _primaryActions(s),
        const SizedBox(height: 10),
        _secondaryActions(s),
        const SizedBox(height: 16),
        Text(
          s.daySummaryDisclaimer,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _statsRow(
    ThemeData theme,
    AppStrings s,
    DaySummarySnapshot snap,
  ) {
    final todayValue = snap.todayReminders == 0
        ? '—'
        : '${snap.todayCompleted}/${snap.todayReminders}';
    final adhValue =
        snap.hasAdherence7 ? '${(snap.adherence7 * 100).round()}%' : '—';

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
              fontSize: 11,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          if (hint != null)
            Text(
              hint,
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dvrsCard(
    ThemeData theme,
    AppStrings s,
    DaySummarySnapshot snap,
  ) {
    final last = snap.lastDvrs;
    final title = s.daySummaryDvrsLabel;
    final body = last == null
        ? s.daySummaryDvrsNever
        : s.daySummaryDvrsLastText(
            last.totalScore,
            last.classificationLabel,
            snap.daysSinceDvrs ?? 0,
          );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
        ),
      ),
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
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.3,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _nudgeBanner(
    ThemeData theme,
    AppStrings s,
    DaySummarySnapshot snap,
  ) {
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
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _snoozing ? null : _snooze,
                  child: Text(s.daySummaryNudgeDismiss),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: widget.onDvrs,
                  child: Text(s.daySummaryNudgeDo),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _insightCard(
    ThemeData theme,
    AppStrings s,
    DaySummarySnapshot snap,
  ) {
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

  Widget _primaryActions(AppStrings s) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: widget.onStartBreak,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 46),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            icon: const Icon(Icons.play_circle_outline, size: 18),
            label: Text(s.daySummaryCtaBreak),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: widget.onDvrs,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 46),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            icon: const Icon(Icons.assignment, size: 18),
            label: Text(s.daySummaryCtaDvrs),
          ),
        ),
      ],
    );
  }

  Widget _secondaryActions(AppStrings s) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: widget.onProgress,
            icon: const Icon(Icons.trending_up, size: 16),
            label: Text(s.daySummaryCtaProgress),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: widget.onDashboard,
            icon: const Icon(Icons.dashboard_outlined, size: 16),
            label: Text(s.daySummaryCtaDashboard),
          ),
        ),
      ],
    );
  }
}
