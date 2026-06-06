import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_state.dart';
import '../utils/constants.dart';

/// Cartão compacto de pausa para o "modo suave": aparece no canto superior
/// direito sem bloquear o restante da tela. Mostra a mensagem da fase e, nas
/// fases com cronômetro, o tempo restante.
class GentleBreakCard extends StatelessWidget {
  const GentleBreakCard({
    super.key,
    required this.state,
    required this.secondsRemaining,
  });

  final AppState state;
  final int secondsRemaining;

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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xF21E1E1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.glassBorder, width: 1),
                boxShadow: const [
                  BoxShadow(color: AppColors.glassShadow, blurRadius: 16),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.visibility_outlined,
                      color: AppColors.alertBall, size: 26),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                        if (state.showsCountdown) ...[
                          const SizedBox(height: 4),
                          Text(
                            _timeText,
                            style: GoogleFonts.robotoMono(
                              color: AppColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
