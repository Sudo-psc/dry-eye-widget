import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/screen_time_data.dart';
import '../utils/constants.dart';
import 'liquid_glass.dart';

/// Períodos de visualização do tempo de tela.
enum _Range { week, month, year }

/// Janela de visualização do tempo de uso de tela.
///
/// Mostra o total de hoje em destaque e um gráfico de barras com os períodos
/// semanal (dias da semana), mensal (dias do mês) e anual (12 meses). Não
/// depende de bibliotecas de gráficos — as barras são desenhadas com widgets
/// nativos.
class ScreenTimeDialog extends StatefulWidget {
  const ScreenTimeDialog({
    super.key,
    required this.strings,
    required this.data,
    required this.trackingEnabled,
    required this.onClose,
    required this.onClear,
  });

  final AppStrings strings;
  final ScreenTimeData data;
  final bool trackingEnabled;
  final VoidCallback onClose;
  final VoidCallback onClear;

  @override
  State<ScreenTimeDialog> createState() => _ScreenTimeDialogState();
}

class _ScreenTimeDialogState extends State<ScreenTimeDialog> {
  _Range _range = _Range.week;

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final now = DateTime.now();
    final data = widget.data;

    final series = switch (_range) {
      _Range.week => data.weekSeries(now),
      _Range.month => data.monthSeries(now),
      _Range.year => data.yearSeries(now),
    };

    final labels = _labelsFor(_range, series, s);
    final highlight = _highlightIndex(_range, series, now);

    final total = series.fold<int>(0, (sum, p) => sum + p.seconds);
    final nonZero = series.where((p) => p.seconds > 0).length;
    final average = nonZero == 0 ? 0 : (total / nonZero).round();

    return LiquidGlass(
      width: 560,
      constraints: const BoxConstraints(maxHeight: 740),
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
                  s.screenTimeTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
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
            s.screenTimeSubtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          _todayCard(s, formatDuration(data.secondsForDay(now), s)),
          const SizedBox(height: 16),
          if (!widget.trackingEnabled) ...[
            _hint(s.screenTimeDisabledHint),
            const SizedBox(height: 12),
          ],
          _rangeSelector(s),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (total == 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: _hint(s.screenTimeNoData)),
                    )
                  else ...[
                    SizedBox(
                      height: 260,
                      child: _BarChart(
                        values: [for (final p in series) p.seconds],
                        labels: labels,
                        highlightIndex: highlight,
                        formatValue: (v) => formatDuration(v, s),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _statBox(
                            s.screenTimeTotal,
                            formatDuration(total, s),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statBox(
                            s.screenTimeDailyAverage,
                            formatDuration(average, s),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const Divider(color: AppColors.glassBorder),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: total == 0 ? null : widget.onClear,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: Text(s.screenTimeClear),
              ),
              Text(
                s.screenTimeDisclaimer,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Componentes --------------------------------------------------------

  Widget _todayCard(AppStrings s, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.idleBall.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.idleBall, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.today, color: AppColors.idleBall, size: 22),
          const SizedBox(width: 12),
          Text(
            s.screenTimeToday,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rangeSelector(AppStrings s) {
    Widget button(_Range range, String label) {
      final selected = _range == range;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _range = range),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.idleBall.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? AppColors.idleBall : AppColors.glassBorder,
                width: selected ? 2 : 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        button(_Range.week, s.screenTimeWeek),
        const SizedBox(width: 10),
        button(_Range.month, s.screenTimeMonth),
        const SizedBox(width: 10),
        button(_Range.year, s.screenTimeYear),
      ],
    );
  }

  Widget _statBox(String label, String value) {
    return Container(
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
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
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
  }

  Widget _hint(String text) => Text(
    text,
    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
  );

  // --- Rótulos e destaque -------------------------------------------------

  List<String> _labelsFor(
    _Range range,
    List<ScreenTimePoint> series,
    AppStrings s,
  ) {
    switch (range) {
      case _Range.week:
        return [for (final p in series) s.weekdayShort[p.day.weekday - 1]];
      case _Range.month:
        // Rótulo a cada 5 dias para não poluir o eixo.
        return [
          for (final p in series)
            (p.day.day == 1 || p.day.day % 5 == 0) ? '${p.day.day}' : '',
        ];
      case _Range.year:
        return [for (final p in series) s.monthShort[p.day.month - 1]];
    }
  }

  int? _highlightIndex(
    _Range range,
    List<ScreenTimePoint> series,
    DateTime now,
  ) {
    final key = ScreenTimeData.dayKey(DateTime(now.year, now.month, now.day));
    for (var i = 0; i < series.length; i++) {
      final p = series[i];
      switch (range) {
        case _Range.week:
        case _Range.month:
          if (ScreenTimeData.dayKey(p.day) == key) return i;
          break;
        case _Range.year:
          if (p.day.month == now.month) return i;
          break;
      }
    }
    return null;
  }
}

/// Formata segundos como "Xh Ymin" (ou "Ymin" / "0 min").
String formatDuration(int seconds, AppStrings s) {
  final totalMinutes = seconds ~/ 60;
  final h = totalMinutes ~/ 60;
  final m = totalMinutes % 60;
  if (h > 0) return '$h${s.unitHour} $m${s.unitMin}';
  return '$m ${s.unitMin}';
}

/// Gráfico de barras vertical simples, com rótulos no eixo X e destaque
/// opcional de uma barra (ex.: hoje / mês atual).
class _BarChart extends StatelessWidget {
  const _BarChart({
    required this.values,
    required this.labels,
    required this.highlightIndex,
    required this.formatValue,
  });

  final List<int> values;
  final List<String> labels;
  final int? highlightIndex;
  final String Function(int) formatValue;

  @override
  Widget build(BuildContext context) {
    final maxValue = values.fold<int>(0, (m, v) => v > m ? v : m);
    final safeMax = maxValue == 0 ? 1 : maxValue;
    final dense = values.length > 12;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < values.length; i++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: dense ? 1 : 3,
                        ),
                        child: _bar(
                          fraction: values[i] / safeMax,
                          highlighted: i == highlightIndex,
                          tooltip: formatValue(values[i]),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
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
                        color: i == highlightIndex
                            ? AppColors.idleBall
                            : AppColors.textSecondary,
                        fontSize: dense ? 9 : 11,
                        fontWeight: i == highlightIndex
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _bar({
    required double fraction,
    required bool highlighted,
    required String tooltip,
  }) {
    // Altura mínima visível para qualquer valor positivo.
    final clamped = fraction <= 0 ? 0.0 : fraction.clamp(0.04, 1.0);
    return Tooltip(
      message: tooltip,
      child: FractionallySizedBox(
        alignment: Alignment.bottomCenter,
        heightFactor: clamped == 0.0 ? 0.004 : clamped,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: highlighted
                  ? [
                      AppColors.idleBall,
                      AppColors.idleBall.withValues(alpha: 0.6),
                    ]
                  : [
                      AppColors.idleBall.withValues(alpha: 0.55),
                      AppColors.idleBall.withValues(alpha: 0.25),
                    ],
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}
