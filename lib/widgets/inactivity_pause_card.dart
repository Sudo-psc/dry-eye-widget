import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../ui/app_theme.dart';
import '../utils/constants.dart';
import 'liquid_glass.dart';

/// Aviso compacto exibido quando o ciclo é pausado por inatividade do sistema.
///
/// Discreto e não bloqueante (canto superior direito): mostra um título curto,
/// uma frase explicando que o ciclo será retomado ao voltar, e um botão pequeno
/// de retomada manual ([onResume]). Sem som, sem overlay escuro, sem tela cheia.
class InactivityPauseCard extends StatelessWidget {
  const InactivityPauseCard({
    super.key,
    required this.strings,
    required this.onResume,
  });

  final AppStrings strings;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Semantics(
          container: true,
          liveRegion: true,
          label: '${strings.inactivityTitle}. ${strings.inactivityBody}',
          child: LiquidGlass(
            borderRadius: AppRadii.md,
            blur: 18,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.idleBall.withValues(alpha: 0.18),
                    border: Border.all(
                      color: AppColors.idleBall.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Icon(
                    Icons.pause_circle_outline,
                    color: AppColors.idleBall,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.inactivityTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        strings.inactivityBody,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.28,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: onResume,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.idleBall,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    minimumSize: const Size(44, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                  ),
                  child: Text(
                    strings.inactivityContinue,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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
