import 'package:flutter/material.dart';

/// Frasco de colírio que pinga uma gota, em loop. Usado no lembrete de colírio.
class DropperAnimation extends StatefulWidget {
  const DropperAnimation({
    super.key,
    this.size = 96,
    this.bottleColor = const Color(0xFF4A90E2),
    this.dropColor = const Color(0xFF6FB1FF),
  });

  final double size;
  final Color bottleColor;
  final Color dropColor;

  @override
  State<DropperAnimation> createState() => _DropperAnimationState();
}

class _DropperAnimationState extends State<DropperAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _DropperPainter(
            t: _c.value,
            bottleColor: widget.bottleColor,
            dropColor: widget.dropColor,
          ),
        ),
      ),
    );
  }
}

class _DropperPainter extends CustomPainter {
  _DropperPainter({
    required this.t,
    required this.bottleColor,
    required this.dropColor,
  });

  final double t;
  final Color bottleColor;
  final Color dropColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // Corpo do frasco (parte superior).
    final bodyW = w * 0.42;
    final bodyH = h * 0.40;
    final bodyLeft = (w - bodyW) / 2;
    final bodyTop = h * 0.05;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(bodyLeft, bodyTop, bodyW, bodyH),
      Radius.circular(w * 0.06),
    );
    canvas.drawRRect(
      body,
      Paint()..color = bottleColor.withValues(alpha: 0.9),
    );
    // Tampa.
    final capW = bodyW * 0.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH((w - capW) / 2, bodyTop - h * 0.05, capW, h * 0.06),
        Radius.circular(w * 0.02),
      ),
      Paint()..color = bottleColor,
    );
    // Bico conta-gotas (triângulo afunilando para baixo).
    final nozzleTop = bodyTop + bodyH;
    final nozzleTipY = nozzleTop + h * 0.10;
    final nozzle = Path()
      ..moveTo(w / 2 - bodyW * 0.18, nozzleTop)
      ..lineTo(w / 2 + bodyW * 0.18, nozzleTop)
      ..lineTo(w / 2 + bodyW * 0.05, nozzleTipY)
      ..lineTo(w / 2 - bodyW * 0.05, nozzleTipY)
      ..close();
    canvas.drawPath(nozzle, Paint()..color = bottleColor.withValues(alpha: 0.85));

    // Brilho no corpo.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bodyLeft + bodyW * 0.16, bodyTop + bodyH * 0.12,
            bodyW * 0.16, bodyH * 0.6),
        Radius.circular(w * 0.03),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.25),
    );

    // Gota: forma e cai ciclicamente.
    final floorY = h * 0.92;
    final fall = t.clamp(0.0, 1.0);
    final dropY = nozzleTipY + (floorY - nozzleTipY) * Curves.easeIn.transform(fall);
    final dropR = w * 0.06 * (0.6 + 0.4 * (1 - fall));
    final dropOpacity = fall < 0.85 ? 1.0 : (1 - (fall - 0.85) / 0.15);
    _drawDrop(canvas, Offset(w / 2, dropY), dropR,
        dropColor.withValues(alpha: dropOpacity.clamp(0.0, 1.0)));

    // Pequena poça/onda ao tocar o chão (final do ciclo).
    if (fall > 0.8) {
      final spread = (fall - 0.8) / 0.2;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(w / 2, floorY + h * 0.02),
          width: w * 0.30 * spread,
          height: h * 0.05 * spread,
        ),
        Paint()
          ..color = dropColor.withValues(alpha: (1 - spread) * 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.012,
      );
    }
  }

  /// Desenha uma gota (círculo com ponta superior).
  void _drawDrop(Canvas canvas, Offset center, double r, Color color) {
    final path = Path()
      ..moveTo(center.dx, center.dy - r * 1.8)
      ..quadraticBezierTo(
          center.dx + r, center.dy - r * 0.4, center.dx + r, center.dy)
      ..arcToPoint(Offset(center.dx - r, center.dy),
          radius: Radius.circular(r), clockwise: false)
      ..quadraticBezierTo(
          center.dx - r, center.dy - r * 0.4, center.dx, center.dy - r * 1.8)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawCircle(
      Offset(center.dx - r * 0.3, center.dy - r * 0.2),
      r * 0.25,
      Paint()..color = Colors.white.withValues(alpha: 0.6 * (color.a)),
    );
  }

  @override
  bool shouldRepaint(_DropperPainter oldDelegate) => oldDelegate.t != t;
}
