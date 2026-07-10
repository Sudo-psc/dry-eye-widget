import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/app_state.dart';
import '../ui/breathing_circle.dart';
import '../ui/progress_ring.dart';
import '../utils/constants.dart';
import 'blinking_eye.dart';
import 'liquid_glass.dart';
import 'timer_display.dart';

/// Overlay central de "vidro líquido" exibido durante alerta e pausas.
///
/// Usa [BackdropFilter] para o desfoque e anima a entrada/saída com fade.
/// A troca de texto entre as fases é feita com [AnimatedSwitcher].
class GlassOverlay extends StatelessWidget {
  const GlassOverlay({
    super.key,
    required this.state,
    required this.strings,
    required this.secondsRemaining,
    required this.phaseTotalSeconds,
    this.currentStreak = 0,
    this.completionInsight = '',
    this.fillOpacity = 0.15,
    this.blur = 20.0,
  });

  final AppState state;
  final AppStrings strings;
  final int secondsRemaining;
  final int phaseTotalSeconds;
  final int currentStreak;

  /// Insight proativo local exibido na conclusão da pausa (pode ser vazio).
  final String completionInsight;

  /// Opacidade do preenchimento branco do vidro.
  final double fillOpacity;

  /// Intensidade do desfoque de fundo.
  final double blur;

  @override
  Widget build(BuildContext context) {
    final visible = state.isActive;

    return IgnorePointer(
      // Não bloqueia cliques quando invisível (estado IDLE).
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: AppDurations.fade,
        curve: Curves.easeInOut,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.overlayMaxWidth,
              minWidth: 240,
            ),
            child: LiquidGlass(
              dark: false,
              blur: blur,
              fillOpacity: fillOpacity,
              borderRadius: 24,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: _buildContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return AnimatedSwitcher(
      duration: AppDurations.fade,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: Column(
        // A key garante que o switcher anime quando o estado muda.
        key: ValueKey(state),
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.showsCountdown) ...[
            Stack(
              alignment: Alignment.center,
              children: [
                const BreathingCircle(size: 150),
                const BlinkingEye(size: 96),
              ],
            ),
            const SizedBox(height: 16),
          ],
          Text(
            strings.stateTitle(state),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            strings.stateSubtitle(state),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          if (state == AppState.conclusao) ...[
            const SizedBox(height: 16),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              builder: (context, v, child) =>
                  Transform.scale(scale: v, child: child),
              child: const Icon(Icons.check_circle,
                  size: 44, color: AppColors.textPrimary),
            ),
            if (currentStreak >= 2) ...[
              const SizedBox(height: 10),
              Text(
                // Localizado: reusa o helper existente do "Meu Progresso"
                // (ex.: "5 dias" / "5 days").
                '🔥 ${strings.progressDaysCount(currentStreak)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
            if (completionInsight.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                completionInsight,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary.withValues(alpha: 0.9),
                ),
              ),
            ],
          ],
          if (state.showsCountdown) ...[
            const SizedBox(height: 24),
            ProgressRing(
              value: phaseTotalSeconds <= 0
                  ? 0
                  : 1 - secondsRemaining / phaseTotalSeconds,
              size: 118,
              strokeWidth: 5,
              color: Colors.white,
              child: TimerDisplay(secondsRemaining: secondsRemaining),
            ),
          ],
        ],
      ),
    );
  }
}
