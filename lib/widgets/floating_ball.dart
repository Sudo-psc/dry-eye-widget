import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/constants.dart';
import '../utils/edge_snap.dart';

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
    this.dockEdge,
    this.semanticLabel,
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

  /// Quando definido, a bolinha está encaixada nessa borda (modo meia-lua):
  /// mais translúcida e sem anel de progresso (discreta).
  final BallDockEdge? dockEdge;
  final String? semanticLabel;
  final VoidCallback? onTap;
  final VoidCallback? onSecondaryTap;
  final VoidCallback? onDragStart;
  final ValueChanged<Offset>? onDragEnd;

  /// Espessura e folga adaptativas: o anel permanece delicado no tamanho
  /// padrão, mas ganha presença suficiente em bolas maiores sem parecer pesado.
  static double ringStrokeForSize(double size) =>
      (size * 0.072).clamp(2.4, 4.4).toDouble();

  static double ringGapForSize(double size) =>
      (size * 0.09).clamp(3.0, 5.0).toDouble();

  static const double ringAnimationThreshold = 0.9;
  static const int idleOrbPhaseSteps = 32;
  static const int activeOrbPhaseSteps = 30;
  static const int ringPhaseSteps = 52;

  /// Reduz notificações visuais contínuas sem alterar a duração do movimento.
  static double quantizedPhase(double value, int steps) {
    final normalized = value.clamp(0.0, 1.0);
    return (normalized * steps).floor() / steps;
  }

  static bool shouldAnimateRing(double progress) =>
      progress.clamp(0.0, 1.0) >= ringAnimationThreshold;

  /// Filtro de movimento do material interno. Limita energia e absorve
  /// inversões bruscas para a íris acompanhar a mão sem vibrar.
  static Offset smoothMotionVector(
    Offset current,
    Offset sample, {
    double response = 0.22,
    double maxMagnitude = 0.82,
  }) {
    if (!sample.dx.isFinite || !sample.dy.isFinite) return current;
    final limit = maxMagnitude.clamp(0.0, 1.0).toDouble();
    final distance = sample.distance;
    final limited = distance > limit && distance > 0
        ? sample * (limit / distance)
        : sample;
    return Offset.lerp(current, limited, response.clamp(0.0, 1.0))!;
  }

  @override
  State<FloatingBall> createState() => _FloatingBallState();
}

class _FloatingBallState extends State<FloatingBall>
    with TickerProviderStateMixin {
  late final AnimationController _blink;
  late final AnimationController _hover;
  late final AnimationController _reminder;
  late final AnimationController _reminderBurst;
  late final AnimationController _press;
  late final AnimationController _release;
  late final AnimationController _ring;
  late final Animation<double> _opacity;
  late final ValueNotifier<double> _orbFrame;
  late final ValueNotifier<double> _ringFrame;
  Timer? _orbTimer;
  Duration? _orbTick;
  double _orbPhase = 0;
  bool _reduceMotion = false;
  bool _pressed = false;
  bool _dragging = false;
  Offset _dragVector = Offset.zero;
  Offset _releaseVector = Offset.zero;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(vsync: this, duration: widget.blinkDuration);
    _opacity = Tween<double>(
      begin: 1.0,
      end: 0.3,
    ).animate(CurvedAnimation(parent: _blink, curve: Curves.easeInOut));
    _orbFrame = ValueNotifier(0);
    _hover = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 260),
    );
    _reminder = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    // Burst one-shot disparado quando o aviso de piscada é emitido: a bolinha
    // brilha/clareia e ganha opacidade por um instante, depois volta ao normal.
    _reminderBurst = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _release = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    _ring = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _ringFrame = ValueNotifier(0);
    _ring.addListener(_updateRingFrame);
    _syncAnimation();
    _syncOrbAnimation();
    _syncReminderAnimation();
    _syncRingAnimation();
    if (widget.blinkReminderVisible && !widget.isActive) {
      _reminderBurst.forward(from: 0);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations == true;
    if (reduce != _reduceMotion) {
      _reduceMotion = reduce;
      _syncOrbAnimation();
      _syncRingAnimation();
    }
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
    if (!widget.hoverReactiveBall && _hover.value > 0) {
      _hover.reverse();
    }
    if (oldWidget.blinkReminderVisible != widget.blinkReminderVisible ||
        oldWidget.isActive != widget.isActive) {
      _syncReminderAnimation();
      if (!oldWidget.blinkReminderVisible &&
          widget.blinkReminderVisible &&
          !widget.isActive) {
        _reminderBurst.forward(from: 0);
      }
    }
    if (oldWidget.showProgress != widget.showProgress ||
        oldWidget.isActive != widget.isActive ||
        oldWidget.dockEdge != widget.dockEdge ||
        FloatingBall.shouldAnimateRing(oldWidget.progress) !=
            FloatingBall.shouldAnimateRing(widget.progress)) {
      _syncRingAnimation();
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
    if (widget.dynamicOrbEffect && intensity > 0 && !_reduceMotion) {
      final durationMs = widget.isActive ? 1800 : 3200;
      final steps = widget.isActive
          ? FloatingBall.activeOrbPhaseSteps
          : FloatingBall.idleOrbPhaseSteps;
      final tick = Duration(milliseconds: (durationMs / steps).round());
      if (_orbTimer != null && _orbTick == tick) return;
      _orbTimer?.cancel();
      _orbTick = tick;
      _orbTimer = Timer.periodic(tick, (_) {
        if (!mounted) return;
        _orbPhase = (_orbPhase + tick.inMilliseconds / durationMs) % 1.0;
        final next = FloatingBall.quantizedPhase(_orbPhase, steps);
        if (_orbFrame.value != next) _orbFrame.value = next;
      });
    } else {
      _orbTimer?.cancel();
      _orbTimer = null;
      _orbTick = null;
      _orbPhase = 0;
      if (_orbFrame.value != 0) _orbFrame.value = 0;
    }
  }

  void _updateRingFrame() {
    final next = FloatingBall.quantizedPhase(
      _ring.value,
      FloatingBall.ringPhaseSteps,
    );
    if (_ringFrame.value != next) _ringFrame.value = next;
  }

  void _syncRingAnimation() {
    final visible =
        widget.showProgress && !widget.isActive && widget.dockEdge == null;
    if (visible &&
        !_reduceMotion &&
        FloatingBall.shouldAnimateRing(widget.progress)) {
      if (!_ring.isAnimating) _ring.repeat();
    } else {
      _ring.stop();
      _ring.value = 0;
    }
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
    if (value) {
      _release.stop();
      _press.forward();
    } else {
      _press.reverse();
    }
  }

  void _handlePanStart(DragStartDetails details) {
    setState(() {
      _dragging = true;
      _dragVector = Offset.zero;
    });
    _setPressed(true);
    widget.onDragStart?.call();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final delta = details.delta;
    if (delta == Offset.zero) return;
    final energy = (delta.distance / 14).clamp(0.04, 0.82).toDouble();
    final direction = delta / delta.distance;
    setState(() {
      _dragVector = FloatingBall.smoothMotionVector(
        _dragVector,
        direction * energy,
      );
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond;
    final speed = velocity.distance;
    final direction = speed == 0 ? _dragVector : velocity / speed;
    final energy = (speed / 1500).clamp(0.0, 1.0).toDouble();
    final releaseTarget = direction * energy;
    setState(() {
      _dragging = false;
      _releaseVector = FloatingBall.smoothMotionVector(
        _dragVector,
        releaseTarget,
        response: 0.52,
        maxMagnitude: 0.88,
      );
      _dragVector = Offset.zero;
    });
    _setPressed(false);
    if (!_reduceMotion && energy > 0.02) {
      _release.forward(from: 0);
    } else {
      _release.value = 1;
    }
    widget.onDragEnd?.call(velocity);
  }

  void _handlePanCancel() {
    setState(() {
      _dragging = false;
      _dragVector = Offset.zero;
      _releaseVector = Offset.zero;
    });
    _setPressed(false);
    widget.onDragEnd?.call(Offset.zero);
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
    _orbTimer?.cancel();
    _hover.dispose();
    _reminder.dispose();
    _reminderBurst.dispose();
    _press.dispose();
    _release.dispose();
    _ring.removeListener(_updateRingFrame);
    _ring.dispose();
    _orbFrame.dispose();
    _ringFrame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isActive ? widget.alertColor : widget.idleColor;
    final docked = widget.dockEdge != null && !widget.isActive;
    final reminderVisible =
        widget.blinkReminderVisible &&
        !widget.isActive &&
        !docked &&
        widget.blinkReminderText.trim().isNotEmpty;
    final baseOpacity = widget.isActive
        ? 1.0
        : (docked
              ? (widget.idleOpacity.clamp(0.2, 1.0) * 0.72).clamp(0.28, 0.76)
              : widget.idleOpacity.clamp(0.2, 1.0));
    final ringVisible = widget.showProgress && !widget.isActive && !docked;

    final s = widget.size;
    final orbIntensity = widget.orbIntensity.clamp(0.0, 1.0);
    final hoverBoost = widget.hoverReactiveBall ? _hover.value : 0.0;
    final effectiveOrbIntensity = widget.dynamicOrbEffect
        ? (orbIntensity + hoverBoost * 0.28).clamp(0.0, 1.0)
        : 0.0;

    Widget circle = AnimatedBuilder(
      animation: Listenable.merge([
        _opacity,
        _orbFrame,
        _hover,
        _reminder,
        _reminderBurst,
        _press,
        _release,
      ]),
      builder: (context, _) {
        final orbPhase = _orbFrame.value;
        final reminderPulse = reminderVisible
            ? math.sin(_reminder.value * math.pi)
            : 0.0;
        // Burst: sobe e desce em ~700ms (sin 0->1->0) no instante do aviso.
        final burst = widget.blinkReminderVisible && !widget.isActive
            ? math.sin(_reminderBurst.value * math.pi)
            : 0.0;
        final effColor = Color.lerp(
          color,
          const Color(0xFF9BE8FF),
          burst * 0.45,
        )!;
        final hovered = widget.hoverReactiveBall && _hover.value > 0.01;
        final hoverEase = Curves.easeOutCubic.transform(_hover.value);
        final pressEase = Curves.easeOutCubic.transform(_press.value);
        final releaseWave = _reduceMotion || _release.value >= 1
            ? 0.0
            : math.sin(_release.value * math.pi) *
                  math.exp(-_release.value * 2.8);
        final motion = _dragging ? _dragVector : _releaseVector * releaseWave;
        final motionStrength = motion.distance.clamp(0.0, 1.0);
        final motionAngle = motionStrength > 0.001
            ? math.atan2(motion.dy, motion.dx)
            : 0.0;
        final stretch = _reduceMotion ? 0.0 : motionStrength;
        final scaleX = 1.0 + stretch * 0.10 + pressEase * 0.028;
        final scaleY = 1.0 - stretch * 0.045 - pressEase * 0.045;
        final hoverScale = 1.0 + hoverEase * (docked ? 0.13 : 0.11);
        final reminderScale = 1.0 + reminderPulse * 0.08 + burst * 0.14;
        final dockScale = docked ? 0.96 : 1.0;
        final liveScale = widget.dynamicOrbEffect && !widget.isActive
            ? 1.0 + math.sin(orbPhase * math.pi * 2) * 0.012
            : 1.0;
        final opacity = widget.isActive
            ? _opacity.value
            : (baseOpacity + (1.0 - baseOpacity) * burst);
        final transform = Matrix4.identity()
          ..rotateZ(motionAngle)
          ..multiply(Matrix4.diagonal3Values(scaleX, scaleY, 1));
        return Transform(
          key: const ValueKey<String>('floating_ball_material'),
          alignment: Alignment.center,
          transform: transform,
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: dockScale * liveScale * hoverScale * reminderScale,
              child: Container(
                width: s,
                height: s,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: Alignment(
                      (-0.32 - motion.dx * 0.16).clamp(-0.7, 0.1),
                      (-0.34 - motion.dy * 0.16).clamp(-0.7, 0.1),
                    ),
                    radius: 1.06,
                    colors: [
                      Color.lerp(effColor, Colors.white, 0.68)!,
                      Color.lerp(effColor, const Color(0xFF7AE8FF), 0.12)!,
                      effColor,
                      Color.lerp(effColor, Colors.black, 0.48)!,
                    ],
                    stops: const [0.0, 0.28, 0.64, 1.0],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: 0.38 + pressEase * 0.22,
                    ),
                    width: 0.9 + pressEase * 0.5,
                  ),
                  boxShadow: [
                    // Sombra de profundidade (sempre, para "flutuar").
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: docked ? 0.26 : 0.34,
                      ),
                      blurRadius: s * (0.22 + hoverEase * 0.08),
                      offset: Offset(
                        motion.dx * s * 0.08,
                        s * (0.10 + hoverEase * 0.02) + motion.dy * s * 0.06,
                      ),
                    ),
                    if (widget.dynamicOrbEffect)
                      BoxShadow(
                        color: const Color(0xFF53D8FF).withValues(
                          alpha: 0.16 + effectiveOrbIntensity * 0.22,
                        ),
                        blurRadius: s * (0.32 + effectiveOrbIntensity * 0.22),
                        spreadRadius:
                            effectiveOrbIntensity * (docked ? 1.0 : 1.8),
                      ),
                    if (hovered)
                      BoxShadow(
                        color: const Color(
                          0xFF79F2D0,
                        ).withValues(alpha: 0.26 + hoverEase * 0.22),
                        blurRadius: s * (0.36 + hoverEase * 0.18),
                        spreadRadius: 1.0 + hoverEase * 2.0,
                      ),
                    if (reminderVisible || burst > 0)
                      BoxShadow(
                        color: const Color(0xFF88F7FF).withValues(
                          alpha: (0.30 + reminderPulse * 0.30 + burst * 0.35)
                              .clamp(0.0, 1.0),
                        ),
                        blurRadius:
                            s * (0.44 + reminderPulse * 0.26 + burst * 0.40),
                        spreadRadius: 2.0 + reminderPulse * 2.5 + burst * 3.0,
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
                          key: const ValueKey<String>(
                            'floating_ball_inner_effect',
                          ),
                          painter: _DynamicOrbPainter(
                            phase: orbPhase,
                            baseColor: color,
                            intensity: effectiveOrbIntensity,
                            hovered: hovered,
                            isActive: widget.isActive,
                            motion: motion,
                            pressure: pressEase,
                          ),
                        ),
                      ),
                    Positioned(
                      left: s * (0.13 - motion.dx * 0.055 + pressEase * 0.02),
                      top: s * (0.10 - motion.dy * 0.045 + pressEase * 0.018),
                      child: Container(
                        width: s * (0.38 + pressEase * 0.04),
                        height: s * (0.22 + pressEase * 0.025),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(s),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(
                                alpha: 0.72 + pressEase * 0.14,
                              ),
                              Colors.white.withValues(alpha: 0.18),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                            stops: const [0.0, 0.48, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    Widget visual = circle;
    if (ringVisible) {
      final ringStroke = FloatingBall.ringStrokeForSize(widget.size);
      final ringGap = FloatingBall.ringGapForSize(widget.size);
      final ringSize = widget.size + (ringGap + ringStroke) * 2;
      visual = SizedBox(
        width: ringSize,
        height: ringSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 0,
                end: widget.progress.clamp(0.0, 1.0),
              ),
              duration: _reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 520),
              curve: Curves.easeOutCubic,
              builder: (context, progress, _) => AnimatedBuilder(
                animation: Listenable.merge([_press, _release, _ringFrame]),
                builder: (context, _) {
                  final press = Curves.easeOutCubic.transform(_press.value);
                  final wave = _reduceMotion || _release.value >= 1
                      ? 0.0
                      : math.sin(_release.value * math.pi) *
                            math.exp(-_release.value * 2.8);
                  final motion = _dragging
                      ? _dragVector
                      : _releaseVector * wave;
                  final strength = motion.distance.clamp(0.0, 1.0);
                  final angle = strength > 0.001
                      ? math.atan2(motion.dy, motion.dx)
                      : 0.0;
                  final transform = Matrix4.identity()
                    ..rotateZ(angle)
                    ..multiply(
                      Matrix4.diagonal3Values(
                        1 + strength * 0.075 + press * 0.018,
                        1 - strength * 0.032 - press * 0.028,
                        1,
                      ),
                    );
                  return Transform(
                    key: const ValueKey<String>('floating_ball_progress_ring'),
                    alignment: Alignment.center,
                    transform: transform,
                    child: CustomPaint(
                      size: Size.square(ringSize),
                      painter: _ProgressRingPainter(
                        progress: progress,
                        strokeWidth: ringStroke,
                        baseColor: color,
                        phase: _ringFrame.value,
                        reduceMotion: _reduceMotion,
                      ),
                    ),
                  );
                },
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

    Widget interactive = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      onSecondaryTap: widget.onSecondaryTap,
      onPanDown: (_) => _setPressed(true),
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      onPanCancel: _handlePanCancel,
      child: visual,
    );
    final label = widget.semanticLabel;
    if (label != null) {
      interactive = Semantics(
        button: true,
        label: label,
        value: ringVisible
            ? '${(widget.progress.clamp(0.0, 1.0) * 100).round()}%'
            : null,
        child: ExcludeSemantics(child: interactive),
      );
    }

    return MouseRegion(
      key: const ValueKey<String>('floating_ball_pointer'),
      cursor: _pressed || _dragging
          ? SystemMouseCursors.grabbing
          : SystemMouseCursors.grab,
      onEnter: (_) {
        if (widget.hoverReactiveBall) _hover.forward();
      },
      onExit: (_) {
        if (widget.hoverReactiveBall) _hover.reverse();
      },
      child: interactive,
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

/// Desenha uma "íris aurora": fitas aquáticas em profundidade, um halo de
/// íris, reflexo cáustico e uma pequena gota orbital. O resultado remete ao
/// cuidado ocular sem transformar a bolinha num ícone literal de olho.
class _DynamicOrbPainter extends CustomPainter {
  _DynamicOrbPainter({
    required this.phase,
    required this.baseColor,
    required this.intensity,
    required this.hovered,
    required this.isActive,
    required this.motion,
    required this.pressure,
  });

  final double phase;
  final Color baseColor;
  final double intensity;
  final bool hovered;
  final bool isActive;
  final Offset motion;
  final double pressure;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final center = Offset(
      size.width / 2 - motion.dx * s * 0.07,
      size.height / 2 - motion.dy * s * 0.07 + pressure * s * 0.02,
    );
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

    final spin = phase * 2 * math.pi + motion.dx * 0.45 - motion.dy * 0.24;
    final hoverLift = hovered ? 1.25 : 1.0;
    final activeLift = isActive ? 1.18 : 1.0;
    final alpha = (0.18 + intensity * 0.28) * hoverLift * activeLift;

    // Duas auroras passam por trás da íris. A diferença de velocidade cria
    // paralaxe suficiente para sugerir profundidade mesmo no tamanho padrão.
    _drawRibbon(
      canvas,
      size,
      angle: spin,
      colorA: const Color(0xFF5EEBFF),
      colorB: const Color(0xFF2F80FF),
      alpha: (alpha * 0.88).clamp(0.0, 0.66),
      width: s * (0.14 + intensity * 0.07),
      vertical: false,
    );
    _drawRibbon(
      canvas,
      size,
      angle: -spin * 0.82 + math.pi / 2.7,
      colorA: const Color(0xFFB8FFF4),
      colorB: const Color(0xFF26D59E),
      alpha: (alpha * 0.72).clamp(0.0, 0.56),
      width: s * (0.12 + intensity * 0.06),
      vertical: true,
    );

    _drawIrisHalo(
      canvas,
      size,
      center: center,
      spin: spin,
      intensity: intensity,
      hovered: hovered,
      isActive: isActive,
    );

    // Núcleo levemente deslocado: funciona como uma lente, não como pupila.
    final core = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.22, -0.28),
        radius: 0.86,
        colors: [
          Colors.white.withValues(alpha: 0.48 * intensity),
          const Color(0xFFB8FFF4).withValues(alpha: 0.28 * intensity),
          const Color(0xFF35C9FF).withValues(alpha: 0.12 * intensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.34, 0.70, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: s * 0.30));
    canvas.drawCircle(center, s * (hovered ? 0.235 : 0.21), core);

    _drawCausticCrescent(
      canvas,
      size,
      center: center,
      spin: spin,
      alpha: (alpha * 0.82).clamp(0.0, 0.58),
    );
    _drawOrbitingTear(
      canvas,
      size,
      center: center,
      spin: spin,
      intensity: intensity,
      hovered: hovered,
    );

    canvas.restore();
  }

  void _drawIrisHalo(
    Canvas canvas,
    Size size, {
    required Offset center,
    required double spin,
    required double intensity,
    required bool hovered,
    required bool isActive,
  }) {
    final s = size.shortestSide;
    final breath = math.sin(spin * 0.72) * s * 0.012;
    final radius = s * (hovered ? 0.255 : 0.235) + breath;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final rotation = GradientRotation(spin * 0.58);
    final haloAlpha = (0.22 + intensity * 0.30 + (isActive ? 0.08 : 0.0)).clamp(
      0.0,
      0.68,
    );

    final softHalo = Paint()
      ..color = const Color(0xFF65F4E1).withValues(alpha: haloAlpha * 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.12
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.055);
    canvas.drawCircle(center, radius, softHalo);

    final iris = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s * (0.035 + intensity * 0.018)
      ..blendMode = BlendMode.screen
      ..shader = SweepGradient(
        colors: [
          const Color(0xFFB8FFF4).withValues(alpha: haloAlpha),
          const Color(0xFF4FE6FF).withValues(alpha: haloAlpha * 0.70),
          Colors.white.withValues(alpha: haloAlpha * 0.92),
          const Color(0xFF3A8DFF).withValues(alpha: haloAlpha * 0.58),
          const Color(0xFFB8FFF4).withValues(alpha: haloAlpha),
        ],
        stops: const [0.0, 0.26, 0.48, 0.76, 1.0],
        transform: rotation,
      ).createShader(rect);
    canvas.drawCircle(center, radius, iris);

    // Pequenas aberturas dão textura de íris sem adicionar imagens ou assets.
    final glints = Paint()
      ..color = Colors.white.withValues(alpha: haloAlpha * 0.52)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(0.55, s * 0.018)
      ..blendMode = BlendMode.screen;
    for (var i = 0; i < 5; i++) {
      final start = spin * 0.42 + i * (math.pi * 2 / 5);
      canvas.drawArc(rect, start, 0.22 + intensity * 0.05, false, glints);
    }
  }

  void _drawCausticCrescent(
    Canvas canvas,
    Size size, {
    required Offset center,
    required double spin,
    required double alpha,
  }) {
    final s = size.shortestSide;
    final rect = Rect.fromCenter(
      center: center.translate(-s * 0.025, -s * 0.02),
      width: s * 0.48,
      height: s * 0.31,
    );
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-spin * 0.24 - 0.28);
    canvas.translate(-center.dx, -center.dy);
    final caustic = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(0.75, s * 0.026)
      ..blendMode = BlendMode.screen
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: alpha),
          const Color(0xFF9CFFF1).withValues(alpha: alpha * 0.72),
          Colors.transparent,
        ],
        stops: const [0.0, 0.30, 0.70, 1.0],
      ).createShader(rect);
    canvas.drawArc(rect, math.pi * 0.18, math.pi * 0.98, false, caustic);
    canvas.restore();
  }

  void _drawOrbitingTear(
    Canvas canvas,
    Size size, {
    required Offset center,
    required double spin,
    required double intensity,
    required bool hovered,
  }) {
    final s = size.shortestSide;
    final angle = spin * 0.86 - math.pi / 2;
    final orbit = s * (hovered ? 0.31 : 0.285);
    final point = center + Offset(math.cos(angle), math.sin(angle)) * orbit;
    final radius = s * (0.027 + intensity * 0.012);
    final halo = Paint()
      ..color = const Color(
        0xFFB8FFF4,
      ).withValues(alpha: (0.24 + intensity * 0.24).clamp(0.0, 0.58))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 1.45);
    canvas.drawCircle(point, radius * 2.1, halo);
    canvas.drawCircle(
      point,
      radius,
      Paint()
        ..color = Color.lerp(const Color(0xFF79F2D0), Colors.white, 0.68)!
        ..blendMode = BlendMode.screen,
    );
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
      old.isActive != isActive ||
      old.motion != motion ||
      old.pressure != pressure;
}

/// Arco líquido contínuo com profundidade, reflexo e ponta luminosa.
class _ProgressRingPainter extends CustomPainter {
  _ProgressRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.baseColor,
    required this.phase,
    required this.reduceMotion,
  });

  final double progress;
  final double strokeWidth;
  final Color baseColor;
  final double phase;
  final bool reduceMotion;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth * 2.35) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = -math.pi / 2;

    // Sombra externa e aro interno dão separação sobre fundos claros ou escuros
    // sem transformar o progresso numa borda pesada.
    final outerDepth = Paint()
      ..color = Colors.black.withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 1.7
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, strokeWidth * 0.72);
    canvas.drawCircle(center, radius, outerDepth);

    final track = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.white.withValues(alpha: 0.10),
          baseColor.withValues(alpha: 0.22),
          Colors.white.withValues(alpha: 0.16),
          baseColor.withValues(alpha: 0.14),
          Colors.white.withValues(alpha: 0.10),
        ],
        stops: const [0, 0.26, 0.52, 0.78, 1],
        transform: const GradientRotation(start),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    final innerRim = Paint()
      ..color = Colors.white.withValues(alpha: 0.11)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.7, strokeWidth * 0.28);
    canvas.drawCircle(center, radius - strokeWidth * 0.42, innerRim);

    if (progress <= 0) return;

    final urgency = ((progress - 0.75) / 0.25).clamp(0.0, 1.0);
    final pulse = reduceMotion || progress < 0.9
        ? 0.0
        : (math.sin(phase * math.pi * 2) * 0.5 + 0.5) * urgency;
    final totalSweep = math.pi * 2 * progress.clamp(0.0, 1.0);
    final aqua = Color.lerp(baseColor, const Color(0xFFA9FFF2), 0.72)!;
    final warm = Color.lerp(aqua, const Color(0xFFFFE39A), urgency * 0.42)!;
    final deep = Color.lerp(baseColor, const Color(0xFF2878EA), 0.42)!;
    final shimmer = reduceMotion ? 0.0 : math.sin(phase * math.pi * 2) * 0.025;

    // Halo contínuo: substitui dezenas de segmentos e mantém o arco suave em
    // todos os tamanhos, inclusive durante a transição do progresso.
    final glow = Paint()
      ..color = warm.withValues(alpha: 0.24 + urgency * 0.10 + pulse * 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * (1.65 + pulse * 0.10)
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, strokeWidth * 1.05);
    canvas.drawArc(rect, start, totalSweep, false, glow);

    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: start,
        endAngle: start + math.pi * 2,
        colors: [deep, baseColor, aqua, warm],
        stops: const [0.0, 0.30, 0.72, 1.0],
        transform: GradientRotation(shimmer),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * (1.02 + pulse * 0.04)
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, start, totalSweep, false, progressPaint);

    // Reflexo interno deslocado para o lado da luz: cria volume sem alterar a
    // extensão matemática do progresso.
    final highlightRect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth * 0.22,
    );
    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.34 + pulse * 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, strokeWidth * 0.26)
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(highlightRect, start, totalSweep, false, highlight);

    final origin = Offset(center.dx, center.dy - radius);
    canvas.drawCircle(
      origin,
      strokeWidth * 0.24,
      Paint()..color = Colors.white.withValues(alpha: 0.62),
    );

    final tipAngle = start + totalSweep;
    final tip = Offset(
      center.dx + math.cos(tipAngle) * radius,
      center.dy + math.sin(tipAngle) * radius,
    );
    final haloRadius = strokeWidth * (1.45 + urgency * 0.55 + pulse * 0.45);
    final halo = Paint()
      ..color = warm.withValues(alpha: 0.30 + urgency * 0.16 + pulse * 0.16)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, haloRadius);
    canvas.drawCircle(tip, haloRadius, halo);
    canvas.drawCircle(
      tip,
      strokeWidth * (0.60 + urgency * 0.12 + pulse * 0.08),
      Paint()..color = Color.lerp(warm, Colors.white, 0.62)!,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter old) =>
      old.progress != progress ||
      old.strokeWidth != strokeWidth ||
      old.baseColor != baseColor ||
      old.phase != phase ||
      old.reduceMotion != reduceMotion;
}
