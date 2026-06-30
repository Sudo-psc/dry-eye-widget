import 'package:flutter/material.dart';

import '../../models/dvrs_assessment.dart';
import '../../models/dvrs_definitions.dart';
import 'dvrs_ui.dart';

/// Exibe o conteúdo de um [DvrsResult] (sem botões de ação): score,
/// classificação, barra de risco, scores por domínio, mensagem educativa e
/// alerta de segurança. Reutilizável na tela de resultado e no histórico.
class DvrsResultView extends StatelessWidget {
  const DvrsResultView({super.key, required this.result, this.showDate = false});

  final DvrsResult result;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = DvrsUi.classificationColor(result.classification);
    final safety =
        DvrsUi.safetyBanner(result.safetyAlertLevel, result.safetyAlertMessage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          theme,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showDate) ...[
                Text(
                  DvrsUi.formatDate(result.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${result.totalScore}',
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                      height: 1,
                      color: color,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6, left: 2),
                    child: Text(
                      '/100',
                      style: TextStyle(
                        fontSize: 16,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  const Spacer(),
                  DvrsUi.classificationChip(result.classification),
                ],
              ),
              const SizedBox(height: 12),
              DvrsUi.riskBar(result.classification, result.totalScore),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _card(
          theme,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Scores por domínio',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              for (final domain in DvrsDomain.values) ...[
                _domainBar(theme, domain, result.domainScores.valueFor(domain)),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _card(
          theme,
          child: Text(
            result.educationalMessage,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
        ),
        if (safety != null) ...[
          const SizedBox(height: 16),
          safety,
        ],
        const SizedBox(height: 16),
        DvrsUi.disclaimerBanner(theme),
      ],
    );
  }

  Widget _card(ThemeData theme, {required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
        child: child,
      );

  Widget _domainBar(ThemeData theme, DvrsDomain domain, double value) {
    final pct = value.clamp(0.0, 100.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                kDvrsDomainLabels[domain] ?? domain.id,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            Text(
              '${pct.round()}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct / 100,
            minHeight: 7,
            backgroundColor:
                theme.colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
      ],
    );
  }
}
