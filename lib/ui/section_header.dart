import 'package:flutter/material.dart';

/// Título de seção padronizado (14/w600) com espaço para ação à direita.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            if (trailing != null) trailing as Widget,
          ],
        ),
      );
}
