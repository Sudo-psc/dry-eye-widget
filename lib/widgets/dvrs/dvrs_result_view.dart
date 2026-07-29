import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/feature_strings.dart';
import '../../models/dvrs_assessment.dart';
import '../../providers/settings_provider.dart';
import '../../ui/glass_card.dart';
import '../../ui/section_header.dart';
import 'dvrs_ui.dart';

/// Exibe o perfil educativo por domínio sem apresentar o total como escore
/// clínico ou classificação validada.
class DvrsResultView extends StatelessWidget {
  const DvrsResultView({
    super.key,
    required this.result,
    this.showDate = false,
  });

  final DvrsResult result;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final f = FeatureStrings.of(
      context.watch<SettingsProvider>().value.languageCode,
    );
    final safety = DvrsUi.safetyBanner(
      result.safetyAlertLevel,
      f.dvrsSafetyMessage(result.safetyAlertLevel),
      semanticLabel: f.dvrsSafetyAlertLabel,
    );

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
              Text(
                f.dvrsResultTitle,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                f.dvrsResultNote,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(f.dvrsDomainProfile),
              for (final domain in DvrsDomain.values) ...[
                _domainBar(
                  theme,
                  domain,
                  result.domainScores.valueFor(domain),
                  f.dvrsDomainLabel(domain.id),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Text(
            f.dvrsPublicMessage(DvrsPublicMessageKey.domainFollowUp),
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
        ),
        if (safety != null) ...[const SizedBox(height: 16), safety],
        const SizedBox(height: 16),
        DvrsUi.disclaimerBanner(theme, text: f.dvrsDisclaimer),
      ],
    );
  }

  Widget _domainBar(
    ThemeData theme,
    DvrsDomain domain,
    double value,
    String label,
  ) {
    final pct = value.clamp(0.0, 100.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
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
              backgroundColor: theme.colorScheme.onSurface.withValues(
                alpha: 0.08,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
