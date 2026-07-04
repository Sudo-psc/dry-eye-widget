import 'package:flutter/material.dart';

/// Gráfico de linha com área em gradiente e último ponto destacado.
/// Escala fixa (minY/maxY) ou automática; grid e labels opcionais
/// (modo sparkline: showGrid=false, dateLabels=false, height baixa).
class TrendLineChart extends StatelessWidget {
  const TrendLineChart({
    super.key,
    required this.points,
    this.minY,
    this.maxY,
    this.showGrid = true,
    this.dateLabels = true,
    this.height = 160,
    this.color,
    this.formatValue,
  });

  final List<(DateTime, double)> points;
  final double? minY;
  final double? maxY;
  final bool showGrid;
  final bool dateLabels;
  final double height;
  final Color? color;

  /// Formata o valor do último ponto (default: inteiro).
  final String Function(double)? formatValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _TrendPainter(
          points: points,
          minY: minY,
          maxY: maxY,
          showGrid: showGrid,
          dateLabels: dateLabels,
          lineColor: color ?? theme.colorScheme.primary,
          axisColor: theme.colorScheme.onSurface.withValues(alpha: 0.35),
          gridColor: theme.colorScheme.onSurface.withValues(alpha: 0.10),
          formatValue: formatValue ?? (v) => v.round().toString(),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.points,
    required this.minY,
    required this.maxY,
    required this.showGrid,
    required this.dateLabels,
    required this.lineColor,
    required this.axisColor,
    required this.gridColor,
    required this.formatValue,
  });

  final List<(DateTime, double)> points;
  final double? minY;
  final double? maxY;
  final bool showGrid;
  final bool dateLabels;
  final Color lineColor;
  final Color axisColor;
  final Color gridColor;
  final String Function(double) formatValue;

  static const _leftPad = 28.0;
  static const _bottomPad = 16.0;
  static const _topPad = 14.0;

  @override
  void paint(Canvas canvas, Size size) {
    final left = showGrid ? _leftPad : 0.0;
    final bottom = dateLabels ? _bottomPad : 2.0;
    final chartW = size.width - left;
    final chartH = size.height - bottom - _topPad;
    if (chartW <= 0 || chartH <= 0) return;

    // Escala.
    var lo = minY ?? 0;
    var hi = maxY ?? 1;
    if (minY == null || maxY == null) {
      if (points.isEmpty) {
        lo = 0;
        hi = 1;
      } else {
        final values = points.map((p) => p.$2);
        lo = values.reduce((a, b) => a < b ? a : b);
        hi = values.reduce((a, b) => a > b ? a : b);
        if (hi - lo < 1e-6) {
          hi = lo + 1;
          lo = lo - 1 < 0 ? 0 : lo - 1;
        }
      }
    }

    double yFor(double v) =>
        _topPad + chartH * (1 - ((v - lo) / (hi - lo)).clamp(0.0, 1.0));

    if (showGrid) {
      final gridPaint = Paint()
        ..color = gridColor
        ..strokeWidth = 0.5;
      final style = TextStyle(color: axisColor, fontSize: 9);
      for (var i = 0; i <= 5; i++) {
        final v = lo + (hi - lo) * i / 5;
        final y = yFor(v);
        canvas.drawLine(Offset(left, y), Offset(size.width, y), gridPaint);
        final tp = TextPainter(
          text: TextSpan(text: v.round().toString(), style: style),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(0, y - tp.height / 2));
      }
    }

    if (points.isEmpty) return;

    double xFor(int i) => points.length == 1
        ? left + chartW / 2
        : left + chartW * (i / (points.length - 1));

    // Área em gradiente.
    final line = Path();
    for (var i = 0; i < points.length; i++) {
      final p = Offset(xFor(i), yFor(points[i].$2));
      if (i == 0) {
        line.moveTo(p.dx, p.dy);
      } else {
        line.lineTo(p.dx, p.dy);
      }
    }
    if (points.length > 1) {
      final area = Path.from(line)
        ..lineTo(xFor(points.length - 1), _topPad + chartH)
        ..lineTo(xFor(0), _topPad + chartH)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              lineColor.withValues(alpha: 0.28),
              lineColor.withValues(alpha: 0.0),
            ],
          ).createShader(
            Rect.fromLTWH(left, _topPad, chartW, chartH),
          ),
      );
      canvas.drawPath(
        line,
        Paint()
          ..color = lineColor
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    // Pontos + destaque do último.
    final dot = Paint()..color = lineColor;
    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(Offset(xFor(i), yFor(points[i].$2)), 2.5, dot);
    }
    final last = Offset(xFor(points.length - 1), yFor(points.last.$2));
    canvas.drawCircle(last, 5.5, Paint()..color = Colors.white);
    canvas.drawCircle(last, 4, dot);
    final valueTp = TextPainter(
      text: TextSpan(
        text: formatValue(points.last.$2),
        style: TextStyle(
          color: lineColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    valueTp.paint(
      canvas,
      Offset(
        (last.dx - valueTp.width / 2).clamp(left, size.width - valueTp.width),
        (last.dy - valueTp.height - 7).clamp(0, size.height),
      ),
    );

    if (dateLabels) {
      String fmt(DateTime d) =>
          '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
      final style = TextStyle(color: axisColor, fontSize: 9);
      final first = TextPainter(
        text: TextSpan(text: fmt(points.first.$1), style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      first.paint(canvas, Offset(left, size.height - first.height));
      if (points.length > 1) {
        final lastTp = TextPainter(
          text: TextSpan(text: fmt(points.last.$1), style: style),
          textDirection: TextDirection.ltr,
        )..layout();
        lastTp.paint(
          canvas,
          Offset(size.width - lastTp.width, size.height - lastTp.height),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) =>
      old.points != points || old.lineColor != lineColor;
}
