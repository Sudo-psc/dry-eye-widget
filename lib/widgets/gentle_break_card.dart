import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_strings.dart';
import '../models/app_state.dart';
import '../utils/constants.dart';
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
  });

  final AppState state;
  final AppStrings strings;
  final int secondsRemaining;
  final int totalSeconds;

  String get _timeText {
    final m = (secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final s = (secondsRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LiquidGlass(
          width: 404,
          borderRadius: 24,
          blur: 26,
          fillOpacity: 0.82,
          padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _BreakLabel(),
                    const SizedBox(height: 8),
                    Text(
                      strings.stateTitle(state),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      strings.stateSubtitle(state),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        height: 1.22,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
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
    );
  }
}

class _BreakLabel extends StatelessWidget {
  const _BreakLabel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          colors: [
            AppColors.idleBall.withValues(alpha: 0.38),
            AppColors.alertBall.withValues(alpha: 0.34),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          '20-20-20',
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.92),
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
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
      dimension: 96,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: progress, end: progress),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return CustomPaint(
            painter: _CountdownRingPainter(progress: value),
            child: child,
          );
        },
        child: Center(
          child: Container(
            width: 76,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.18),
                  Colors.white.withValues(alpha: 0.06),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.idleBall.withValues(alpha: 0.14),
                  blurRadius: 18,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Text(
              timeText,
              style: GoogleFonts.robotoMono(
                color: AppColors.textPrimary,
                fontSize: 21,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
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
        ? const Color(0xFF50C878)
        : AppColors.idleBall;

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.36),
            color.withValues(alpha: 0.10),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Icon(icon, color: Colors.white.withValues(alpha: 0.92), size: 30),
    );
  }
}

class _CountdownRingPainter extends CustomPainter {
  const _CountdownRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 5;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.14);
    canvas.drawCircle(center, radius, track);

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7)
      ..shader = const SweepGradient(
        startAngle: -1.5708,
        endAngle: 4.7124,
        colors: [
          AppColors.idleBall,
          Color(0xFF50C878),
          AppColors.alertBall,
          AppColors.idleBall,
        ],
      ).createShader(rect);
    canvas.drawArc(rect, -1.5708, 6.2832 * progress, false, glow);

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        startAngle: -1.5708,
        endAngle: 4.7124,
        colors: [
          AppColors.idleBall,
          Color(0xFF50C878),
          AppColors.alertBall,
          AppColors.idleBall,
        ],
      ).createShader(rect);
    canvas.drawArc(rect, -1.5708, 6.2832 * progress, false, ring);
  }

  @override
  bool shouldRepaint(_CountdownRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
