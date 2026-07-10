import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../l10n/feature_strings.dart';
import '../../models/screen_time_data.dart';
import '../../providers/settings_provider.dart';
import '../../services/dvrs_engine.dart';
import '../../services/dvrs_storage_service.dart';
import '../../services/screen_time_service.dart';
import '../../services/storage_service.dart';
import '../../ui/app_theme.dart';
import '../../ui/glass_card.dart';
import '../../ui/panel_state_view.dart';
import '../../ui/score_gauge.dart';
import '../../ui/section_header.dart';
import '../../ui/stat_tile.dart';
import '../../ui/trend_line_chart.dart';
import '../../utils/constants.dart';
import '../dvrs/dvrs_history_view.dart';
import '../dvrs/dvrs_ui.dart';
import '../liquid_glass.dart';

// ---- Formatação de duração ----

String _fmtSecs(int secs) {
  final m = secs ~/ 60;
  final h = m ~/ 60;
  final min = m % 60;
  if (h > 0) return '${h}h ${min}min';
  return '$m min';
}

// ============================================================
// Gráfico de barras (tempo de tela)
// ============================================================

class _BarChart extends StatelessWidget {
  const _BarChart({
    required this.values,
    required this.labels,
    this.highlightIdx,
    required this.fmtValue,
  });

  final List<int> values;
  final List<String> labels;
  final int? highlightIdx;
  final String Function(int) fmtValue;

  @override
  Widget build(BuildContext context) {
    final maxVal = values.fold<int>(0, (m, v) => v > m ? v : m);
    final safeMax = maxVal == 0 ? 1 : maxVal;
    final dense = values.length > 12;

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < values.length; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: dense ? 1 : 2),
                    child: _bar(values[i] / safeMax, i == highlightIdx, fmtValue(values[i])),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              Expanded(
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                    color: i == highlightIdx
                        ? AppColors.idleBall
                        : AppColors.textSecondary,
                    fontSize: dense ? 9 : 11,
                    fontWeight: i == highlightIdx
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _bar(double fraction, bool highlighted, String tooltip) {
    final clamped = fraction <= 0 ? 0.0 : fraction.clamp(0.04, 1.0);
    return Tooltip(
      message: tooltip,
      child: FractionallySizedBox(
        alignment: Alignment.bottomCenter,
        heightFactor: clamped == 0 ? 0.004 : clamped,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: highlighted
                  ? [AppColors.idleBall, AppColors.idleBall.withValues(alpha: 0.6)]
                  : [
                      AppColors.idleBall.withValues(alpha: 0.55),
                      AppColors.idleBall.withValues(alpha: 0.25),
                    ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Aba 1 — Resumo
// ============================================================

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final screenTime = context.watch<ScreenTimeService>();
    final now = DateTime.now();
    final todaySecs = screenTime.data.secondsForDay(now);
    final screenTodayLabel = _fmtSecs(todaySecs);

    // DVRS — reusa as variáveis que a aba já usava.
    final dvrsHistory = context.read<DvrsStorageService>().getDvrsHistory();
    final latest = dvrsHistory.isNotEmpty ? dvrsHistory.last : null;
    final previous =
        dvrsHistory.length >= 2 ? dvrsHistory[dvrsHistory.length - 2] : null;
    final trend = (latest != null && previous != null)
        ? compareDvrsTrend(previous, latest)
        : null;

    // Adesão às pausas — 7 dias.
    final breakStats = context.read<StorageService>().loadBreakStats();
    final adh7Start = now.subtract(const Duration(days: 6));
    final double? adherence7 =
        breakStats.sumForRange(adh7Start, now).reminders > 0
            ? breakStats.adherenceForRange(adh7Start, now)
            : null;

    // Sparkline de tempo de tela — últimos 7 dias.
    final last7 = <(DateTime, double)>[
      for (final p in screenTime.data.dailySeries(now, 7))
        (p.day, p.seconds.toDouble()),
    ];

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: StatTile(
                label: context.read<SettingsProvider>().strings.progressAdherence7Label,
                value: adherence7 == null
                    ? '—'
                    : '${(adherence7 * 100).round()}%',
                ringValue: adherence7 ?? 0,
                icon: Icons.free_breakfast_outlined,
                color: semantic.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                label: context.read<SettingsProvider>().strings.dashboardScreenToday,
                value: screenTodayLabel,
                icon: Icons.desktop_windows_outlined,
                footer: last7.length >= 2
                    ? TrendLineChart(
                        points: last7,
                        showGrid: false,
                        dateLabels: false,
                        height: 44,
                        formatValue: (v) => _fmtSecs(v.round()),
                      )
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader('DVRS — Risco Visual Digital'),
              if (latest == null)
                Text(
                  'Responda o DVRS para acompanhar seu risco visual digital.',
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
                )
              else ...[
                Center(
                  child: ScoreGauge(
                    score: latest.totalScore,
                    color: DvrsUi.classificationColor(latest.classification),
                    segments: DvrsUi.classificationSegments,
                    size: 150,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: DvrsUi.classificationChip(latest.classification),
                ),
                // Linha de tendência (compareDvrsTrend) — mantida da versão anterior.
                if (trend != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(DvrsUi.trendIcon(trend),
                          size: 16, color: DvrsUi.trendColor(trend)),
                      const SizedBox(width: 6),
                      Text(
                        DvrsUi.trendLabel(trend),
                        style: TextStyle(
                          fontSize: 12,
                          color: DvrsUi.trendColor(trend),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        DvrsUi.disclaimerBanner(theme),
      ],
    );
  }
}

// ============================================================
// Aba 2 — Tempo de Tela
// ============================================================

enum _TimeRange { week, month, year }

class _ScreenTimeTab extends StatefulWidget {
  const _ScreenTimeTab();

  @override
  State<_ScreenTimeTab> createState() => _ScreenTimeTabState();
}

class _ScreenTimeTabState extends State<_ScreenTimeTab> {
  _TimeRange _range = _TimeRange.week;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenTime = context.watch<ScreenTimeService>();
    final data = screenTime.data;
    final now = DateTime.now();
    final settings = context.watch<SettingsProvider>();
    final strings = settings.strings;
    final f = FeatureStrings.of(settings.value.languageCode);
    final todaySecs = data.secondsForDay(now);

    if (!settings.value.screenTimeTracking) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: PanelStateView(
          tone: PanelStateTone.unavailable,
          icon: Icons.desktop_access_disabled_outlined,
          title: f.stateScreenUnavailableTitle,
          message: f.stateScreenUnavailableMessage,
        ),
      );
    }

    final series = switch (_range) {
      _TimeRange.week  => data.weekSeries(now),
      _TimeRange.month => data.monthSeries(now),
      _TimeRange.year  => data.yearSeries(now),
    };

    final labels = _buildLabels(_range, series, strings);
    final hlIdx = _highlightIdx(_range, series, now);
    final total = series.fold<int>(0, (s, p) => s + p.seconds);
    final nonZero = series.where((p) => p.seconds > 0).length;
    final avg = nonZero == 0 ? 0 : (total / nonZero).round();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Card de hoje
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.idleBall.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.idleBall.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.today, color: AppColors.idleBall, size: 22),
              const SizedBox(width: 12),
              const Text(
                'Hoje',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const Spacer(),
              Text(
                _fmtSecs(todaySecs),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Seletor de período
        Row(
          children: [
            _rangeBtn(theme, _TimeRange.week, 'Semana'),
            const SizedBox(width: 8),
            _rangeBtn(theme, _TimeRange.month, 'Mês'),
            const SizedBox(width: 8),
            _rangeBtn(theme, _TimeRange.year, 'Ano'),
          ],
        ),
        const SizedBox(height: 14),
        if (total == 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: PanelStateView(
              icon: Icons.monitor_heart_outlined,
              title: f.stateScreenEmptyTitle,
              message: f.stateScreenEmptyMessage,
            ),
          )
        else ...[
          SizedBox(
            height: 200,
            child: _BarChart(
              values: [for (final p in series) p.seconds],
              labels: labels,
              highlightIdx: hlIdx,
              fmtValue: _fmtSecs,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _statBox(theme, 'Total no período', _fmtSecs(total)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statBox(theme, 'Média diária', _fmtSecs(avg)),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _rangeBtn(ThemeData theme, _TimeRange range, String label) {
    final sel = _range == range;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _range = range),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: sel
                ? AppColors.idleBall.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: sel ? AppColors.idleBall : AppColors.glassBorder,
              width: sel ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _statBox(ThemeData theme, String label, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.glassBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  List<String> _buildLabels(
    _TimeRange range,
    List<ScreenTimePoint> series,
    AppStrings s,
  ) {
    switch (range) {
      case _TimeRange.week:
        return [for (final p in series) s.weekdayShort[p.day.weekday - 1]];
      case _TimeRange.month:
        return [
          for (final p in series)
            (p.day.day == 1 || p.day.day % 5 == 0) ? '${p.day.day}' : '',
        ];
      case _TimeRange.year:
        return [for (final p in series) s.monthShort[p.day.month - 1]];
    }
  }

  int? _highlightIdx(
    _TimeRange range,
    List<ScreenTimePoint> series,
    DateTime now,
  ) {
    final key = ScreenTimeData.dayKey(DateTime(now.year, now.month, now.day));
    for (var i = 0; i < series.length; i++) {
      final p = series[i];
      switch (range) {
        case _TimeRange.week:
        case _TimeRange.month:
          if (ScreenTimeData.dayKey(p.day) == key) return i;
          break;
        case _TimeRange.year:
          if (p.day.month == now.month) return i;
          break;
      }
    }
    return null;
  }
}

// ============================================================
// DashboardScreen principal
// ============================================================

/// Dashboard integrado de acompanhamento ao longo do tempo.
///
/// Agrega em 3 abas: Resumo, Tempo de Tela e DVRS (Índice de Risco Visual
/// Digital). Todos os dados são locais — lidos diretamente dos serviços já
/// instanciados no Provider tree. Linguagem educativa, nunca diagnóstica.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.onClose, this.embedded = false});

  final VoidCallback onClose;
  final bool embedded;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = context.watch<SettingsProvider>().strings;
    final content = Column(
      children: [
        if (!widget.embedded) _header(theme, strings),
        if (widget.embedded)
          Material(
            color: theme.colorScheme.surface.withValues(alpha: 0.2),
            child: TabBar(
              controller: _tabs,
              labelColor: AppColors.idleBall,
              unselectedLabelColor:
                  theme.colorScheme.onSurface.withValues(alpha: 0.65),
              indicatorColor: AppColors.idleBall,
              tabs: [
                Tab(text: strings.dashboardTabOverview),
                Tab(text: strings.dashboardTabScreen),
                Tab(text: strings.dashboardTabDvrs),
              ],
            ),
          ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: const [
              _OverviewTab(),
              _ScreenTimeTab(),
              DvrsHistoryView(),
            ],
          ),
        ),
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

  Widget _header(ThemeData theme, AppStrings strings) => Container(
    decoration: BoxDecoration(
      color: theme.colorScheme.surface.withValues(alpha: 0.5),
      border: Border(
        bottom: BorderSide(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
    ),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onClose,
                tooltip: strings.close,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  strings.menuDashboard,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tabs,
          indicatorColor: AppColors.idleBall,
          labelColor: AppColors.idleBall,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: [
            Tab(
              iconMargin: const EdgeInsets.only(bottom: 2),
              icon: const Icon(Icons.space_dashboard_outlined, size: 18),
              text: strings.dashboardTabOverview,
            ),
            Tab(
              iconMargin: const EdgeInsets.only(bottom: 2),
              icon: const Icon(Icons.monitor_outlined, size: 18),
              text: strings.dashboardTabScreen,
            ),
            Tab(
              iconMargin: const EdgeInsets.only(bottom: 2),
              icon: const Icon(Icons.assignment_outlined, size: 18),
              text: strings.dashboardTabDvrs,
            ),
          ],
        ),
      ],
    ),
  );
}

