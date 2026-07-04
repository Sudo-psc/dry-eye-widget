import 'package:flutter/material.dart';

import '../../models/dvrs_assessment.dart';
import '../../models/dvrs_definitions.dart';
import '../../ui/glass_card.dart';
import '../../ui/section_header.dart';
import '../../ui/score_gauge.dart';
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
        GlassCard(
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
              Center(
                child: ScoreGauge(
                  score: result.totalScore,
                  color: color,
                  segments: DvrsUi.classificationSegments,
                ),
              ),
              const SizedBox(height: 10),
              Center(child: DvrsUi.classificationChip(result.classification)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader('Scores por domínio'),
              for (final domain in DvrsDomain.values) ...[
                _domainBar(theme, domain, result.domainScores.valueFor(domain)),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
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
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: pct / 100),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: v,
              minHeight: 7,
              backgroundColor:
                  theme.colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
        ),
      ],
    );
  }
}
