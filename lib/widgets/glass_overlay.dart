import 'package:flutter/material.dart';

import '../models/app_state.dart';
import '../utils/constants.dart';
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
    required this.secondsRemaining,
    this.fillOpacity = 0.15,
    this.blur = 20.0,
  });

  final AppState state;
  final int secondsRemaining;

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
          Text(
            state.title,
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
            state.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          if (state.showsCountdown) ...[
            const SizedBox(height: 24),
            TimerDisplay(secondsRemaining: secondsRemaining),
          ],
        ],
      ),
    );
  }
}
