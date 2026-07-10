import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../l10n/feature_strings.dart';
import '../../models/break_stats_data.dart';
import '../../providers/settings_provider.dart';
import '../../services/daily_insight.dart';
import '../../services/dvrs_storage_service.dart';
import '../../services/storage_service.dart';
import '../../utils/constants.dart';
import '../../ui/panel_state_view.dart';
import '../liquid_glass.dart';

/// Tela "Meu Progresso": devolve ao usuário a narrativa dos dados de pausas já
/// coletados localmente ([BreakStatsData]).
///
/// Foco em **reforço de hábito sem punição**: sequência (streak) respeitosa,
/// taxa de adesão recente, total de pausas e um insight proativo. Todos os
/// dados são locais — lidos diretamente do [StorageService].
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key, required this.onClose, this.embedded = false});

  final VoidCallback onClose;
  final bool embedded;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  BreakStatsData _stats = BreakStatsData.empty();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _stats = context.read<StorageService>().loadBreakStats());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = context.read<SettingsProvider>().strings;
    final content = Column(
      children: [
        if (!widget.embedded) _header(theme, s),
        Expanded(child: _body(theme, s)),
      ],
    );
    if (widget.embedded) return content;
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
      border: const Border(
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
              s.progressTitle,
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
              Icons.local_florist_outlined,
              color: AppColors.idleBall,
              size: 20,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _body(ThemeData theme, AppStrings s) {
    if (_stats.totalReminders == 0) return _empty(s);

    final now = DateTime.now();
    final streak = _stats.currentStreak(now);
    final best = _stats.bestStreak();
    final total = _stats.totalCompleted;

    final from7 = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));
    final from30 = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 29));
    final adh7 = _stats.adherenceForRange(from7, now);
    final adh30 = _stats.adherenceForRange(from30, now);
    final has7 = _stats.sumForRange(from7, now).reminders > 0;
    final has30 = _stats.sumForRange(from30, now).reminders > 0;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _streakCard(theme, s, streak, best),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _statCard(
                theme,
                icon: Icons.task_alt,
                color: const Color(0xFF50C878),
                label: s.progressTotalBreaksLabel,
                value: '$total',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                theme,
                icon: Icons.percent,
                color: AppColors.idleBall,
                label: s.progressAdherence7Label,
                value: has7 ? '${(adh7 * 100).round()}%' : '—',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                theme,
                icon: Icons.calendar_month_outlined,
                color: const Color(0xFF9B59B6),
                label: s.progressAdherence30Label,
                value: has30 ? '${(adh30 * 100).round()}%' : '—',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _insightCard(theme, s),
        const SizedBox(height: 20),
        Text(
          s.progressDisclaimer,
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

  Widget _streakCard(ThemeData theme, AppStrings s, int streak, int best) {
    const accent = Color(0xFFFF8C00);
    final active = streak > 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: active ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: active ? 0.4 : 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              active ? Icons.local_fire_department : Icons.local_fire_department_outlined,
              color: accent,
              size: 32,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.progressStreakCurrentLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s.progressDaysCount(streak),
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: active
                        ? accent
                        : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                if (active)
                  Text(
                    '${s.progressStreakBestLabel}: ${s.progressDaysCount(best)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  )
                else
                  Text(
                    s.progressStreakZeroHint,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    ThemeData theme, {
    required IconData icon,
    required Color color,
    required String label,
    required String value,
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
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
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
        ],
      ),
    );
  }

  Widget _insightCard(ThemeData theme, AppStrings s) {
    final storage = context.read<StorageService>();
    final lastDvrs = context.read<DvrsStorageService>().getLatestDvrsResult();
    final now = DateTime.now();
    final nudge = DailyInsightEngine.isDvrsNudgeDue(
      now: now,
      enabled: context.read<SettingsProvider>().value.dvrsReminderEnabled,
      lastDvrsAt: lastDvrs?.createdAt,
      snoozedUntil: storage.loadDvrsNudgeSnoozedUntil(),
      intervalDays: AppDefaults.dvrsReminderDays,
      totalCompletedBreaks: _stats.totalCompleted,
    );
    final text = DailyInsightEngine.buildInsight(
      strings: s,
      stats: _stats,
      now: now,
      lastDvrsAt: lastDvrs?.createdAt,
      dvrsNudgeDue: nudge,
    ).message;

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
          const Icon(Icons.lightbulb_outline, color: AppColors.idleBall, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.progressInsightLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: AppColors.idleBall,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
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

  Widget _empty(AppStrings s) {
    final f = FeatureStrings.of(
      context.read<SettingsProvider>().value.languageCode,
    );
    return Padding(
      padding: const EdgeInsets.all(32),
      child: PanelStateView(
        icon: Icons.insights_outlined,
        title: f.stateProgressEmptyTitle,
        message: s.progressEmpty,
      ),
    );
  }
}

