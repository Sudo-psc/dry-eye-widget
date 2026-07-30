import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/orb_interaction.dart';
import '../ui/design_tokens.dart';
import '../utils/constants.dart';
import '../utils/edge_snap.dart';

/// A bolinha flutuante.
///
/// Visualmente: cor IDLE e cor de alerta com feedback único na transição.
/// Tamanho, cores e opacidade no IDLE continuam configuráveis.
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

  /// Rótulo da pílula do lembrete. Fica aqui porque a mesma definição precisa
  /// desenhar o texto e medi-lo para dimensionar a pílula e a janela.
  static const TextStyle blinkReminderTextStyle = TextStyle(
    color: AppColorTokens.textPrimary,
    fontFamily: AppTypography.family,
    fontSize: AppTypography.supporting,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

  /// Tamanho exato da pílula do lembrete de piscada.
  ///
  /// A largura acompanha o texto medido em vez de uma constante: rótulos curtos
  /// como "Pisque" e "Blink" deixavam uma sobra vazia à direita, porque a
  /// fórmula antiga reservava espaço fixo independentemente do conteúdo.
  ///
  /// A janela nativa usa este mesmo cálculo — se as duas contas divergirem, a
  /// pílula sobra na janela ou é cortada por ela.
  static Size blinkReminderSize({
    required double ballSize,
    required String text,
    required bool showRing,
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    final visualWidth = showRing
        ? ballSize +
              (ringGapForSize(ballSize) + ringStrokeForSize(ballSize)) * 2
        : ballSize;
    final painter = TextPainter(
      text: TextSpan(text: text.trim(), style: blinkReminderTextStyle),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
      maxLines: 1,
    )..layout();

    final padLeft = showRing ? AppSpace.x1 : AppSpace.x2;
    final width =
        padLeft + visualWidth + AppSpace.x2 + painter.width + AppSpace.x3;
    // Altura acomoda a bolinha e o texto: com escala de texto grande o rótulo
    // passa a mandar.
    final height = math.max(
      math.max(ballSize + AppSpace.x6, 52.0),
      painter.height + AppSpace.x1 * 2,
    );
    return Size(width.ceilToDouble(), height.ceilToDouble());
  }

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

  /// O avanço do próprio ciclo já atualiza o anel. Não há pulso decorativo.
  static bool shouldAnimateRing(double progress) => false;

  @override
  State<FloatingBall> createState() => _FloatingBallState();
}

class _FloatingBallState extends State<FloatingBall>
    with TickerProviderStateMixin {
  late final AnimationController _blink;
  late final AnimationController _hover;
  late final AnimationController _reminderBurst;
  late final AnimationController _press;
  late final Animation<double> _opacity;
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
    _blink = AnimationController(vsync: this, duration: AppMotion.normal);
    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 0.82,
        ).chain(CurveTween(curve: AppMotion.standard)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.82,
          end: 1,
        ).chain(CurveTween(curve: AppMotion.standard)),
        weight: 1,
      ),
    ]).animate(_blink);
    _hover = AnimationController(
      vsync: this,
      duration: AppMotion.fast,
      reverseDuration: AppMotion.normal,
    );
    _reminderBurst = AnimationController(vsync: this, duration: AppMotion.slow);
    _press = AnimationController(
      vsync: this,
      duration: AppMotion.fast,
      reverseDuration: AppMotion.fast,
    );
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
      // A preferência permanece disponível, mas a linguagem de movimento
      // calma limita feedback visual a uma transição curta e não repetitiva.
      _blink.duration = AppMotion.normal;
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
        startCycleFeedback: oldWidget.isActive != widget.isActive,
      );
    }
  }

  void _resetController(AnimationController controller) {
    controller.stop();
    if (controller.value != 0) controller.value = 0;
  }

  void _syncAllMotion({
    bool startReminderBurst = false,
    bool startCycleFeedback = false,
  }) {
    _syncAnimation(startCycleFeedback: startCycleFeedback);

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

  void _syncAnimation({required bool startCycleFeedback}) {
    _resetController(_blink);
    if (_motionAllowed && startCycleFeedback) {
      _blink.forward(from: 0);
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
    _resetController(_hover);
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
    _hover.dispose();
    _reminderBurst.dispose();
    _press.dispose();
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
    final effectiveOrbIntensity = widget.dynamicOrbEffect && !_dragging
        ? (orbIntensity + hoverBoost * 0.28).clamp(0.0, 1.0)
        : 0.0;

    Widget circle = AnimatedBuilder(
      animation: Listenable.merge([_opacity, _hover, _reminderBurst, _press]),
      builder: (context, _) {
        final burst = widget.blinkReminderVisible && !widget.isActive
            ? math.sin(_reminderBurst.value * math.pi)
            : 0.0;
        final effColor = Color.lerp(
          color,
          AppColorTokens.accent,
          burst * 0.32,
        )!;
        final hovered = materialHovered;
        final hoverEase = Curves.easeOutCubic.transform(_hover.value);
        final pressEase = Curves.easeOutCubic.transform(_press.value);
        final scaleX = 1.0 + pressEase * 0.028;
        final scaleY = 1.0 - pressEase * 0.045;
        final hoverScale = 1.0 + hoverEase * (docked ? 0.13 : 0.11);
        final reminderScale = 1.0 + burst * 0.06;
        final dockScale = docked ? 0.96 : 1.0;
        final baseVisualOpacity = widget.isActive
            ? 1.0
            : (baseOpacity + (1.0 - baseOpacity) * burst);
        final visualOpacity = (baseVisualOpacity * _opacity.value).clamp(
          0.0,
          1.0,
        );
        final transform = Matrix4.identity()
          ..multiply(Matrix4.diagonal3Values(scaleX, scaleY, 1));
        return Transform(
          key: const ValueKey<String>('floating_ball_material'),
          alignment: Alignment.center,
          transform: transform,
          child: Opacity(
            opacity: visualOpacity,
            child: Transform.scale(
              scale: dockScale * hoverScale * reminderScale,
              child: Container(
                width: s,
                height: s,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.32, -0.34),
                    radius: 1.06,
                    colors: [
                      Color.lerp(effColor, AppColorTokens.textPrimary, 0.58)!,
                      Color.lerp(effColor, AppColorTokens.accent, 0.12)!,
                      effColor,
                      Color.lerp(effColor, AppColorTokens.canvas, 0.48)!,
                    ],
                    stops: const [0.0, 0.28, 0.64, 1.0],
                  ),
                  border: Border.all(
                    color: AppColorTokens.textPrimary.withValues(
                      alpha: 0.38 + pressEase * 0.22,
                    ),
                    width: 0.9 + pressEase * 0.5,
                  ),
                  boxShadow: [
                    // Sombra de profundidade (sempre, para "flutuar").
                    BoxShadow(
                      color: AppColorTokens.canvas.withValues(
                        alpha: docked ? 0.26 : 0.34,
                      ),
                      blurRadius: s * (0.22 + hoverEase * 0.08),
                      offset: Offset(0, s * (0.10 + hoverEase * 0.02)),
                    ),
                    if (widget.dynamicOrbEffect && !_dragging)
                      BoxShadow(
                        color: AppColorTokens.accent.withValues(
                          alpha: 0.16 + effectiveOrbIntensity * 0.22,
                        ),
                        blurRadius: s * (0.32 + effectiveOrbIntensity * 0.22),
                        spreadRadius:
                            effectiveOrbIntensity * (docked ? 1.0 : 1.8),
                      ),
                    if (hovered)
                      BoxShadow(
                        color: AppColorTokens.accent.withValues(
                          alpha: 0.18 + hoverEase * 0.18,
                        ),
                        blurRadius: s * (0.36 + hoverEase * 0.18),
                        spreadRadius: 1.0 + hoverEase * 2.0,
                      ),
                    if (reminderVisible || burst > 0)
                      BoxShadow(
                        color: AppColorTokens.accent.withValues(
                          alpha: (0.24 + burst * 0.28).clamp(0.0, 1.0),
                        ),
                        blurRadius: s * (0.36 + burst * 0.24),
                        spreadRadius: 1.0 + burst * 2.0,
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
                              AppColorTokens.textPrimary.withValues(
                                alpha: 0.72 + pressEase * 0.14,
                              ),
                              AppColorTokens.textPrimary.withValues(
                                alpha: 0.18,
                              ),
                              AppColorTokens.transparent,
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
                duration: AppMotion.resolve(context, AppMotion.normal),
                curve: AppMotion.standard,
                builder: (context, progress, _) => AnimatedBuilder(
                  animation: _press,
                  builder: (context, _) => _ProgressRing(
                    progress: progress,
                    ringSize: ringSize,
                    strokeWidth: ringStroke,
                    baseColor: color,
                    press: _press.value,
                  ),
                ),
              )
            else
              AnimatedBuilder(
                animation: _press,
                builder: (context, _) => _ProgressRing(
                  progress: widget.progress.clamp(0.0, 1.0),
                  ringSize: ringSize,
                  strokeWidth: ringStroke,
                  baseColor: color,
                  press: 0,
                ),
              ),
            circle,
          ],
        ),
      );
    }
    if (reminderVisible) {
      final pillSize = FloatingBall.blinkReminderSize(
        ballSize: widget.size,
        text: widget.blinkReminderText,
        showRing: ringVisible,
        textScaler: MediaQuery.textScalerOf(context),
      );
      visual = _BlinkReminderPill(
        width: pillSize.width,
        height: pillSize.height,
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
        color: focusVisible ? AppColorTokens.focus : AppColorTokens.transparent,
        width: 2,
      ),
      boxShadow: focusVisible
          ? [
              BoxShadow(
                color: AppColorTokens.canvas,
                blurRadius: 0,
                spreadRadius: 1,
              ),
            ]
          : const [],
    );
    visual = _motionAllowed
        ? AnimatedContainer(
            key: const ValueKey<String>('floating_ball_focus_indicator'),
            duration: AppMotion.fast,
            curve: AppMotion.standard,
            foregroundDecoration: focusDecoration,
            child: visual,
          )
        : Container(
            key: const ValueKey<String>('floating_ball_focus_indicator'),
            foregroundDecoration: focusDecoration,
            child: visual,
          );
    visual = RepaintBoundary(
      key: const ValueKey<String>('floating_ball_repaint_boundary'),
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
    required this.press,
  });

  final double progress;
  final double ringSize;
  final double strokeWidth;
  final Color baseColor;
  final double press;

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
            color: AppColorTokens.surfaceOverlay.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(color: color.withValues(alpha: 0.32), width: 1),
            boxShadow: [
              ...AppDepth.floating,
              BoxShadow(
                color: color.withValues(alpha: 0.22),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          // Se a janela ainda não tiver crescido para o tamanho da pílula, o
          // conteúdo é cortado em silêncio em vez de listrar a tela.
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height / 2),
            // A pílula se compõe sempre no tamanho pretendido, mesmo que a
            // janela ainda não tenha crescido: o excedente é cortado em
            // silêncio em vez de listrar a tela por alguns quadros.
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              minWidth: width,
              maxWidth: width,
              minHeight: height,
              maxHeight: height,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  progressRingVisible ? AppSpace.x1 : AppSpace.x2,
                  AppSpace.x1,
                  AppSpace.x3,
                  AppSpace.x1,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    child,
                    const SizedBox(width: AppSpace.x2),
                    Flexible(
                      child: Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        // Mesmo estilo usado na medição da largura; separá-los
                        // faria a pílula sobrar ou cortar o texto.
                        style: FloatingBall.blinkReminderTextStyle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lente ocular estática e tonal; hover e pressão são os únicos feedbacks.
class _DynamicOrbPainter extends CustomPainter {
  _DynamicOrbPainter({
    required this.baseColor,
    required this.intensity,
    required this.hovered,
    required this.isActive,
    required this.pressure,
  });

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
    final accent = Color.lerp(AppColorTokens.accent, baseColor, 0.24)!;
    final lift = hovered ? 1.0 : 0.82;
    final activeLift = isActive ? 1.0 : 0.86;
    final alpha = intensity * lift * activeLift;

    final ambient = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.22, -0.28),
        radius: 0.9,
        colors: [
          AppColorTokens.textPrimary.withValues(alpha: 0.22 * alpha),
          accent.withValues(alpha: 0.14 * alpha),
          AppColorTokens.transparent,
        ],
      ).createShader(bounds);
    canvas.drawCircle(center, s * 0.48, ambient);

    final lensRadius = s * (hovered ? 0.26 : 0.23);
    final lensRect = Rect.fromCircle(center: center, radius: lensRadius);
    final lens = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s * (0.032 + intensity * 0.012)
      ..shader = SweepGradient(
        colors: [
          accent.withValues(alpha: 0.5 * alpha),
          AppColorTokens.textPrimary.withValues(alpha: 0.66 * alpha),
          accent.withValues(alpha: 0.5 * alpha),
        ],
      ).createShader(lensRect);
    canvas.drawCircle(center, lensRadius, lens);

    final core = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.3),
        colors: [
          AppColorTokens.textPrimary.withValues(alpha: 0.5 * alpha),
          accent.withValues(alpha: 0.18 * alpha),
          AppColorTokens.transparent,
        ],
      ).createShader(lensRect);
    canvas.drawCircle(center, lensRadius * 0.78, core);

    canvas.drawCircle(
      center.translate(-s * 0.08, -s * 0.09),
      s * 0.035,
      Paint()
        ..color = AppColorTokens.textPrimary.withValues(alpha: 0.72 * alpha),
    );
  }

  @override
  bool shouldRepaint(_DynamicOrbPainter old) =>
      old.baseColor != baseColor ||
      old.intensity != intensity ||
      old.hovered != hovered ||
      old.isActive != isActive ||
      old.pressure != pressure;
}

/// Progresso ambiental contínuo: um único acento, sem pulso ou urgência visual.
class _ProgressRingPainter extends CustomPainter {
  _ProgressRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.baseColor,
  });

  final double progress;
  final double strokeWidth;
  final Color baseColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth * 2.35) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = -math.pi / 2;

    final outerDepth = Paint()
      ..color = AppColorTokens.canvas.withValues(alpha: 0.46)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 1.5
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, strokeWidth * 0.6);
    canvas.drawCircle(center, radius, outerDepth);

    final track = Paint()
      ..color = AppColorTokens.progressTrack
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;

    final totalSweep = math.pi * 2 * progress.clamp(0.0, 1.0);
    final accent = Color.lerp(AppColorTokens.accent, baseColor, 0.18)!;
    final accentSoft = Color.lerp(accent, AppColorTokens.textPrimary, 0.28)!;
    final glow = Paint()
      ..color = accent.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 1.55
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, strokeWidth);
    canvas.drawArc(rect, start, totalSweep, false, glow);

    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: start,
        endAngle: start + math.pi * 2,
        colors: [accent, accentSoft],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, start, totalSweep, false, progressPaint);

    final tipAngle = start + totalSweep;
    final tip = Offset(
      center.dx + math.cos(tipAngle) * radius,
      center.dy + math.sin(tipAngle) * radius,
    );
    final haloRadius = strokeWidth * 1.25;
    final halo = Paint()
      ..color = accent.withValues(alpha: 0.28)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, haloRadius);
    canvas.drawCircle(tip, haloRadius, halo);
    canvas.drawCircle(tip, strokeWidth * 0.55, Paint()..color = accentSoft);
  }

  @override
  bool shouldRepaint(_ProgressRingPainter old) =>
      old.progress != progress ||
      old.strokeWidth != strokeWidth ||
      old.baseColor != baseColor;
}
