import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/feature_strings.dart';
import '../../models/dvrs_assessment.dart';
import '../../providers/settings_provider.dart';
import '../../services/dvrs_storage_service.dart';
import '../../ui/glass_card.dart';
import '../../ui/panel_state_view.dart';
import '../../ui/section_header.dart';
import '../../ui/trend_line_chart.dart';
import 'dvrs_ui.dart';

/// Histórico longitudinal do DVRS por domínio e lista de registros.
///
/// O total numérico legado continua no modelo para compatibilidade dos dados,
/// mas não é apresentado como escore clínico nesta superfície educativa.
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
    final settings = context.watch<SettingsProvider>();
    final f = FeatureStrings.of(settings.value.languageCode);
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
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _latestCard(theme, latest),
        if (previous != null) ...[
          const SizedBox(height: 16),
          _domainCompareCard(theme, previous, latest),
        ],
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
              Expanded(
                child: Text(
                  f.dvrsRetakeHint,
                  style: TextStyle(fontSize: 13, height: 1.35),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _latestCard(ThemeData theme, DvrsResult latest) {
    final f = FeatureStrings.of(
      context.read<SettingsProvider>().value.languageCode,
    );
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            f.dvrsLatest(DvrsUi.formatDate(latest.createdAt)),
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            f.dvrsEducationalProfile,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            f.dvrsHistoryIntro,
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
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
              label: f.dvrsDomainLabel(d.id),
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
    final color = delta.abs() > 1
        ? theme.colorScheme.primary
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
              'Δ ${delta >= 0 ? '+' : ''}${delta.round()}',
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
    final settings = context.read<SettingsProvider>();
    final f = FeatureStrings.of(settings.value.languageCode);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(settings.strings.dvrsHistoryEvolution),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final d in DvrsDomain.values)
                ChoiceChip(
                  label: Text(
                    f.dvrsDomainLabel(d.id),
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
    final f = FeatureStrings.of(
      context.read<SettingsProvider>().value.languageCode,
    );
    final reversed = _history.reversed.toList();
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(f.dvrsHistoryResults),
          for (final r in reversed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f.dvrsHistoryRecord,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
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
