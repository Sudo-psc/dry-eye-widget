import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Card translúcido padrão do app (vidro sobre o LiquidGlass das telas).
/// Substitui os antigos `_card()` duplicados por tela.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColorTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: onTap,
        focusColor: AppColorTokens.accent.withValues(alpha: 0.12),
        hoverColor: AppColorTokens.accent.withValues(alpha: 0.08),
        child: card,
      ),
    );
  }
}
