import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// Anel de progresso animado (0→[value] em 800ms, one-shot).
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 56,
    this.strokeWidth = 6,
    this.color,
    this.child,
  });

  /// Progresso 0..1.
  final double value;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final ringColor = color ?? Theme.of(context).colorScheme.primary;
    const track = AppColorTokens.progressTrack;
    final normalized = value.clamp(0.0, 1.0);
    return Semantics(
      label: 'Progresso',
      value: '${(normalized * 100).round()}%',
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: normalized),
        duration: AppMotion.resolve(context, AppMotion.normal),
        curve: AppMotion.standard,
        builder: (context, v, _) => CustomPaint(
          size: Size.square(size),
          painter: _RingPainter(
            value: v,
            color: ringColor,
            track: track,
            strokeWidth: strokeWidth,
          ),
          child: SizedBox.square(
            dimension: size,
            child: child == null ? null : Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.value,
    required this.color,
    required this.track,
    required this.strokeWidth,
  });

  final double value;
  final Color color;
  final Color track;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inset = strokeWidth / 2;
    final arcRect = rect.deflate(inset);
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(arcRect, 0, math.pi * 2, false, trackPaint);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arcRect, -math.pi / 2, math.pi * 2 * value, false, paint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.value != value || old.color != color;
}
