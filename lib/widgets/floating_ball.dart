import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// A bolinha flutuante.
///
/// Visualmente: cor IDLE (estática) e cor de alerta piscando quando ativa.
/// Tamanho, cores, opacidade no IDLE e velocidade do piscar são configuráveis.
/// Quando [showProgress] está ativo (e a bolinha não está em alerta), desenha
/// um anel branco ao redor que se preenche em sentido horário conforme
/// [progress] (0.0–1.0) avança até a próxima pausa.
class FloatingBall extends StatefulWidget {
  const FloatingBall({
    super.key,
    required this.isActive,
    this.size = AppDefaults.ballSize,
    this.idleColor = AppColors.idleBall,
    this.alertColor = AppColors.alertBall,
    this.idleOpacity = 1.0,
    this.blinkDuration = const Duration(milliseconds: AppDefaults.blinkMs),
    this.showProgress = false,
    this.progress = 0.0,
    this.dimmed = false,
    this.onTap,
    this.onSecondaryTap,
    this.onDragStart,
    this.onDragEnd,
  });

  final bool isActive;
  final double size;
  final Color idleColor;
  final Color alertColor;
  final double idleOpacity;
  final Duration blinkDuration;
  final bool showProgress;
  final double progress;

  /// Esmaece a bolinha (ex.: quando o ciclo está pausado por inatividade).
  /// Só tem efeito no estado IDLE.
  final bool dimmed;
  final VoidCallback? onTap;
  final VoidCallback? onSecondaryTap;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;

  /// Espessura do anel de progresso e folga ao redor da bolinha.
  static const double ringStroke = 3.0;
  static const double ringGap = 4.0;

  @override
  State<FloatingBall> createState() => _FloatingBallState();
}

class _FloatingBallState extends State<FloatingBall>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(vsync: this, duration: widget.blinkDuration);
    _opacity = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(parent: _blink, curve: Curves.easeInOut),
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant FloatingBall oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.blinkDuration != widget.blinkDuration) {
      _blink.duration = widget.blinkDuration;
      if (widget.isActive) _blink.repeat(reverse: true);
    }
    if (oldWidget.isActive != widget.isActive) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    if (widget.isActive) {
      _blink.repeat(reverse: true);
    } else {
      _blink.stop();
      _blink.value = 0;
    }
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isActive ? widget.alertColor : widget.idleColor;
    var baseOpacity =
        widget.isActive ? 1.0 : widget.idleOpacity.clamp(0.1, 1.0);
    if (widget.dimmed && !widget.isActive) baseOpacity *= 0.5;
    final ringVisible = widget.showProgress && !widget.isActive;

    // Tons derivados da cor base para o relevo 3D.
    final light = Color.lerp(color, Colors.white, 0.55)!;
    final dark = Color.lerp(color, Colors.black, 0.32)!;
    final s = widget.size;

    Widget circle = AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) {
        return Opacity(
          opacity: widget.isActive ? _opacity.value : baseOpacity,
          child: child,
        );
      },
      child: Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Gradiente radial com luz no topo-esquerdo → esfera 3D.
          gradient: RadialGradient(
            center: const Alignment(-0.35, -0.4),
            radius: 0.95,
            colors: [light, color, dark],
            stops: const [0.0, 0.5, 1.0],
          ),
          boxShadow: [
            // Sombra de profundidade (sempre, para "flutuar").
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: s * 0.22,
              offset: Offset(0, s * 0.10),
            ),
            // Brilho colorido quando em alerta.
            if (widget.isActive)
              BoxShadow(
                color: color.withValues(alpha: 0.6),
                blurRadius: 14,
                spreadRadius: 2,
              ),
          ],
        ),
        // Reflexo especular (brilho de vidro) no topo-esquerdo.
        child: Stack(
          children: [
            Positioned(
              left: s * 0.16,
              top: s * 0.12,
              child: Container(
                width: s * 0.34,
                height: s * 0.34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.7),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Widget visual = circle;
    if (ringVisible) {
      final ringSize =
          widget.size + (FloatingBall.ringGap + FloatingBall.ringStroke) * 2;
      visual = SizedBox(
        width: ringSize,
        height: ringSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size.square(ringSize),
              painter: _ProgressRingPainter(
                progress: widget.progress.clamp(0.0, 1.0),
                strokeWidth: FloatingBall.ringStroke,
              ),
            ),
            circle,
          ],
        ),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onSecondaryTap: widget.onSecondaryTap,
        onPanStart: (_) => widget.onDragStart?.call(),
        onPanEnd: (_) => widget.onDragEnd?.call(),
        child: visual,
      ),
    );
  }
}

/// Desenha o arco de progresso (branco) na borda externa da bolinha,
/// começando no topo (12h) e crescendo em sentido horário.
class _ProgressRingPainter extends CustomPainter {
  _ProgressRingPainter({required this.progress, required this.strokeWidth});

  final double progress;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Trilho de fundo sutil (círculo completo).
    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;

    // Arco de progresso: -pi/2 = topo; sweep positivo = sentido horário.
    final arc = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, arc);
  }

  @override
  bool shouldRepaint(_ProgressRingPainter old) =>
      old.progress != progress || old.strokeWidth != strokeWidth;
}
