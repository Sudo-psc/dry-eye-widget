import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/feature_strings.dart';
import '../../models/dvrs_assessment.dart';
import '../../models/dvrs_definitions.dart';
import '../../providers/settings_provider.dart';
import '../../services/dvrs_engine.dart';
import '../../services/dvrs_storage_service.dart';
import '../../ui/glass_card.dart';
import '../../ui/panel_state_view.dart';
import '../../ui/section_header.dart';
import '../../ui/trend_line_chart.dart';
import 'dvrs_ui.dart';

/// Histórico longitudinal do DVRS: último resultado, variação, gráfico de
/// evolução do score, evolução por domínio e lista de resultados (com exclusão).
class DvrsHistoryView extends StatefulWidget {
  const DvrsHistoryView({super.key});

  @override
  State<DvrsHistoryView> createState() => _DvrsHistoryViewState();
}

class _DvrsHistoryViewState extends State<DvrsHistoryView> {
  List<DvrsResult> _history = const [];
  DvrsDomain _selectedDomain = DvrsDomain.symptoms;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final storage = context.read<DvrsStorageService>();
    setState(() => _history = storage.getDvrsHistory());
  }

  Future<void> _confirmDelete(String id) async {
    final f = FeatureStrings.of(
      context.read<SettingsProvider>().value.languageCode,
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(f.dvrsDeleteConfirmTitle),
        content: Text(f.dvrsDeleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(f.dvrsDeleteCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(f.dvrsDeleteConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final storage = context.read<DvrsStorageService>();
    await storage.deleteDvrsResult(id);
    if (!mounted) return;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_history.isEmpty) {
      final f = FeatureStrings.of(
        context.read<SettingsProvider>().value.languageCode,
      );
      return Padding(
        padding: const EdgeInsets.all(32),
        child: PanelStateView(
          icon: Icons.assignment_outlined,
          title: f.stateDvrsEmptyTitle,
          message: f.stateDvrsEmptyMessage,
        ),
      );
    }

    final latest = _history.last;
    final previous = _history.length >= 2
        ? _history[_history.length - 2]
        : null;
    final trend = previous == null ? null : compareDvrsTrend(previous, latest);
    final delta = previous == null
        ? null
        : latest.totalScore - previous.totalScore;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _latestCard(theme, latest, trend, delta),
        if (previous != null) ...[
          const SizedBox(height: 16),
          _domainCompareCard(theme, previous, latest),
        ],
        const SizedBox(height: 16),
        _chartCard(
          title: context.read<SettingsProvider>().strings.dvrsHistoryEvolution,
          points: [
            for (final r in _history) (r.createdAt, r.totalScore.toDouble()),
          ],
        ),
        const SizedBox(height: 16),
        _domainEvolutionCard(),
        const SizedBox(height: 16),
        _historyListCard(theme),
        const SizedBox(height: 16),
        GlassCard(
          child: Row(
            children: [
              Icon(
                Icons.event_repeat,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Refaça o DVRS semanalmente ou mensalmente para acompanhar a '
                  'evolução do seu risco visual digital.',
                  style: TextStyle(fontSize: 13, height: 1.35),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _latestCard(
    ThemeData theme,
    DvrsResult latest,
    DvrsTrend? trend,
    int? delta,
  ) {
    final color = DvrsUi.classificationColor(latest.classification);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Último DVRS · ${DvrsUi.formatDate(latest.createdAt)}',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${latest.totalScore}',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  height: 1,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '/100',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const Spacer(),
              DvrsUi.classificationChip(latest.classification),
            ],
          ),
          if (trend != null && delta != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  DvrsUi.trendIcon(trend),
                  size: 16,
                  color: DvrsUi.trendColor(trend),
                ),
                const SizedBox(width: 6),
                Text(
                  '${DvrsUi.trendLabel(trend)} (${delta > 0 ? '+' : ''}$delta '
                  'desde o anterior)',
                  style: TextStyle(
                    fontSize: 12,
                    color: DvrsUi.trendColor(trend),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _chartCard({
    required String title,
    required List<(DateTime, double)> points,
  }) {
    final f = FeatureStrings.of(
      context.read<SettingsProvider>().value.languageCode,
    );
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title),
          TrendLineChart(points: points, minY: 0, maxY: 100, height: 160),
          if (points.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final p in points)
                  Tooltip(
                    message: f.dvrsTooltipScore
                        .replaceAll('{score}', p.$2.round().toString())
                        .replaceAll('{date}', DvrsUi.formatDate(p.$1)),
                    child: Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(
                        '${p.$2.round()} · ${DvrsUi.formatDate(p.$1)}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _domainCompareCard(
    ThemeData theme,
    DvrsResult previous,
    DvrsResult latest,
  ) {
    final f = FeatureStrings.of(
      context.read<SettingsProvider>().value.languageCode,
    );
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(f.dvrsDomainCompare),
          const SizedBox(height: 8),
          for (final d in DvrsDomain.values)
            _domainDeltaRow(
              theme,
              label: kDvrsDomainLabels[d] ?? d.id,
              prev: previous.domainScores.valueFor(d),
              next: latest.domainScores.valueFor(d),
            ),
        ],
      ),
    );
  }

  Widget _domainDeltaRow(
    ThemeData theme, {
    required String label,
    required double prev,
    required double next,
  }) {
    final delta = next - prev;
    final color = delta > 1
        ? const Color(0xFFE57373)
        : delta < -1
        ? const Color(0xFF81C784)
        : theme.colorScheme.onSurface.withValues(alpha: 0.55);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            child: Text(
              prev.round().toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
          const Icon(Icons.arrow_forward, size: 14),
          Expanded(
            child: Text(
              next.round().toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              '${delta >= 0 ? '+' : ''}${delta.round()}',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _domainEvolutionCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader('Evolução por domínio'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final d in DvrsDomain.values)
                ChoiceChip(
                  label: Text(
                    kDvrsDomainLabels[d] ?? d.id,
                    style: const TextStyle(fontSize: 11),
                  ),
                  selected: _selectedDomain == d,
                  onSelected: (_) => setState(() => _selectedDomain = d),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TrendLineChart(
            points: [
              for (final r in _history)
                (r.createdAt, r.domainScores.valueFor(_selectedDomain)),
            ],
            minY: 0,
            maxY: 100,
            height: 140,
          ),
        ],
      ),
    );
  }

  Widget _historyListCard(ThemeData theme) {
    final reversed = _history.reversed.toList();
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader('Resultados'),
          for (final r in reversed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 34,
                    child: Text(
                      '${r.totalScore}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: DvrsUi.classificationColor(r.classification),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.classificationLabel,
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          DvrsUi.formatDate(r.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: ValueKey<String>('dvrs_delete_${r.id}'),
                    icon: const Icon(Icons.delete_outline, size: 20),
                    tooltip: context
                        .read<SettingsProvider>()
                        .strings
                        .dvrsHistoryDelete,
                    onPressed: () => _confirmDelete(r.id),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
