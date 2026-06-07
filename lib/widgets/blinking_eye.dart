import 'package:flutter/material.dart';

/// Olho estilizado que pisca de tempos em tempos. Exibido durante a pausa,
/// reforçando o lembrete de piscar enquanto se olha para longe.
class BlinkingEye extends StatefulWidget {
  const BlinkingEye({
    super.key,
    this.size = 88,
    this.color = Colors.white,
    this.irisColor = const Color(0xFF4A90E2),
  });

  final double size;
  final Color color;
  final Color irisColor;

  @override
  State<BlinkingEye> createState() => _BlinkingEyeState();
}

class _BlinkingEyeState extends State<BlinkingEye>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Abertura vertical do olho (1 = aberto, ~0.08 = fechado durante a piscada).
  double _openFor(double t) {
    if (t <= 0.9) return 1.0;
    final b = (t - 0.9) / 0.1; // 0..1 na janela da piscada
    final tri = b < 0.5 ? 1 - b / 0.5 : (b - 0.5) / 0.5;
    return tri.clamp(0.08, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final open = _openFor(_c.value);
        return SizedBox(
          width: widget.size,
          height: widget.size * 0.62,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(1, open, 1),
            child: CustomPaint(
              painter: _EyePainter(
                color: widget.color,
                irisColor: widget.irisColor,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EyePainter extends CustomPainter {
  _EyePainter({required this.color, required this.irisColor});

  final Color color;
  final Color irisColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cy = h / 2;
    final stroke = w * 0.045;

    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final halfW = w * 0.46;
    final halfH = h * 0.42;
    final left = Offset(w / 2 - halfW, cy);
    final right = Offset(w / 2 + halfW, cy);
    final eye = Path()
      ..moveTo(left.dx, left.dy)
      ..quadraticBezierTo(w / 2, cy - halfH, right.dx, right.dy)
      ..quadraticBezierTo(w / 2, cy + halfH, left.dx, left.dy);
    canvas.drawPath(eye, line);

    // Íris + pupila.
    final irisR = h * 0.26;
    canvas.drawCircle(Offset(w / 2, cy), irisR,
        Paint()..color = irisColor.withValues(alpha: 0.9));
    canvas.drawCircle(Offset(w / 2, cy), irisR, line..strokeWidth = stroke);
    canvas.drawCircle(
        Offset(w / 2, cy), irisR * 0.42, Paint()..color = color);
    // Brilho.
    canvas.drawCircle(
      Offset(w / 2 - irisR * 0.35, cy - irisR * 0.35),
      irisR * 0.18,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(_EyePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.irisColor != irisColor;
}
