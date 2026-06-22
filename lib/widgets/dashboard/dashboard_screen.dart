import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/checklist.dart';
import '../../models/osdi_assessment.dart';
import '../../models/screen_time_data.dart';
import '../../providers/settings_provider.dart';
import '../../services/checklist_storage_service.dart';
import '../../services/screen_time_service.dart';
import '../../services/storage_service.dart';
import '../../utils/constants.dart';
import '../checklists/checklist_ui.dart';
import '../liquid_glass.dart';

// ---- Entradas de checklist exibidas no resumo e seletor ----

typedef _ChecklistEntry = (ChecklistType, String, IconData);

const List<_ChecklistEntry> _kEntries = [
  (ChecklistType.visualErgonomics, 'Ergonomia visual', Icons.desktop_windows_outlined),
  (ChecklistType.screenEnvironment, 'Ambiente de tela', Icons.air_outlined),
  (ChecklistType.visualSymptoms, 'Sintomas visuais', Icons.remove_red_eye_outlined),
  (ChecklistType.warningSigns, 'Sinais de alerta', Icons.warning_amber_outlined),
  (ChecklistType.breakHabits, 'Pausas e hábitos', Icons.timer_outlined),
];

// ---- Helpers de severidade OSDI ----

String _osdiLabel(OsdiSeverity s) => switch (s) {
  OsdiSeverity.normal   => 'Normal',
  OsdiSeverity.mild     => 'Leve',
  OsdiSeverity.moderate => 'Moderado',
  OsdiSeverity.severe   => 'Grave',
};

Color _osdiColor(OsdiSeverity s) => switch (s) {
  OsdiSeverity.normal   => Colors.green,
  OsdiSeverity.mild     => Colors.amber,
  OsdiSeverity.moderate => Colors.orange,
  OsdiSeverity.severe   => Colors.red,
};

// ---- Formatação de duração ----

String _fmtSecs(int secs) {
  final m = secs ~/ 60;
  final h = m ~/ 60;
  final min = m % 60;
  if (h > 0) return '${h}h ${min}min';
  return '$m min';
}

// ---- Cor por tipo de checklist ----

Color _typeColor(ChecklistType t) => switch (t) {
  ChecklistType.visualErgonomics  => const Color(0xFF4A90E2),
  ChecklistType.screenEnvironment => const Color(0xFF50C878),
  ChecklistType.visualSymptoms    => const Color(0xFFFF8C00),
  ChecklistType.warningSigns      => const Color(0xFFFF4444),
  ChecklistType.breakHabits       => const Color(0xFF9B59B6),
  _                               => AppColors.idleBall,
};

String _typeLabel(ChecklistType t) {
  for (final e in _kEntries) {
    if (e.$1 == t) return e.$2;
  }
  return t.id;
}

// ============================================================
// Modelo de ponto para gráficos
// ============================================================

class _Pt {
  const _Pt({required this.date, required this.value});
  final DateTime date;
  final double value;
}

// ============================================================
// Painter do gráfico de linha
// ============================================================

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.pts,
    required this.minY,
    required this.maxY,
    required this.color,
    required this.refYs,
    required this.refColors,
    this.hoveredIdx,
  });

  final List<_Pt> pts;
  final double minY, maxY;
  final Color color;
  final List<double> refYs;
  final List<Color> refColors;
  final int? hoveredIdx;

  @override
  void paint(Canvas canvas, Size size) {
    if (pts.isEmpty) return;
    const lp = 4.0, rp = 4.0, tp = 6.0, bp = 2.0;
    final cL = lp, cR = size.width - rp;
    final cT = tp, cB = size.height - bp;
    final cW = cR - cL, cH = cB - cT;
    final yR = (maxY - minY).abs().clamp(1.0, double.infinity);

    double nx(int i) => pts.length == 1
        ? cL + cW / 2
        : cL + cW * i / (pts.length - 1);

    double ny(double v) => cB - ((v - minY) / yR).clamp(0.0, 1.0) * cH;

    // Linhas de referência tracejadas
    for (var r = 0; r < refYs.length; r++) {
      final rv = refYs[r];
      if (rv < minY || rv > maxY) continue;
      final ry = ny(rv);
      final p = Paint()
        ..color = refColors[r].withValues(alpha: 0.55)
        ..strokeWidth = 1;
      var x = cL;
      while (x < cR) {
        canvas.drawLine(Offset(x, ry), Offset(math.min(x + 5, cR), ry), p);
        x += 9;
      }
    }

    // Área sombreada
    final area = Path()..moveTo(nx(0), cB);
    for (var i = 0; i < pts.length; i++) {
      area.lineTo(nx(i), ny(pts[i].value));
    }
    area.lineTo(nx(pts.length - 1), cB);
    area.close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0.02)],
        ).createShader(Rect.fromLTWH(cL, cT, cW, cH)),
    );

    // Linha principal
    final linePath = Path();
    for (var i = 0; i < pts.length; i++) {
      final x = nx(i), y = ny(pts[i].value);
      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );

    // Pontos
    for (var i = 0; i < pts.length; i++) {
      final px = nx(i), py = ny(pts[i].value);
      final big = (i == hoveredIdx) || (i == pts.length - 1);
      canvas.drawCircle(Offset(px, py), big ? 5 : 3.5, Paint()..color = color);
      if (big) {
        canvas.drawCircle(
          Offset(px, py),
          big ? 3 : 2,
          Paint()..color = Colors.white.withValues(alpha: 0.9),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_LinePainter o) =>
      o.pts != pts ||
      o.hoveredIdx != hoveredIdx ||
      o.minY != minY ||
      o.maxY != maxY;
}

// ============================================================
// Widget de gráfico de linha
// ============================================================

class _LineChart extends StatefulWidget {
  const _LineChart({
    required this.pts,
    required this.color,
    this.minY,
    this.maxY,
    this.refYs = const [],
    this.refColors = const [],
    this.refLabels = const [],
    required this.fmtY,
    this.height = 150.0,
  });

  final List<_Pt> pts;
  final Color color;
  final double? minY, maxY;
  final List<double> refYs;
  final List<Color> refColors;
  final List<String> refLabels;
  final String Function(double) fmtY;
  final double height;

  @override
  State<_LineChart> createState() => _LineChartState();
}

class _LineChartState extends State<_LineChart> {
  int? _hovered;
  final _key = GlobalKey();

  double get _min {
    if (widget.minY != null) return widget.minY!;
    if (widget.pts.isEmpty) return 0;
    return widget.pts.map((p) => p.value).reduce(math.min).clamp(0.0, double.infinity);
  }

  double get _max {
    if (widget.maxY != null) return widget.maxY!;
    if (widget.pts.isEmpty) return 100;
    final mx = widget.pts.map((p) => p.value).reduce(math.max);
    return mx == 0 ? 10 : mx * 1.15;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pts = widget.pts;

    if (pts.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.show_chart,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'Sem dados ainda',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final minY = _min;
    final maxY = _max;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legenda de linhas de referência
        if (widget.refLabels.isNotEmpty) ...[
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              for (var i = 0; i < widget.refLabels.length; i++)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 14,
                      height: 2,
                      color: widget.refColors[i].withValues(alpha: 0.75),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.refLabels[i],
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        // Gráfico com eixo Y
        SizedBox(
          height: widget.height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Eixo Y
              SizedBox(
                width: 34,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(widget.fmtY(maxY), style: _axisStyle(theme)),
                    Text(widget.fmtY((maxY + minY) / 2), style: _axisStyle(theme)),
                    Text(widget.fmtY(minY), style: _axisStyle(theme)),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              // Área do gráfico
              Expanded(
                child: MouseRegion(
                  onHover: (e) {
                    final box =
                        _key.currentContext?.findRenderObject() as RenderBox?;
                    if (box == null || pts.isEmpty) return;
                    final local = box.globalToLocal(e.position);
                    final w = box.size.width - 8;
                    final rel =
                        ((local.dx - 4) / w).clamp(0.0, 1.0);
                    final idx = (rel * (pts.length - 1))
                        .round()
                        .clamp(0, pts.length - 1);
                    setState(() => _hovered = idx);
                  },
                  onExit: (_) => setState(() => _hovered = null),
                  child: Stack(
                    children: [
                      CustomPaint(
                        key: _key,
                        size: Size.infinite,
                        painter: _LinePainter(
                          pts: pts,
                          minY: minY,
                          maxY: maxY,
                          color: widget.color,
                          refYs: widget.refYs,
                          refColors: widget.refColors,
                          hoveredIdx: _hovered,
                        ),
                      ),
                      // Tooltip de hover
                      if (_hovered != null)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _shortDate(pts[_hovered!].date),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  widget.fmtY(pts[_hovered!].value),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Eixo X
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 38),
          child: _xLabels(theme, pts),
        ),
      ],
    );
  }

  TextStyle _axisStyle(ThemeData t) => TextStyle(
    fontSize: 9,
    color: t.colorScheme.onSurface.withValues(alpha: 0.45),
  );

  Widget _xLabels(ThemeData theme, List<_Pt> pts) {
    if (pts.length <= 1) return const SizedBox.shrink();
    final step = math.max(1, (pts.length / 7).ceil());
    return Row(
      children: [
        for (var i = 0; i < pts.length; i++)
          Expanded(
            child: (i == 0 || i == pts.length - 1 || i % step == 0)
                ? Text(
                    _shortDate(pts[i].date),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      color: i == _hovered
                          ? widget.color
                          : theme.colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
      ],
    );
  }

  static String _shortDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
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
  const _OverviewTab({required this.osdi});
  final List<OsdiAssessment> osdi;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenTime = context.watch<ScreenTimeService>();
    final now = DateTime.now();
    final todaySecs = screenTime.data.secondsForDay(now);
    final lastOsdi = osdi.isNotEmpty ? osdi.last : null;
    final clStorage = context.read<ChecklistStorageService>();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _bigCard(
          theme,
          icon: Icons.monitor_outlined,
          color: AppColors.idleBall,
          label: 'Tempo de tela hoje',
          value: _fmtSecs(todaySecs),
          sub: _screenTimeSub(todaySecs),
        ),
        const SizedBox(height: 12),
        _bigCard(
          theme,
          icon: Icons.assignment_outlined,
          color: lastOsdi != null
              ? _osdiColor(lastOsdi.severity)
              : Colors.blueGrey,
          label: 'Pontuação OSDI',
          value: lastOsdi != null
              ? lastOsdi.score.toStringAsFixed(1)
              : '—',
          sub: lastOsdi != null
              ? '${_osdiLabel(lastOsdi.severity)} · ${ChecklistUi.formatDate(lastOsdi.completedAt)}'
              : 'Nenhuma avaliação ainda',
        ),
        const SizedBox(height: 20),
        Text(
          'Últimos resultados dos checklists',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 10),
        for (final e in _kEntries) ...[
          _checklistRow(theme, e, clStorage),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 16),
        Text(
          'Dashboard educativo — não substitui consulta médica.',
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

  String _screenTimeSub(int secs) {
    final h = secs ~/ 3600;
    if (secs == 0) return 'Nenhum registro hoje';
    if (h >= 8) return 'Alto uso — considere pausas frequentes';
    if (h >= 6) return 'Uso elevado';
    if (h >= 4) return 'Uso moderado';
    return 'Uso dentro do esperado';
  }

  Widget _bigCard(
    ThemeData theme, {
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required String sub,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  sub,
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

  Widget _checklistRow(
    ThemeData theme,
    _ChecklistEntry e,
    ChecklistStorageService storage,
  ) {
    final latest = storage.latestByType(e.$1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Icon(e.$3, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(e.$2, style: const TextStyle(fontSize: 13)),
          ),
          if (latest != null) ...[
            ChecklistUi.riskChip(latest.riskLevel, dense: true),
            const SizedBox(width: 8),
            Text(
              ChecklistUi.formatDate(latest.createdAt),
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ] else
            Text(
              'Não preenchido',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
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
    final strings = context.read<SettingsProvider>().strings;
    final todaySecs = data.secondsForDay(now);

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
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'Nenhum dado neste período',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
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
// Aba 3 — OSDI
// ============================================================

class _OsdiTab extends StatelessWidget {
  const _OsdiTab({required this.osdi});
  final List<OsdiAssessment> osdi;

  static const _refYs = [12.0, 22.0, 32.0];
  static const _refColors = [Colors.green, Colors.amber, Colors.deepOrange];
  static const _refLabels = ['Normal ≤12', 'Leve ≤22', 'Moderado ≤32'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final last30 = osdi.length > 30 ? osdi.sublist(osdi.length - 30) : osdi;
    final pts = [
      for (final a in last30) _Pt(date: a.completedAt, value: a.score),
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (osdi.isNotEmpty) ...[
          _lastScoreCard(theme, osdi.last),
          const SizedBox(height: 20),
        ],
        Text(
          'Evolução da pontuação OSDI',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 10),
        _LineChart(
          pts: pts,
          color: AppColors.idleBall,
          minY: 0,
          maxY: 100,
          refYs: _refYs,
          refColors: _refColors,
          refLabels: _refLabels,
          fmtY: (v) => v.toStringAsFixed(0),
          height: 160,
        ),
        const SizedBox(height: 24),
        Text(
          'Últimas avaliações',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 10),
        if (osdi.isEmpty)
          _empty(theme,
              'Nenhuma avaliação OSDI ainda.\nUse o menu > "OSDI" para iniciar.')
        else
          for (final a in osdi.reversed.take(10)) _osdiRow(theme, a),
      ],
    );
  }

  Widget _lastScoreCard(ThemeData theme, OsdiAssessment a) {
    final color = _osdiColor(a.severity);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Último OSDI',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                a.score.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _severityChip(a.severity),
                const SizedBox(height: 6),
                Text(
                  ChecklistUi.formatDate(a.completedAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          // Seta tendência
          if (osdi.length >= 2) _trendIcon(osdi[osdi.length - 2], a),
        ],
      ),
    );
  }

  Widget _trendIcon(OsdiAssessment prev, OsdiAssessment curr) {
    final delta = curr.score - prev.score;
    if (delta < -1) {
      return const Icon(Icons.trending_down, color: Colors.green, size: 28);
    } else if (delta > 1) {
      return const Icon(Icons.trending_up, color: Colors.orange, size: 28);
    }
    return const Icon(Icons.trending_flat, color: Colors.blueGrey, size: 28);
  }

  Widget _osdiRow(ThemeData theme, OsdiAssessment a) {
    final color = _osdiColor(a.severity);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Text(
              a.score.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            _severityChip(a.severity),
            const Spacer(),
            Text(
              ChecklistUi.formatDate(a.completedAt),
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _severityChip(OsdiSeverity s) {
    final color = _osdiColor(s);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        _osdiLabel(s),
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _empty(ThemeData theme, String msg) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Text(
      msg,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 13,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
      ),
    ),
  );
}

// ============================================================
// Aba 4 — Checklists
// ============================================================

class _ChecklistsTab extends StatefulWidget {
  const _ChecklistsTab();

  @override
  State<_ChecklistsTab> createState() => _ChecklistsTabState();
}

class _ChecklistsTabState extends State<_ChecklistsTab> {
  ChecklistType _selected = ChecklistType.visualSymptoms;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final storage = context.read<ChecklistStorageService>();
    final history = storage.getChecklistHistory(type: _selected);
    final last30 = history.length > 30 ? history.sublist(history.length - 30) : history;
    final pts = [
      for (final r in last30)
        _Pt(date: r.createdAt, value: r.totalScore.toDouble()),
    ];
    final color = _typeColor(_selected);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Seletor de tipo
        Text(
          'Selecione o checklist',
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final e in _kEntries) _typeChip(theme, e, e.$1 == _selected),
          ],
        ),
        const SizedBox(height: 20),
        // Gráfico
        Text(
          'Pontuação ao longo do tempo — ${_typeLabel(_selected)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 10),
        _LineChart(
          pts: pts,
          color: color,
          fmtY: (v) => v.toStringAsFixed(0),
          height: 150,
        ),
        const SizedBox(height: 24),
        // Últimos resultados
        Row(
          children: [
            Text(
              'Últimos resultados',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            if (history.isNotEmpty) ...[
              const Spacer(),
              Text(
                '${history.length} registro${history.length == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        if (history.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Text(
              'Nenhum resultado salvo para este checklist.\n'
              'Abra o menu > "Checklists" para preencher.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          )
        else
          for (final r in history.reversed.take(10)) _resultRow(theme, r),
      ],
    );
  }

  Widget _typeChip(ThemeData theme, _ChecklistEntry e, bool selected) {
    final color = _typeColor(e.$1);
    return GestureDetector(
      onTap: () => setState(() => _selected = e.$1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? color
                : theme.colorScheme.onSurface.withValues(alpha: 0.18),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              e.$3,
              size: 14,
              color: selected
                  ? color
                  : theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
            const SizedBox(width: 5),
            Text(
              e.$2,
              style: TextStyle(
                fontSize: 12,
                color: selected
                    ? color
                    : theme.colorScheme.onSurface.withValues(alpha: 0.75),
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultRow(ThemeData theme, ChecklistResult r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Text(
              '${r.totalScore} pts',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 10),
            ChecklistUi.riskChip(r.riskLevel, dense: true),
            const Spacer(),
            Text(
              ChecklistUi.formatDate(r.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// DashboardScreen principal
// ============================================================

/// Dashboard integrado de acompanhamento ao longo do tempo.
///
/// Agrega em 4 abas: Resumo, Tempo de Tela, OSDI e Checklists.
/// Todos os dados são locais — lidos diretamente dos serviços já
/// instanciados no Provider tree.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<OsdiAssessment> _osdi = const [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _osdi = context.read<StorageService>().loadOsdiHistory();
        });
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: LiquidGlass(
          fillOpacity: 0.8,
          blur: 20,
          child: Column(
            children: [
              _header(theme),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _OverviewTab(osdi: _osdi),
                    const _ScreenTimeTab(),
                    _OsdiTab(osdi: _osdi),
                    const _ChecklistsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(ThemeData theme) => Container(
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
                tooltip: 'Fechar',
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'Dashboard — Acompanhamento',
                  style: TextStyle(
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
          tabs: const [
            Tab(
              iconMargin: EdgeInsets.only(bottom: 2),
              icon: Icon(Icons.space_dashboard_outlined, size: 18),
              text: 'Resumo',
            ),
            Tab(
              iconMargin: EdgeInsets.only(bottom: 2),
              icon: Icon(Icons.monitor_outlined, size: 18),
              text: 'Tela',
            ),
            Tab(
              iconMargin: EdgeInsets.only(bottom: 2),
              icon: Icon(Icons.assignment_outlined, size: 18),
              text: 'OSDI',
            ),
            Tab(
              iconMargin: EdgeInsets.only(bottom: 2),
              icon: Icon(Icons.checklist_outlined, size: 18),
              text: 'Checklists',
            ),
          ],
        ),
      ],
    ),
  );
}
