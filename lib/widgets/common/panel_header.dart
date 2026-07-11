import 'package:flutter/material.dart';

import '../../utils/constants.dart';

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
        border: const Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 14, 6),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(leadingIcon),
                  onPressed: onLeading,
                  tooltip: leadingTooltip,
                  style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (trailing != null)
                  trailing!
                else if (trailingIcon != null)
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.idleBall.withValues(alpha: 0.16),
                    ),
                    child: Icon(
                      trailingIcon,
                      color: AppColors.idleBall,
                      size: 20,
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
