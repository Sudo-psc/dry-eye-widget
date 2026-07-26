import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/app_state.dart';
import '../ui/app_theme.dart';
import '../ui/progress_ring.dart';
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
    this.fillOpacity = AppDepth.lightOpacity,
    this.blur = AppDepth.blur,
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
    final duration = AppMotion.resolve(context, AppMotion.normal);

    return IgnorePointer(
      // Não bloqueia cliques quando invisível (estado IDLE).
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: duration,
        curve: AppMotion.standard,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppComponentSize.overlayMaxWidth,
              minWidth: AppComponentSize.overlayMinWidth,
            ),
            child: Semantics(
              key: const ValueKey('cycle_live_region'),
              container: true,
              liveRegion: true,
              label: strings.stateTitle(state),
              child: LiquidGlass(
                blur: blur,
                fillOpacity: fillOpacity,
                borderRadius: AppRadii.xl,
                padding: const EdgeInsets.all(AppSpace.x3),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColorTokens.surfaceRaised,
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                    border: Border.all(color: AppColorTokens.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.x6,
                      vertical: AppSpace.x8,
                    ),
                    child: _buildContent(context),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final duration = AppMotion.resolve(context, AppMotion.normal);
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: AppMotion.standard,
      switchOutCurve: AppMotion.standard,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: Column(
        // A key garante que o switcher anime quando o estado muda.
        key: ValueKey(state),
        mainAxisSize: MainAxisSize.min,
        children: [
          _StateMark(state: state),
          const SizedBox(height: AppSpace.x4),
          Text(
            strings.stateTitle(state),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTypography.family,
              fontSize: AppTypography.headline,
              fontWeight: FontWeight.w700,
              color: AppColorTokens.textPrimary,
              height: 1.2,
              letterSpacing: -0.35,
            ),
          ),
          const SizedBox(height: AppSpace.x2),
          Text(
            strings.stateSubtitle(state),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTypography.family,
              fontSize: AppTypography.body,
              color: AppColorTokens.textSecondary,
              height: 1.45,
            ),
          ),
          if (state == AppState.conclusao) ...[
            if (currentStreak >= 2) ...[
              const SizedBox(height: AppSpace.x3),
              Text(
                // Localizado: reusa o helper existente do "Meu Progresso"
                // (ex.: "5 dias" / "5 days").
                '🔥 ${strings.progressDaysCount(currentStreak)}',
                style: const TextStyle(
                  fontFamily: AppTypography.family,
                  fontSize: AppTypography.supporting,
                  fontWeight: FontWeight.w600,
                  color: AppColorTokens.textPrimary,
                ),
              ),
            ],
            if (completionInsight.isNotEmpty) ...[
              const SizedBox(height: AppSpace.x3),
              Text(
                completionInsight,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTypography.family,
                  fontSize: AppTypography.supporting,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                  color: AppColorTokens.textSecondary,
                ),
              ),
            ],
          ],
          if (state.showsCountdown) ...[
            const SizedBox(height: AppSpace.x6),
            ProgressRing(
              value: phaseTotalSeconds <= 0
                  ? 0
                  : 1 - secondsRemaining / phaseTotalSeconds,
              size: AppComponentSize.overlayProgress,
              strokeWidth: AppComponentSize.progressStroke,
              color: AppColorTokens.accent,
              child: TimerDisplay(secondsRemaining: secondsRemaining),
            ),
          ],
        ],
      ),
    );
  }
}

class _StateMark extends StatelessWidget {
  const _StateMark({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final completed = state == AppState.conclusao;
    final icon = completed ? Icons.check_rounded : Icons.visibility_outlined;
    final color = completed ? AppColorTokens.success : AppColorTokens.accent;
    return Container(
      width: AppComponentSize.minimumTarget,
      height: AppComponentSize.minimumTarget,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: AppColorTokens.border),
      ),
      child: Icon(icon, color: color, size: AppTypography.headline),
    );
  }
}
