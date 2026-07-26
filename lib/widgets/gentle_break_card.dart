import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/app_state.dart';
import '../ui/app_theme.dart';
import 'liquid_glass.dart';

/// Cartão compacto de pausa para o "modo suave": aparece no canto superior
/// direito sem bloquear o restante da tela. Mostra a mensagem da fase e, nas
/// fases com cronômetro, o tempo restante.
class GentleBreakCard extends StatelessWidget {
  const GentleBreakCard({
    super.key,
    required this.state,
    required this.strings,
    required this.secondsRemaining,
    required this.totalSeconds,
    this.completionInsight = '',
  });

  final AppState state;
  final AppStrings strings;
  final int secondsRemaining;
  final int totalSeconds;

  /// Insight local na conclusão (substitui o subtítulo quando não vazio).
  final String completionInsight;

  String get _timeText {
    final m = (secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final s = (secondsRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final title = strings.stateTitle(state);
    final subtitle = state == AppState.conclusao && completionInsight.isNotEmpty
        ? completionInsight
        : strings.stateSubtitle(state);
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.x3),
        child: Semantics(
          container: true,
          liveRegion: true,
          label: state.showsCountdown
              ? '$title. $_timeText. $subtitle'
              : '$title. $subtitle',
          child: LiquidGlass(
            width: AppComponentSize.gentleBreakWidth,
            borderRadius: AppRadii.xl,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.x4,
              vertical: AppSpace.x2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _BreakLabel(),
                      const SizedBox(height: AppSpace.x2),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppTypography.family,
                          color: AppColorTokens.textPrimary,
                          fontSize: AppTypography.title,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          letterSpacing: -0.25,
                        ),
                      ),
                      const SizedBox(height: AppSpace.x1),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppTypography.family,
                          color: AppColorTokens.textSecondary,
                          fontSize: AppTypography.supporting,
                          fontWeight: FontWeight.w400,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.x4),
                if (state.showsCountdown)
                  _CountdownDial(
                    timeText: _timeText,
                    secondsRemaining: secondsRemaining,
                    totalSeconds: totalSeconds,
                  )
                else
                  _StateBadge(state: state),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BreakLabel extends StatelessWidget {
  const _BreakLabel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        color: AppColorTokens.accent.withValues(alpha: 0.14),
        border: Border.all(color: AppColorTokens.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.x3,
          vertical: AppSpace.x1,
        ),
        child: Text(
          '20-20-20',
          style: const TextStyle(
            fontFamily: AppTypography.family,
            color: AppColorTokens.accent,
            fontSize: AppTypography.supporting,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

class _CountdownDial extends StatelessWidget {
  const _CountdownDial({
    required this.timeText,
    required this.secondsRemaining,
    required this.totalSeconds,
  });

  final String timeText;
  final int secondsRemaining;
  final int totalSeconds;

  @override
  Widget build(BuildContext context) {
    final progress = totalSeconds <= 0
        ? 0.0
        : (secondsRemaining / totalSeconds).clamp(0.0, 1.0).toDouble();

    return SizedBox.square(
      dimension: AppComponentSize.countdownDial,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: progress, end: progress),
        duration: AppMotion.resolve(context, AppMotion.normal),
        curve: AppMotion.standard,
        builder: (context, value, child) {
          return CustomPaint(
            painter: _CountdownRingPainter(progress: value),
            child: child,
          );
        },
        child: Center(
          child: SizedBox(
            width: AppComponentSize.countdownInnerWidth,
            height: AppComponentSize.countdownInnerHeight,
            child: Center(
              child: Text(
                timeText,
                style: AppTypography.timerStyle.copyWith(
                  fontSize: AppTypography.headline,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StateBadge extends StatelessWidget {
  const _StateBadge({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final icon = state == AppState.conclusao
        ? Icons.check_rounded
        : Icons.timer_outlined;
    final color = state == AppState.conclusao
        ? AppColorTokens.success
        : AppColorTokens.accent;

    return Container(
      width: AppComponentSize.stateBadge,
      height: AppComponentSize.stateBadge,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: AppColorTokens.border),
      ),
      child: Icon(icon, color: color, size: AppTypography.display),
    );
  }
}

class _CountdownRingPainter extends CustomPainter {
  const _CountdownRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - AppComponentSize.progressStroke;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppComponentSize.progressStroke
      ..strokeCap = StrokeCap.round
      ..color = AppColorTokens.progressTrack;
    canvas.drawCircle(center, radius, track);

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppComponentSize.progressStroke
      ..strokeCap = StrokeCap.round
      ..color = AppColorTokens.accent;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false, ring);
  }

  @override
  bool shouldRepaint(_CountdownRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
