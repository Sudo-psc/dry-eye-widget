import 'package:flutter/material.dart';

/// Círculo de "respiração": expande e contrai suavemente (~4s por ciclo)
/// para guiar piscadas/respiração durante a pausa. Use APENAS em estados
/// de pausa — o loop roda enquanto o widget estiver montado.
class BreathingCircle extends StatefulWidget {
  const BreathingCircle({super.key, this.size = 150, this.color = Colors.white});

  final double size;
  final Color color;

  @override
  State<BreathingCircle> createState() => _BreathingCircleState();
}

class _BreathingCircleState extends State<BreathingCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat(reverse: true);

  late final Animation<double> _scale = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  ).drive(Tween(begin: 0.82, end: 1.12));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: 0.08),
            border: Border.all(color: widget.color.withValues(alpha: 0.22)),
          ),
        ),
      ),
    );
  }
}
