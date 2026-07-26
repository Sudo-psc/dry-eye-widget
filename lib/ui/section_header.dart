import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// Título de seção padronizado (14/w600) com espaço para ação à direita.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpace.x3),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: AppTypography.body,
              fontWeight: FontWeight.w600,
              color: AppColorTokens.textPrimary,
            ),
          ),
        ),
        if (trailing != null) trailing as Widget,
      ],
    ),
  );
}
