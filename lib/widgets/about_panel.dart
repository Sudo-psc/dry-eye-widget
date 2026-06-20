import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../utils/constants.dart';
import 'liquid_glass.dart';

/// Janela "Sobre": identifica o app, a versão atual e a autoria responsável.
/// Renderizada como painel interno (mesmo padrão de [GuidanceDialog]), pois um
/// `showDialog` numa janela do tamanho da bolinha não tem espaço para aparecer.
class AboutPanel extends StatelessWidget {
  const AboutPanel({super.key, required this.strings, required this.onClose});

  final AppStrings strings;
  final VoidCallback onClose;

  Widget build(BuildContext context) {
    final s = strings;
    return LiquidGlass(
      width: 420,
      constraints: const BoxConstraints(maxHeight: 560),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.idleBall),
                  const SizedBox(width: 8),
                  Text(
                    s.menuAbout,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textPrimary),
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dry Eye Widget',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Versão ${AppInfo.version}',
                    style: const TextStyle(
                      color: AppColors.idleBall,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    s.aboutDescription,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13.5,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Divider(color: AppColors.glassBorder),
                  const SizedBox(height: 12),
                  Text(
                    s.aboutAuthorLabel,
                    style: const TextStyle(
                      color: AppColors.idleBall,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Dr. Philipe Saraiva Cruz',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.aboutAuthorRole,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'RQE 71.903 · CRM-MG 69.870 · CRM-SP 204.923',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Instagram: @drphilipesaraiva',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
