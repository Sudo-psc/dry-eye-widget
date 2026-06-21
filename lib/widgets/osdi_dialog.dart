import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/osdi_assessment.dart';
import '../utils/constants.dart';
import 'liquid_glass.dart';

class OsdiDialog extends StatefulWidget {
  const OsdiDialog({
    super.key,
    required this.strings,
    required this.history,
    required this.onSave,
    required this.onClose,
  });

  final AppStrings strings;
  final List<OsdiAssessment> history;
  final ValueChanged<OsdiAssessment> onSave;
  final VoidCallback onClose;

  @override
  State<OsdiDialog> createState() => _OsdiDialogState();
}

class _OsdiDialogState extends State<OsdiDialog> {
  late List<int?> _answers;
  OsdiAssessment? _lastSaved;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _answers = List<int?>.filled(OsdiAssessment.questionCount, null);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  OsdiAssessment? get _preview {
    try {
      return OsdiAssessment.fromAnswers(_answers);
    } catch (_) {
      return null;
    }
  }

  List<OsdiAssessment> get _effectiveHistory {
    final saved = _lastSaved;
    if (saved == null) return widget.history;
    return [...widget.history, saved]
      ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
  }

  void _setAnswer(int questionIndex, int? value) {
    setState(() => _answers[questionIndex] = value);
  }

  void _resetAnswers() {
    setState(() {
      _answers = List<int?>.filled(OsdiAssessment.questionCount, null);
      _lastSaved = null;
    });
  }

  void _save() {
    final assessment = _preview;
    if (assessment == null) return;
    widget.onSave(assessment);
    setState(() {
      _lastSaved = assessment;
      _answers = List<int?>.filled(OsdiAssessment.questionCount, null);
    });
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final preview = _preview;
    final history = _effectiveHistory;
    final display =
        preview ?? _lastSaved ?? (history.isEmpty ? null : history.last);
    final previous = _previousFor(display, history);

    return LiquidGlass(
      width: 640,
      constraints: const BoxConstraints(maxHeight: 750),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(s),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ScoreSummary(
                    strings: s,
                    assessment: display,
                    previous: previous,
                  ),
                  const SizedBox(height: 14),
                  _HistoryPanel(strings: s, history: history),
                  const SizedBox(height: 14),
                  Text(
                    s.osdiInstruction,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ScaleLegend(strings: s),
                  const SizedBox(height: 8),
                  for (var i = 0; i < s.osdiQuestions.length; i++)
                    _QuestionBlock(
                      index: i,
                      question: s.osdiQuestions[i],
                      answerLabels: s.osdiAnswerLabels,
                      notApplicableLabel: s.osdiNotApplicable,
                      selected: _answers[i],
                      onChanged: (value) => _setAnswer(i, value),
                    ),
                ],
              ),
            ),
          ),
          const Divider(color: AppColors.glassBorder, height: 20),
          _buildFooter(s, preview),
        ],
      ),
    );
  }

  Widget _buildHeader(AppStrings s) {
    return Row(
      children: [
        const Icon(
          Icons.assignment_outlined,
          color: AppColors.idleBall,
          size: 24,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.osdiTitle,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                s.osdiSubtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: s.close,
          onPressed: widget.onClose,
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildFooter(AppStrings s, OsdiAssessment? preview) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          s.osdiDisclaimer,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11.5,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 6,
          children: [
            TextButton(onPressed: _resetAnswers, child: Text(s.osdiReset)),
            FilledButton.icon(
              onPressed: preview == null ? null : _save,
              icon: const Icon(Icons.save_outlined, size: 18),
              label: Text(s.osdiSave),
            ),
          ],
        ),
      ],
    );
  }

  OsdiAssessment? _previousFor(
    OsdiAssessment? display,
    List<OsdiAssessment> history,
  ) {
    if (display == null || history.length < 2) return null;
    final index = history.lastIndexWhere(
      (item) => item.completedAt == display.completedAt,
    );
    if (index > 0) return history[index - 1];
    if (index == -1) return history.last;
    return null;
  }
}

class _ScaleLegend extends StatelessWidget {
  const _ScaleLegend({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (var i = 0; i < strings.osdiAnswerLabels.length; i++)
          Text(
            '$i ${strings.osdiAnswerLabels[i]}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}

class _ScoreSummary extends StatelessWidget {
  const _ScoreSummary({
    required this.strings,
    required this.assessment,
    required this.previous,
  });

  final AppStrings strings;
  final OsdiAssessment? assessment;
  final OsdiAssessment? previous;

  @override
  Widget build(BuildContext context) {
    final current = assessment;
    if (current == null) {
      return _SoftPanel(
        child: Row(
          children: [
            const Icon(
              Icons.insights_outlined,
              color: AppColors.idleBall,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                strings.osdiNoHistory,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final severity = _severityLabel(strings, current.severity);
    final severityColor = _severityColor(current.severity);
    final score = _formatScore(current.score);
    return _SoftPanel(
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: severityColor.withValues(alpha: 0.16),
              border: Border.all(color: severityColor.withValues(alpha: 0.7)),
            ),
            child: Text(
              score,
              style: TextStyle(
                color: severityColor,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.osdiScoreLabel.replaceAll('{score}', score),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$severity · ${strings.osdiAnsweredLabel.replaceAll('{count}', current.answeredCount.toString())}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
                if (previous != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _trendLabel(strings, current.score - previous!.score),
                    style: const TextStyle(
                      color: AppColors.idleBall,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({required this.strings, required this.history});

  final AppStrings strings;
  final List<OsdiAssessment> history;

  @override
  Widget build(BuildContext context) {
    final recent = history.length <= 8
        ? history
        : history.sublist(history.length - 8);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.show_chart, color: AppColors.idleBall, size: 18),
            const SizedBox(width: 8),
            Text(
              strings.osdiHistoryTitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _SoftPanel(
          child: SizedBox(
            height: 118,
            width: double.infinity,
            child: recent.isEmpty
                ? Center(
                    child: Text(
                      strings.osdiNoHistory,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  )
                : CustomPaint(painter: _OsdiChartPainter(recent)),
          ),
        ),
      ],
    );
  }
}

class _QuestionBlock extends StatelessWidget {
  const _QuestionBlock({
    required this.index,
    required this.question,
    required this.answerLabels,
    required this.notApplicableLabel,
    required this.selected,
    required this.onChanged,
  });

  final int index;
  final String question;
  final List<String> answerLabels;
  final String notApplicableLabel;
  final int? selected;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${index + 1}. $question',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var value = 0; value < answerLabels.length; value++)
                ChoiceChip(
                  key: ValueKey('osdi-q$index-option-$value'),
                  tooltip: answerLabels[value],
                  label: Text(value.toString()),
                  selected: selected == value,
                  showCheckmark: false,
                  selectedColor: AppColors.idleBall.withValues(alpha: 0.75),
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  side: BorderSide(
                    color: selected == value
                        ? AppColors.idleBall
                        : Colors.white.withValues(alpha: 0.12),
                  ),
                  labelStyle: TextStyle(
                    color: selected == value
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: selected == value
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                  onSelected: (_) => onChanged(value),
                ),
              ChoiceChip(
                key: ValueKey('osdi-q$index-option-na'),
                label: Text(notApplicableLabel),
                selected: selected == null,
                showCheckmark: false,
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                selectedColor: Colors.white.withValues(alpha: 0.12),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                labelStyle: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                ),
                onSelected: (_) => onChanged(null),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SoftPanel extends StatelessWidget {
  const _SoftPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: child,
    );
  }
}

class _OsdiChartPainter extends CustomPainter {
  _OsdiChartPainter(this.history);

  final List<OsdiAssessment> history;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..color = AppColors.idleBall
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fillPaint = Paint()
      ..color = AppColors.idleBall.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;

    const left = 28.0;
    const right = 8.0;
    const top = 8.0;
    const bottom = 22.0;
    final chart = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );

    for (final threshold in const [12.0, 22.0, 32.0, 100.0]) {
      final y = _y(chart, threshold);
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
    }

    final points = <Offset>[];
    for (var i = 0; i < history.length; i++) {
      final x = history.length == 1
          ? chart.center.dx
          : chart.left + chart.width * i / math.max(1, history.length - 1);
      points.add(Offset(x, _y(chart, history[i].score)));
    }

    if (points.length > 1) {
      final fillPath = Path()
        ..moveTo(points.first.dx, chart.bottom)
        ..lineTo(points.first.dx, points.first.dy);
      final linePath = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        linePath.lineTo(point.dx, point.dy);
        fillPath.lineTo(point.dx, point.dy);
      }
      fillPath
        ..lineTo(points.last.dx, chart.bottom)
        ..close();
      canvas.drawPath(fillPath, fillPaint);
      canvas.drawPath(linePath, linePaint);
    }

    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final severity = history[i].severity;
      final pointPaint = Paint()
        ..color = _severityColor(severity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(point, 4.5, pointPaint);
      canvas.drawCircle(
        point,
        4.5,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    _label(canvas, '0', Offset(4, chart.bottom - 7));
    _label(canvas, '100', Offset(0, chart.top - 2));
    if (history.isNotEmpty) {
      _label(
        canvas,
        _shortDate(history.first.completedAt),
        Offset(chart.left, chart.bottom + 5),
      );
      _label(
        canvas,
        _shortDate(history.last.completedAt),
        Offset(math.max(chart.left, chart.right - 42), chart.bottom + 5),
      );
    }
  }

  double _y(Rect chart, double score) =>
      chart.bottom - chart.height * score.clamp(0, 100) / 100;

  void _label(Canvas canvas, String text, Offset offset) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.58),
          fontSize: 10,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  String _shortDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';

  @override
  bool shouldRepaint(covariant _OsdiChartPainter oldDelegate) =>
      oldDelegate.history != history;
}

String _formatScore(double score) {
  final rounded = score.roundToDouble();
  if ((score - rounded).abs() < 0.05) return rounded.toInt().toString();
  return score.toStringAsFixed(1);
}

String _severityLabel(AppStrings strings, OsdiSeverity severity) {
  switch (severity) {
    case OsdiSeverity.normal:
      return strings.osdiSeverityNormal;
    case OsdiSeverity.mild:
      return strings.osdiSeverityMild;
    case OsdiSeverity.moderate:
      return strings.osdiSeverityModerate;
    case OsdiSeverity.severe:
      return strings.osdiSeveritySevere;
  }
}

Color _severityColor(OsdiSeverity severity) {
  switch (severity) {
    case OsdiSeverity.normal:
      return const Color(0xFF50C878);
    case OsdiSeverity.mild:
      return AppColors.idleBall;
    case OsdiSeverity.moderate:
      return const Color(0xFFFFC857);
    case OsdiSeverity.severe:
      return AppColors.alertBall;
  }
}

String _trendLabel(AppStrings strings, double delta) {
  if (delta.abs() < 0.5) return strings.osdiTrendSame;
  final amount = _formatScore(delta.abs());
  if (delta < 0) {
    return strings.osdiTrendBetter.replaceAll('{delta}', amount);
  }
  return strings.osdiTrendWorse.replaceAll('{delta}', amount);
}
