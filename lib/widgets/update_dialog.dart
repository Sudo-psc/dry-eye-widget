import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
            // Instruções de instalação no macOS: o build não é notarizado, então
            // o usuário precisa liberar o .dmg com o comando antes de abrir.
            if (available && Platform.isMacOS) ...[
              const SizedBox(height: 16),
              _MacInstallBox(strings: s),
            ],
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

/// Bloco com o passo a passo de instalação no macOS e o comando para liberar
/// o .dmg (com botão de copiar).
class _MacInstallBox extends StatelessWidget {
  const _MacInstallBox({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.terminal,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  s.updateMacInstallTitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            s.updateMacInstallSteps,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          _CommandBox(
            command: AppInfo.macUnblockCommand,
            copyLabel: s.updateCopyCommand,
            copiedLabel: s.updateCommandCopied,
          ),
        ],
      ),
    );
  }
}

/// Comando em destaque com botão de copiar; mostra confirmação temporária.
class _CommandBox extends StatefulWidget {
  const _CommandBox({
    required this.command,
    required this.copyLabel,
    required this.copiedLabel,
  });

  final String command;
  final String copyLabel;
  final String copiedLabel;

  @override
  State<_CommandBox> createState() => _CommandBoxState();
}

class _CommandBoxState extends State<_CommandBox> {
  bool _copied = false;
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.command));
    if (!mounted) return;
    setState(() => _copied = true);
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
        color: const Color(0x47000000),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: SelectableText(
              widget.command,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontFamily: 'monospace',
                fontSize: 12.5,
              ),
            ),
          ),
          const SizedBox(width: 6),
          TextButton.icon(
            onPressed: _copy,
            icon: Icon(_copied ? Icons.check : Icons.copy, size: 16),
            label: Text(_copied ? widget.copiedLabel : widget.copyLabel),
            style: TextButton.styleFrom(
              foregroundColor:
                  _copied ? const Color(0xFF50C878) : AppColors.idleBall,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}
