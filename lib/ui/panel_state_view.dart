import 'package:flutter/material.dart';

import 'app_theme.dart';

enum PanelStateTone { empty, unavailable, success, error }

/// Estado padronizado para painéis do Hub.
///
/// Cor nunca é o único sinal: todos os estados incluem ícone, título e texto.
class PanelStateView extends StatelessWidget {
  const PanelStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.tone = PanelStateTone.empty,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final PanelStateTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>();
    final color = switch (tone) {
      PanelStateTone.empty => theme.colorScheme.onSurfaceVariant,
      PanelStateTone.unavailable => theme.colorScheme.primary,
      PanelStateTone.success => semantic?.success ?? Colors.green,
      PanelStateTone.error => theme.colorScheme.error,
    };
    final live = tone == PanelStateTone.success || tone == PanelStateTone.error;

    return Semantics(
      container: true,
      liveRegion: live,
      label: '$title. $message',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(compact ? 14 : 24),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: color.withValues(alpha: 0.28)),
            ),
            child: compact
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, color: color, size: 22),
                      const SizedBox(width: 12),
                      Expanded(child: _copy(theme, color)),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: color, size: 40),
                      const SizedBox(height: 14),
                      _copy(theme, color, centered: true),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _copy(ThemeData theme, Color color, {bool centered = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          message,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
            height: 1.35,
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: onAction,
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: Text(actionLabel!),
          ),
        ],
      ],
    );
  }
}
