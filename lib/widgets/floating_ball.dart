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
    this.dynamicOrbEffect = AppDefaults.dynamicOrbEffect,
    this.hoverReactiveBall = AppDefaults.hoverReactiveBall,
    this.orbIntensity = AppDefaults.orbIntensity,
    this.blinkReminderVisible = false,
    this.blinkReminderText = '',
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
  final bool dynamicOrbEffect;
  final bool hoverReactiveBall;
  final double orbIntensity;
  final bool blinkReminderVisible;
  final String blinkReminderText;
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
    with TickerProviderStateMixin {
  late final AnimationController _blink;
  late final AnimationController _orb;
  late final AnimationController _reminder;
  late final Animation<double> _opacity;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(vsync: this, duration: widget.blinkDuration);
    _opacity = Tween<double>(
      begin: 1.0,
      end: 0.3,
    ).animate(CurvedAnimation(parent: _blink, curve: Curves.easeInOut));
    _orb = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _reminder = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _syncAnimation();
    _syncOrbAnimation();
    _syncReminderAnimation();
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
    if (oldWidget.dynamicOrbEffect != widget.dynamicOrbEffect ||
        oldWidget.orbIntensity != widget.orbIntensity ||
        oldWidget.isActive != widget.isActive) {
      _syncOrbAnimation();
    }
    if (oldWidget.blinkReminderVisible != widget.blinkReminderVisible ||
        oldWidget.isActive != widget.isActive) {
      _syncReminderAnimation();
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

  void _syncOrbAnimation() {
    final intensity = widget.orbIntensity.clamp(0.0, 1.0);
    if (widget.dynamicOrbEffect && intensity > 0) {
      _orb.duration = Duration(milliseconds: widget.isActive ? 1800 : 3200);
      _orb.repeat();
    } else {
      _orb.stop();
      _orb.value = 0;
    }
  }

  void _syncReminderAnimation() {
    if (widget.blinkReminderVisible && !widget.isActive) {
      _reminder.repeat(reverse: true);
    } else {
      _reminder.stop();
      _reminder.value = 0;
    }
  }

  @override
  void dispose() {
    _blink.dispose();
    _orb.dispose();
    _reminder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isActive ? widget.alertColor : widget.idleColor;
    final reminderVisible =
        widget.blinkReminderVisible &&
        !widget.isActive &&
        widget.blinkReminderText.trim().isNotEmpty;
    final baseOpacity = widget.isActive
        ? 1.0
        : widget.idleOpacity.clamp(0.1, 1.0);
    final ringVisible = widget.showProgress && !widget.isActive;

    final s = widget.size;
    final orbIntensity = widget.orbIntensity.clamp(0.0, 1.0);
    final hoverBoost = widget.hoverReactiveBall && _hovered ? 1.0 : 0.0;
    final effectiveOrbIntensity = widget.dynamicOrbEffect
        ? (orbIntensity + hoverBoost * 0.25).clamp(0.0, 1.0)
        : 0.0;

    Widget circle = AnimatedBuilder(
      animation: Listenable.merge([_opacity, _orb, _reminder]),
      builder: (context, _) {
        final reminderPulse = reminderVisible
            ? math.sin(_reminder.value * math.pi)
            : 0.0;
        final hoverScale = widget.hoverReactiveBall && _hovered ? 1.08 : 1.0;
        final reminderScale = 1.0 + reminderPulse * 0.05;
        final opacity = widget.isActive ? _opacity.value : baseOpacity;
        return Transform.scale(
          scale: hoverScale * reminderScale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: s,
              height: s,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.3),
                  radius: 1.0,
                  colors: [
                    Color.lerp(color, Colors.white, 0.6)!,
                    color,
                    Color.lerp(color, Colors.black, 0.4)!,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 1.0,
                ),
                boxShadow: [
                  // Sombra de profundidade (sempre, para "flutuar").
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: s * 0.22,
                    offset: Offset(0, s * 0.10),
                  ),
                  if (widget.dynamicOrbEffect)
                    BoxShadow(
                      color: const Color(
                        0xFF53D8FF,
                      ).withValues(alpha: 0.18 + effectiveOrbIntensity * 0.18),
                      blurRadius: s * (0.32 + effectiveOrbIntensity * 0.16),
                      spreadRadius: effectiveOrbIntensity * 1.5,
                    ),
                  if (widget.hoverReactiveBall && _hovered)
                    BoxShadow(
                      color: const Color(0xFF79F2D0).withValues(alpha: 0.42),
                      blurRadius: s * 0.46,
                      spreadRadius: 2.0,
                    ),
                  if (reminderVisible)
                    BoxShadow(
                      color: const Color(
                        0xFF88F7FF,
                      ).withValues(alpha: 0.22 + reminderPulse * 0.22),
                      blurRadius: s * (0.44 + reminderPulse * 0.18),
                      spreadRadius: 1.5 + reminderPulse * 1.5,
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
                  if (effectiveOrbIntensity > 0)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _DynamicOrbPainter(
                          phase: _orb.value,
                          baseColor: color,
                          intensity: effectiveOrbIntensity,
                          hovered: widget.hoverReactiveBall && _hovered,
                          isActive: widget.isActive,
                        ),
                      ),
                    ),
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
          ),
        );
      },
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
    if (reminderVisible) {
      final pillWidth = math.max(widget.size + 156, 176.0).toDouble();
      final pillHeight = math.max(widget.size + 24, 52.0).toDouble();
      visual = _BlinkReminderPill(
        width: pillWidth,
        height: pillHeight,
        color: color,
        text: widget.blinkReminderText,
        progressRingVisible: ringVisible,
        child: visual,
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      onEnter: (_) {
        if (widget.hoverReactiveBall) setState(() => _hovered = true);
      },
      onExit: (_) {
        if (widget.hoverReactiveBall) setState(() => _hovered = false);
      },
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

class _BlinkReminderPill extends StatelessWidget {
  const _BlinkReminderPill({
    required this.width,
    required this.height,
    required this.color,
    required this.text,
    required this.progressRingVisible,
    required this.child,
  });

  final double width;
  final double height;
  final Color color;
  final String text;
  final bool progressRingVisible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Align(
        alignment: Alignment.centerLeft,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF07121F).withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(color: color.withValues(alpha: 0.32), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.24),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: color.withValues(alpha: 0.22),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(progressRingVisible ? 3 : 8, 5, 14, 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                child,
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Desenha fitas luminosas internas em tons frios, inspiradas no efeito de
/// assistentes visuais, sem usar tons de rosa.
class _DynamicOrbPainter extends CustomPainter {
  _DynamicOrbPainter({
    required this.phase,
    required this.baseColor,
    required this.intensity,
    required this.hovered,
    required this.isActive,
  });

  final double phase;
  final Color baseColor;
  final double intensity;
  final bool hovered;
  final bool isActive;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final center = Offset(size.width / 2, size.height / 2);
    final bounds = Rect.fromLTWH(0, 0, size.width, size.height);
    final circle = Path()
      ..addOval(Rect.fromCircle(center: center, radius: s / 2));

    canvas.save();
    canvas.clipPath(circle);

    final glow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.25, 0.2),
        radius: 0.78,
        colors: [
          const Color(0xFF88F7FF).withValues(alpha: 0.16 * intensity),
          Color.lerp(
            baseColor,
            const Color(0xFF1EC8FF),
            0.45,
          )!.withValues(alpha: 0.10 * intensity),
          Colors.transparent,
        ],
      ).createShader(bounds);
    canvas.drawCircle(center, s * 0.48, glow);

    final spin = phase * 2 * math.pi;
    final hoverLift = hovered ? 1.25 : 1.0;
    final activeLift = isActive ? 1.18 : 1.0;
    final alpha = (0.18 + intensity * 0.28) * hoverLift * activeLift;

    _drawRibbon(
      canvas,
      size,
      angle: spin,
      colorA: const Color(0xFF5EEBFF),
      colorB: const Color(0xFF2F80FF),
      alpha: alpha.clamp(0.0, 0.72),
      width: s * (0.16 + intensity * 0.08),
      vertical: false,
    );
    _drawRibbon(
      canvas,
      size,
      angle: -spin * 0.82 + math.pi / 2.7,
      colorA: const Color(0xFFB8FFF4),
      colorB: const Color(0xFF26D59E),
      alpha: (alpha * 0.82).clamp(0.0, 0.62),
      width: s * (0.14 + intensity * 0.07),
      vertical: true,
    );
    _drawRibbon(
      canvas,
      size,
      angle: spin * 0.58 + math.pi / 1.35,
      colorA: Colors.white,
      colorB: const Color(0xFF64C8FF),
      alpha: (alpha * 0.62).clamp(0.0, 0.48),
      width: s * (0.10 + intensity * 0.05),
      vertical: false,
    );

    final core = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.32 * intensity),
          const Color(0xFF9CF7FF).withValues(alpha: 0.18 * intensity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: s * 0.28));
    canvas.drawCircle(center, s * (hovered ? 0.24 : 0.20), core);

    canvas.restore();
  }

  void _drawRibbon(
    Canvas canvas,
    Size size, {
    required double angle,
    required Color colorA,
    required Color colorB,
    required double alpha,
    required double width,
    required bool vertical,
  }) {
    final s = size.shortestSide;
    final center = Offset(size.width / 2, size.height / 2);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.translate(-center.dx, -center.dy);

    final start = vertical
        ? Offset(center.dx - s * 0.06, center.dy - s * 0.58)
        : Offset(center.dx - s * 0.58, center.dy + s * 0.10);
    final end = vertical
        ? Offset(center.dx + s * 0.10, center.dy + s * 0.58)
        : Offset(center.dx + s * 0.58, center.dy - s * 0.04);
    final c1 = vertical
        ? Offset(center.dx + s * 0.46, center.dy - s * 0.22)
        : Offset(center.dx - s * 0.22, center.dy - s * 0.44);
    final c2 = vertical
        ? Offset(center.dx - s * 0.42, center.dy + s * 0.16)
        : Offset(center.dx + s * 0.28, center.dy + s * 0.42);

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = width
      ..blendMode = BlendMode.screen
      ..shader = LinearGradient(
        colors: [
          colorA.withValues(alpha: alpha),
          Colors.white.withValues(alpha: alpha * 0.72),
          colorB.withValues(alpha: alpha),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DynamicOrbPainter old) =>
      old.phase != phase ||
      old.baseColor != baseColor ||
      old.intensity != intensity ||
      old.hovered != hovered ||
      old.isActive != isActive;
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

    // Borda escura suave para visibilidade em fundos brancos (Sombra / Contorno)
    final shadowTrack = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 1.5;
    canvas.drawCircle(center, radius, shadowTrack);

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
