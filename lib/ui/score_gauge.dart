import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Gauge semicircular 0–100 com valor central animado (one-shot ~800ms).
/// O valor numérico e o texto acompanham SEMPRE a cor (cor nunca é o único
/// indicador).
class ScoreGauge extends StatelessWidget {
  const ScoreGauge({
    super.key,
    required this.score,
    required this.color,
    this.segments,
    this.size = 200,
  });

  /// Score final (0..100).
  final int score;

  /// Cor do arco de progresso (classificação atual).
  final Color color;

  /// Cores do trilho de fundo em 5 segmentos iguais (opcional).
  final List<Color>? segments;

  final double size;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Semantics(
      label: 'Score $score de 100',
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: score.clamp(0, 100) / 100),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => SizedBox(
          width: size,
          height: size * 0.62,
          child: CustomPaint(
            painter: _GaugePainter(
              value: v,
              color: color,
              segments: segments,
              track: onSurface.withValues(alpha: 0.12),
            ),
            child: Align(
              alignment: const Alignment(0, 0.9),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(v * 100).round()}',
                    style: TextStyle(
                      fontSize: size * 0.22,
                      fontWeight: FontWeight.bold,
                      height: 1,
                      color: color,
                    ),
                  ),
                  Text(
                    '/100',
                    style: TextStyle(
                      fontSize: size * 0.07,
                      color: onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({
    required this.value,
    required this.color,
    required this.track,
    this.segments,
  });

  final double value;
  final Color color;
  final Color track;
  final List<Color>? segments;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.07;
    final center = Offset(size.width / 2, size.height * 0.94);
    final radius = size.width / 2 - stroke;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Trilho: 5 segmentos (faixas) ou trilho único.
    final segs = segments;
    if (segs != null && segs.isNotEmpty) {
      final sweep = math.pi / segs.length;
      for (var i = 0; i < segs.length; i++) {
        final paint = Paint()
          ..color = segs[i].withValues(alpha: 0.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke;
        canvas.drawArc(rect, math.pi + i * sweep, sweep * 0.96, false, paint);
      }
    } else {
      final paint = Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke;
      canvas.drawArc(rect, math.pi, math.pi, false, paint);
    }

    // Arco de progresso.
    final progress = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi, math.pi * value, false, progress);

    // Marcador na ponta do arco.
    final angle = math.pi + math.pi * value;
    final knob = center + Offset(math.cos(angle), math.sin(angle)) * radius;
    canvas.drawCircle(knob, stroke * 0.55, Paint()..color = Colors.white);
    canvas.drawCircle(knob, stroke * 0.38, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.value != value || old.color != color;
}
