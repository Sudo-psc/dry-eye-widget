import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/update_service.dart';
import '../utils/constants.dart';
import 'liquid_glass.dart';

/// Mostra o resultado da verificação de atualização.
/// [result] é `null` enquanto a verificação está em andamento.
class UpdateDialog extends StatelessWidget {
  const UpdateDialog({
    super.key,
    required this.strings,
    required this.result,
    required this.onClose,
    required this.onDownload,
  });

  final AppStrings strings;
  final UpdateResult? result;
  final VoidCallback onClose;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    IconData icon;
    Color iconColor;
    String message;
    final available = result?.status == UpdateStatus.available;

    if (result == null) {
      icon = Icons.sync;
      iconColor = AppColors.idleBall;
      message = s.updateChecking;
    } else {
      switch (result!.status) {
        case UpdateStatus.upToDate:
          icon = Icons.check_circle_outline;
          iconColor = const Color(0xFF50C878);
          message = s.updateUpToDate;
          break;
        case UpdateStatus.available:
          icon = Icons.system_update_alt;
          iconColor = AppColors.idleBall;
          message = s.updateAvailable
              .replaceAll('{v}', result!.latestVersion ?? '');
          break;
        case UpdateStatus.error:
          icon = Icons.error_outline;
          iconColor = AppColors.alertBall;
          message = s.updateError;
          break;
      }
    }

    return Center(
      child: LiquidGlass(
        width: 360,
        borderRadius: 22,
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: iconColor),
            const SizedBox(height: 14),
            const Text(
              'Dry Eye Widget ${AppInfo.version}',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(onPressed: onClose, child: Text(s.close)),
                if (available) ...[
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: onDownload,
                    icon: const Icon(Icons.download, size: 18),
                    label: Text(s.updateDownload),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
