import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/orb_interaction.dart';
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
    this.semanticHint,
    this.semanticValue,
    this.focusNode,
    this.isSurfaceVisible = true,
    this.hitTargetExtent = minimumHitTargetExtent,
    this.interactionMode = OrbInteractionMode.automatic,
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
  final String? semanticHint;
  final String? semanticValue;
  final FocusNode? focusNode;
  final bool isSurfaceVisible;
  final double hitTargetExtent;
  final OrbInteractionMode interactionMode;
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
  static const double minimumHitTargetExtent = 44.0;
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
  late final AnimationController _ring;
  late final Animation<double> _opacity;
  late final ValueNotifier<double> _orbFrame;
  late final ValueNotifier<double> _ringFrame;
  Timer? _orbTimer;
  Duration? _orbTick;
  double _orbPhase = 0;
  bool _reduceMotion = false;
  bool _dependenciesReady = false;
  bool _pressed = false;
  bool _dragging = false;
  bool _hasFocus = false;
  bool _showFocusHighlight = false;

  bool get _motionAllowed =>
      _dependenciesReady && widget.isSurfaceVisible && !_reduceMotion;

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
    _ring = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _ringFrame = ValueNotifier(0);
    _ring.addListener(_updateRingFrame);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations == true;
    final firstSync = !_dependenciesReady;
    if (firstSync || reduce != _reduceMotion) {
      _dependenciesReady = true;
      _reduceMotion = reduce;
      _syncAllMotion(startReminderBurst: firstSync);
    }
  }

  @override
  void didUpdateWidget(covariant FloatingBall oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.blinkDuration != widget.blinkDuration) {
      _blink.duration = widget.blinkDuration;
    }

    final oldReminderVisible =
        oldWidget.blinkReminderVisible &&
        !oldWidget.isActive &&
        oldWidget.dockEdge == null &&
        oldWidget.blinkReminderText.trim().isNotEmpty;
    final reminderVisible =
        widget.blinkReminderVisible &&
        !widget.isActive &&
        widget.dockEdge == null &&
        widget.blinkReminderText.trim().isNotEmpty;
    final motionInputsChanged =
        oldWidget.blinkDuration != widget.blinkDuration ||
        oldWidget.isActive != widget.isActive ||
        oldWidget.dynamicOrbEffect != widget.dynamicOrbEffect ||
        oldWidget.orbIntensity != widget.orbIntensity ||
        oldWidget.hoverReactiveBall != widget.hoverReactiveBall ||
        oldWidget.blinkReminderVisible != widget.blinkReminderVisible ||
        oldWidget.blinkReminderText != widget.blinkReminderText ||
        oldWidget.showProgress != widget.showProgress ||
        oldWidget.dockEdge != widget.dockEdge ||
        oldWidget.isSurfaceVisible != widget.isSurfaceVisible ||
        FloatingBall.shouldAnimateRing(oldWidget.progress) !=
            FloatingBall.shouldAnimateRing(widget.progress);
    if (motionInputsChanged) {
      if (!widget.isSurfaceVisible) {
        _pressed = false;
        _dragging = false;
      }
      _syncAllMotion(
        startReminderBurst: !oldReminderVisible && reminderVisible,
      );
    }
  }

  void _resetController(AnimationController controller) {
    controller.stop();
    if (controller.value != 0) controller.value = 0;
  }

  void _syncAllMotion({bool startReminderBurst = false}) {
    _syncAnimation();
    _syncOrbAnimation();
    _syncReminderAnimation();
    _syncRingAnimation();

    if (!_motionAllowed) {
      _resetController(_hover);
      _resetController(_reminderBurst);
      _resetController(_press);
      return;
    }

    if (!widget.hoverReactiveBall) _resetController(_hover);
    final reminderCanAnimate = widget.blinkReminderVisible && !widget.isActive;
    if (!reminderCanAnimate) {
      _resetController(_reminderBurst);
    } else if (startReminderBurst) {
      _reminderBurst.forward(from: 0);
    }
  }

  void _syncAnimation() {
    if (_motionAllowed && widget.isActive) {
      if (!_blink.isAnimating) _blink.repeat(reverse: true);
    } else {
      _resetController(_blink);
    }
  }

  void _syncOrbAnimation() {
    final intensity = widget.orbIntensity.clamp(0.0, 1.0);
    if (_motionAllowed && widget.dynamicOrbEffect && intensity > 0) {
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
    if (_motionAllowed &&
        visible &&
        FloatingBall.shouldAnimateRing(widget.progress)) {
      if (!_ring.isAnimating) _ring.repeat();
    } else {
      _resetController(_ring);
    }
  }

  void _setPressed(bool value) {
    if (!widget.isSurfaceVisible) return;
    if (_pressed == value) return;
    setState(() => _pressed = value);
    if (!_motionAllowed) {
      _resetController(_press);
    } else if (value) {
      _press.forward();
    } else {
      _press.reverse();
    }
  }

  void _handlePanStart(DragStartDetails details) {
    setState(() => _dragging = true);
    _setPressed(true);
    widget.onDragStart?.call();
  }

  void _handlePanEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond;
    setState(() => _dragging = false);
    _setPressed(false);
    widget.onDragEnd?.call(velocity);
  }

  void _handlePanCancel() {
    setState(() => _dragging = false);
    _setPressed(false);
    widget.onDragEnd?.call(Offset.zero);
  }

  void _syncReminderAnimation() {
    if (_motionAllowed && widget.blinkReminderVisible && !widget.isActive) {
      if (!_reminder.isAnimating) _reminder.repeat(reverse: true);
    } else {
      _resetController(_reminder);
    }
  }

  void _handleFocusChange(bool value) {
    if (_hasFocus == value) return;
    setState(() => _hasFocus = value);
  }

  void _handleFocusHighlight(bool value) {
    if (_showFocusHighlight == value) return;
    setState(() => _showFocusHighlight = value);
  }

  @override
  void dispose() {
    _blink.dispose();
    _orbTimer?.cancel();
    _hover.dispose();
    _reminder.dispose();
    _reminderBurst.dispose();
    _press.dispose();
    _ring.removeListener(_updateRingFrame);
    _ring.dispose();
    _orbFrame.dispose();
    _ringFrame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final interaction = resolveOrbInteraction(
      mode: widget.interactionMode,
      hasActivationCallback: widget.onTap != null,
      hasDragCallback: widget.onDragStart != null || widget.onDragEnd != null,
    );
    final canActivate = widget.isSurfaceVisible && interaction.canActivate;
    final canDrag = widget.isSurfaceVisible && interaction.canDrag;
    final canSecondaryTap =
        widget.isSurfaceVisible &&
        widget.interactionMode.allowsActivation &&
        widget.onSecondaryTap != null;
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
    // Durante o arrasto, o material interno permanece independente do mouse.
    // O feedback de pressão continua na superfície externa, sem intensificar
    // nem deslocar as auroras internas a cada movimento.
    final materialHovered =
        widget.hoverReactiveBall && !_dragging && _hover.value > 0.01;
    final hoverBoost = materialHovered ? _hover.value : 0.0;
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
        final hovered = materialHovered;
        final hoverEase = Curves.easeOutCubic.transform(_hover.value);
        final pressEase = Curves.easeOutCubic.transform(_press.value);
        final scaleX = 1.0 + pressEase * 0.028;
        final scaleY = 1.0 - pressEase * 0.045;
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
                    center: const Alignment(-0.32, -0.34),
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
                      offset: Offset(0, s * (0.10 + hoverEase * 0.02)),
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
                            pressure: _dragging ? 0.0 : pressEase,
                          ),
                        ),
                      ),
                    Positioned(
                      left: s * (0.13 + pressEase * 0.02),
                      top: s * (0.10 + pressEase * 0.018),
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
            if (_motionAllowed)
              TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 0,
                  end: widget.progress.clamp(0.0, 1.0),
                ),
                duration: const Duration(milliseconds: 520),
                curve: Curves.easeOutCubic,
                builder: (context, progress, _) => AnimatedBuilder(
                  animation: Listenable.merge([_press, _ringFrame]),
                  builder: (context, _) => _ProgressRing(
                    progress: progress,
                    ringSize: ringSize,
                    strokeWidth: ringStroke,
                    baseColor: color,
                    phase: _ringFrame.value,
                    press: _press.value,
                    reduceMotion: false,
                  ),
                ),
              )
            else
              AnimatedBuilder(
                animation: Listenable.merge([_press, _ringFrame]),
                builder: (context, _) => _ProgressRing(
                  progress: widget.progress.clamp(0.0, 1.0),
                  ringSize: ringSize,
                  strokeWidth: ringStroke,
                  baseColor: color,
                  phase: 0,
                  press: 0,
                  reduceMotion: true,
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

    final requestedHitTarget = widget.hitTargetExtent;
    final hitTargetExtent = requestedHitTarget.isFinite
        ? math
              .max(FloatingBall.minimumHitTargetExtent, requestedHitTarget)
              .toDouble()
        : FloatingBall.minimumHitTargetExtent;
    visual = ConstrainedBox(
      key: const ValueKey<String>('floating_ball_hit_target'),
      constraints: BoxConstraints(
        minWidth: hitTargetExtent,
        minHeight: hitTargetExtent,
      ),
      child: Center(child: visual),
    );

    final focusVisible = _showFocusHighlight && canActivate;
    final focusDecoration = BoxDecoration(
      borderRadius: BorderRadius.circular(hitTargetExtent),
      border: Border.all(
        color: focusVisible
            ? Theme.of(context).colorScheme.primary
            : Colors.transparent,
        width: 2,
      ),
      boxShadow: focusVisible
          ? [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.92),
                blurRadius: 0,
                spreadRadius: 1,
              ),
            ]
          : const [],
    );
    visual = _motionAllowed
        ? AnimatedContainer(
            key: const ValueKey<String>('floating_ball_focus_indicator'),
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            foregroundDecoration: focusDecoration,
            child: visual,
          )
        : Container(
            key: const ValueKey<String>('floating_ball_focus_indicator'),
            foregroundDecoration: focusDecoration,
            child: visual,
          );

    final canPress = canActivate || canDrag;
    Widget interactive = GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTapDown: canPress ? (_) => _setPressed(true) : null,
      onTapUp: canPress ? (_) => _setPressed(false) : null,
      onTapCancel: canPress ? () => _setPressed(false) : null,
      onTap: canActivate ? widget.onTap : null,
      onSecondaryTap: canSecondaryTap ? widget.onSecondaryTap : null,
      onPanDown: canDrag ? (_) => _setPressed(true) : null,
      onPanStart: canDrag ? _handlePanStart : null,
      onPanEnd: canDrag ? _handlePanEnd : null,
      onPanCancel: canDrag ? _handlePanCancel : null,
      child: visual,
    );

    final label = widget.semanticLabel;
    final semanticValue =
        widget.semanticValue ??
        (ringVisible
            ? '${(widget.progress.clamp(0.0, 1.0) * 100).round()}%'
            : null);
    final hasPrimarySemantics =
        label != null ||
        widget.semanticHint != null ||
        semanticValue != null ||
        interaction.canActivate;
    Widget semanticChild = ExcludeSemantics(child: interactive);
    if (reminderVisible) {
      semanticChild = Stack(
        children: [
          semanticChild,
          Positioned.fill(
            child: Semantics(
              container: true,
              liveRegion: true,
              label: widget.blinkReminderText.trim(),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      );
    }
    if (hasPrimarySemantics) {
      interactive = Semantics(
        container: true,
        explicitChildNodes: reminderVisible,
        button: interaction.canActivate,
        enabled: interaction.canActivate ? canActivate : null,
        focusable: interaction.canActivate,
        focused: _hasFocus,
        label: label,
        hint: widget.semanticHint,
        value: semanticValue,
        onTap: canActivate ? widget.onTap : null,
        child: semanticChild,
      );
    } else {
      interactive = semanticChild;
    }

    interactive = FocusableActionDetector(
      key: const ValueKey<String>('floating_ball_focus'),
      enabled: canActivate,
      autofocus: false,
      focusNode: widget.focusNode,
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (canActivate) widget.onTap?.call();
            return null;
          },
        ),
      },
      onFocusChange: _handleFocusChange,
      onShowFocusHighlight: _handleFocusHighlight,
      child: interactive,
    );

    final pointer = MouseRegion(
      key: const ValueKey<String>('floating_ball_pointer'),
      cursor: !widget.isSurfaceVisible
          ? SystemMouseCursors.basic
          : _dragging && canDrag
          ? SystemMouseCursors.grabbing
          : interaction.canActivate || canSecondaryTap
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) {
        if (_motionAllowed &&
            widget.hoverReactiveBall &&
            (interaction.isInteractive || canSecondaryTap)) {
          _hover.forward();
        }
      },
      onExit: (_) {
        if (_motionAllowed && widget.hoverReactiveBall) {
          _hover.reverse();
        } else {
          _resetController(_hover);
        }
      },
      child: interactive,
    );

    return ExcludeSemantics(
      excluding: !widget.isSurfaceVisible,
      child: IgnorePointer(ignoring: !widget.isSurfaceVisible, child: pointer),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({
    required this.progress,
    required this.ringSize,
    required this.strokeWidth,
    required this.baseColor,
    required this.phase,
    required this.press,
    required this.reduceMotion,
  });

  final double progress;
  final double ringSize;
  final double strokeWidth;
  final Color baseColor;
  final double phase;
  final double press;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final pressEase = Curves.easeOutCubic.transform(press);
    final transform = Matrix4.identity()
      ..multiply(
        Matrix4.diagonal3Values(
          1 + pressEase * 0.018,
          1 - pressEase * 0.028,
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
          strokeWidth: strokeWidth,
          baseColor: baseColor,
          phase: phase,
          reduceMotion: reduceMotion,
        ),
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
    required this.pressure,
  });

  final double phase;
  final Color baseColor;
  final double intensity;
  final bool hovered;
  final bool isActive;
  final double pressure;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final center = Offset(
      size.width / 2,
      size.height / 2 + pressure * s * 0.02,
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

    final spin = phase * 2 * math.pi;
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
