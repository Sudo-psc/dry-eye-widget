import 'package:flutter/material.dart';

import 'design_tokens.dart';
import 'glass_card.dart';
import 'progress_ring.dart';

/// KPI compacto: valor grande + rótulo, com anel de progresso ou ícone.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.ringValue,
    this.icon,
    this.color,
    this.footer,
  });

  final String label;
  final String value;

  /// Quando definido (0..1), mostra um [ProgressRing] à esquerda.
  final double? ringValue;
  final IconData? icon;
  final Color? color;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.primary;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (ringValue != null)
                ProgressRing(
                  value: ringValue!,
                  size: 48,
                  strokeWidth: 5,
                  color: accent,
                  child: Icon(icon ?? Icons.check, size: 18, color: accent),
                )
              else if (icon != null)
                Icon(icon, size: 28, color: accent),
              if (ringValue != null || icon != null) const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: AppTypography.headline,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                        letterSpacing: -0.35,
                      ),
                    ),
                    const SizedBox(height: AppSpace.x1),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: AppTypography.supporting,
                        color: AppColorTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (footer != null) ...[const SizedBox(height: AppSpace.x3), footer!],
        ],
      ),
    );
  }
}
