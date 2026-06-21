import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/checklist.dart';
import '../../services/checklist_engine.dart';
import '../../services/checklist_storage_service.dart';
import '../../services/screen_time_service.dart';
import '../../services/storage_service.dart';
import '../liquid_glass.dart';
import 'checklist_ui.dart';

/// Módulo 7: resumo de risco visual.
///
/// Agrega os últimos resultados de cada módulo + OSDI + tempo de tela + adesão
/// chamando [buildVisualRiskSummary]. Mostra cards por indicador (ícone + texto
/// + cor) e a frase-resumo. Tom educativo, não-alarmista.
class VisualRiskSummaryView extends StatefulWidget {
  const VisualRiskSummaryView({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  State<VisualRiskSummaryView> createState() => _VisualRiskSummaryViewState();
}

class _VisualRiskSummaryViewState extends State<VisualRiskSummaryView> {
  VisualRiskSummary? _summary;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _build());
  }

  int? _averageScreenSeconds(ScreenTimeService screenTime) {
    final series = screenTime.data.dailySeries(DateTime.now(), 30);
    final active = series.where((p) => p.seconds > 0).toList();
    if (active.isEmpty) return null;
    final total = active.fold<int>(0, (sum, p) => sum + p.seconds);
    return (total / active.length).round();
  }

  double? _breakAdherence(StorageService storage) {
    final now = DateTime.now();
    final stat = storage
        .loadBreakStats()
        .sumForRange(now.subtract(const Duration(days: 29)), now);
    if (stat.reminders == 0) return null;
    return stat.completed / stat.reminders;
  }

  void _build() {
    final storage = context.read<StorageService>();
    final screenTime = context.read<ScreenTimeService>();
    final checklistStorage = context.read<ChecklistStorageService>();

    final symptoms =
        checklistStorage.latestByType(ChecklistType.visualSymptoms);
    // Tendência de sintomas (último x penúltimo), quando houver histórico.
    final symptomHistory =
        checklistStorage.getChecklistHistory(type: ChecklistType.visualSymptoms);
    ChecklistTrend? trend;
    if (symptomHistory.length >= 2) {
      trend = compareChecklistTrend(
        symptomHistory[symptomHistory.length - 2],
        symptomHistory.last,
      );
    }

    final summary = buildVisualRiskSummary(
      now: DateTime.now(),
      ergonomics:
          checklistStorage.latestByType(ChecklistType.visualErgonomics),
      environment:
          checklistStorage.latestByType(ChecklistType.screenEnvironment),
      symptoms: symptoms,
      warningSigns:
          checklistStorage.latestByType(ChecklistType.warningSigns),
      breakHabits: checklistStorage.latestByType(ChecklistType.breakHabits),
      latestOsdiScore: storage.loadOsdiHistory().lastOrNull?.score,
      avgScreenSecondsPerDay: _averageScreenSeconds(screenTime),
      breakAdherence: _breakAdherence(storage),
      trend: trend,
    );

    if (!mounted) return;
    setState(() => _summary = summary);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: LiquidGlass(
          fillOpacity: 0.8,
          blur: 20,
          child: Column(
            children: [
              _header(theme),
              Expanded(
                child: _summary == null
                    ? const Center(child: CircularProgressIndicator())
                    : _body(theme, _summary!),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(ThemeData theme) => Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.5),
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: widget.onClose,
              tooltip: 'Voltar',
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Resumo de risco visual',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );

  Widget _body(ThemeData theme, VisualRiskSummary s) {
    final indicators = <(String, ChecklistRiskLevel?)>[
      ('Ergonomia visual', s.ergonomicRisk),
      ('Ambiente de tela', s.environmentRisk),
      ('Sintomas visuais', s.symptomsRisk),
      ('Sinais de alerta', s.warningSignsRisk),
      ('Pausas e hábitos', s.breakAdherenceRisk),
      ('Tempo de tela', s.screenTimeRisk),
    ];

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Panorama geral.
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Panorama geral',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ChecklistUi.riskChip(s.overallLevel),
                ],
              ),
              const SizedBox(height: 12),
              Text(s.summaryText, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              Text(
                s.recommendation,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (s.trend != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      ChecklistUi.trendIcon(s.trend!),
                      size: 18,
                      color: ChecklistUi.trendColor(s.trend!),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Tendência dos sintomas: ${ChecklistUi.trendLabel(s.trend!)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: ChecklistUi.trendColor(s.trend!),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Indicadores',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 12),
        for (final ind in indicators) ...[
          _indicatorCard(theme, ind.$1, ind.$2),
          const SizedBox(height: 8),
        ],
        if (s.latestOsdiScore != null) ...[
          _osdiCard(theme, s.latestOsdiScore!),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 16),
        ChecklistUi.disclaimerBanner(theme),
        const SizedBox(height: 24),
        SizedBox(
          height: 44,
          child: OutlinedButton(
            onPressed: widget.onClose,
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Voltar'),
          ),
        ),
      ],
    );
  }

  Widget _indicatorCard(ThemeData theme, String label, ChecklistRiskLevel? level) {
    if (level == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.remove_circle_outline,
              size: 18,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 14)),
            ),
            Text(
              'Sem dados',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }
    final color = ChecklistUi.riskColor(level);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(ChecklistUi.riskIcon(level), size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            ChecklistUi.riskLabel(level),
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _osdiCard(ThemeData theme, double score) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Escore OSDI mais recente',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            Text(
              score.toStringAsFixed(1),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
}
