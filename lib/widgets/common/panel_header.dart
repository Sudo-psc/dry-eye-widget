import 'package:flutter/material.dart';

import '../../ui/design_tokens.dart';

/// Cabeçalho unificado de painéis (Resumo, Progresso, DVRS, Dashboard, etc.).
///
/// Padrão visual: fundo levemente elevado, divisor sutil, botão de 44×44,
/// título em w700 e ícone/ação opcional à direita.
class PanelHeader extends StatelessWidget {
  const PanelHeader({
    super.key,
    required this.title,
    required this.onLeading,
    required this.leadingTooltip,
    this.leadingIcon = Icons.close_rounded,
    this.trailingIcon,
    this.trailing,
    this.bottom,
  });

  final String title;
  final VoidCallback onLeading;
  final String leadingTooltip;
  final IconData leadingIcon;

  /// Ícone decorativo à direita (ex.: sol no Resumo do dia).
  final IconData? trailingIcon;

  /// Widget custom à direita (tem prioridade sobre [trailingIcon]).
  final Widget? trailing;

  /// Conteúdo abaixo da linha principal (ex.: TabBar do Dashboard).
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.55),
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.x1,
              AppSpace.x2,
              AppSpace.x4,
              AppSpace.x2,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(leadingIcon),
                  onPressed: onLeading,
                  tooltip: leadingTooltip,
                  style: IconButton.styleFrom(
                    minimumSize: const Size.square(
                      AppComponentSize.minimumTarget,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.x1),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppTypography.title,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.25,
                      color: AppColorTokens.textPrimary,
                    ),
                  ),
                ),
                if (trailing != null)
                  trailing!
                else if (trailingIcon != null)
                  Container(
                    width: AppComponentSize.panelBadge,
                    height: AppComponentSize.panelBadge,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColorTokens.accent.withValues(alpha: 0.14),
                    ),
                    child: Icon(
                      trailingIcon,
                      color: AppColorTokens.accent,
                      size: AppComponentSize.icon,
                    ),
                  ),
              ],
            ),
          ),
          ?bottom,
        ],
      ),
    );
  }
}
