import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../utils/constants.dart';
import 'dropper_animation.dart';
import 'liquid_glass.dart';

/// Aviso de "hora do colírio": frasco pingando uma gota, mensagem e botão de
/// confirmação. Exibido quando o timer oculto do colírio completa.
class EyeDropsReminder extends StatelessWidget {
  const EyeDropsReminder({
    super.key,
    required this.strings,
    required this.onDone,
  });

  final AppStrings strings;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LiquidGlass(
        width: 360,
        borderRadius: 22,
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DropperAnimation(size: 110),
            const SizedBox(height: 10),
            Text(
              strings.eyeDropsTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              strings.eyeDropsBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onDone,
              child: Text(strings.eyeDropsDone),
            ),
          ],
        ),
      ),
    );
  }
}
