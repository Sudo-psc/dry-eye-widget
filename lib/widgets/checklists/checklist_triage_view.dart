import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/checklist.dart';
import '../../services/checklist_engine.dart';
import '../../services/checklist_storage_service.dart';
import '../../services/screen_time_service.dart';
import '../../services/storage_service.dart';
import '../liquid_glass.dart';
import 'checklist_ui.dart';

/// Módulo 6: triagem oftalmológica.
///
/// Cruza OSDI mais recente, sintomas, sinais de alerta, tempo de tela médio e
/// adesão a pausas, chamando [buildTriage]. Exibe a mensagem educativa + aviso
/// e permite salvar.
class ChecklistTriageView extends StatefulWidget {
  const ChecklistTriageView({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  State<ChecklistTriageView> createState() => _ChecklistTriageViewState();
}

class _ChecklistTriageViewState extends State<ChecklistTriageView> {
  ChecklistResult? _result;

  // Dados coletados (para exibir o que entrou na triagem).
  double? _osdi;
  int? _avgScreenSeconds;
  double? _adherence;
  ChecklistResult? _symptoms;
  ChecklistResult? _warningSigns;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runTriage());
  }

  /// Tempo médio de tela (segundos/dia) dos últimos 30 dias com uso > 0.
  int? _averageScreenSeconds(ScreenTimeService screenTime) {
    final series = screenTime.data.dailySeries(DateTime.now(), 30);
    final active = series.where((p) => p.seconds > 0).toList();
    if (active.isEmpty) return null;
    final total = active.fold<int>(0, (sum, p) => sum + p.seconds);
    return (total / active.length).round();
  }

  /// Adesão a pausas (concluídas / lembretes) nos últimos 30 dias.
  double? _breakAdherence(StorageService storage) {
    final now = DateTime.now();
    final stat = storage
        .loadBreakStats()
        .sumForRange(now.subtract(const Duration(days: 29)), now);
    if (stat.reminders == 0) return null;
    return stat.completed / stat.reminders;
  }

  void _runTriage() {
    final storage = context.read<StorageService>();
    final screenTime = context.read<ScreenTimeService>();
    final checklistStorage = context.read<ChecklistStorageService>();

    final osdi = storage.loadOsdiHistory().lastOrNull?.score;
    final avgScreen = _averageScreenSeconds(screenTime);
    final adherence = _breakAdherence(storage);
    final symptoms =
        checklistStorage.latestByType(ChecklistType.visualSymptoms);
    final warningSigns =
        checklistStorage.latestByType(ChecklistType.warningSigns);

    final result = buildTriage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      now: DateTime.now(),
      latestOsdiScore: osdi,
      symptoms: symptoms,
      warningSigns: warningSigns,
      avgScreenSecondsPerDay: avgScreen,
      breakAdherence: adherence,
    );

    if (!mounted) return;
    setState(() {
      _osdi = osdi;
      _avgScreenSeconds = avgScreen;
      _adherence = adherence;
      _symptoms = symptoms;
      _warningSigns = warningSigns;
      _result = result;
    });
  }

  Future<void> _save() async {
    final result = _result;
    if (result == null) return;
    final messenger = ScaffoldMessenger.of(context);
    await context.read<ChecklistStorageService>().saveChecklistResult(result);
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Resultado da triagem salvo.')),
    );
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
                child: _result == null
                    ? const Center(child: CircularProgressIndicator())
                    : _body(theme, _result!),
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
                'Triagem oftalmológica',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );

  Widget _body(ThemeData theme, ChecklistResult result) {
    final inputs = <(String, String)>[];
    if (_osdi != null) {
      inputs.add(('Escore OSDI mais recente', _osdi!.toStringAsFixed(1)));
    }
    if (_avgScreenSeconds != null) {
      inputs.add(('Tempo médio de tela/dia', _durationLabel(_avgScreenSeconds!)));
    }
    if (_adherence != null) {
      inputs.add((
        'Adesão às pausas',
        '${(_adherence! * 100).toStringAsFixed(0)}%',
      ));
    }
    if (_symptoms != null) {
      inputs.add(('Sintomas visuais', _symptoms!.classification));
    }
    if (_warningSigns != null) {
      inputs.add(('Sinais de alerta', _warningSigns!.classification));
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Combina os dados disponíveis (sintomas, escore e exposição) para '
          'uma orientação educativa.',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ChecklistUi.riskChip(result.riskLevel),
              const SizedBox(height: 12),
              Text(
                result.classification,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(result.feedback, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dados considerados',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (inputs.isEmpty)
                Text(
                  'Ainda não há dados suficientes. Preencha os checklists de '
                  'sintomas e de sinais de alerta para uma triagem mais '
                  'completa.',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                )
              else
                ...inputs.map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            e.$1,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          e.$2,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ChecklistUi.disclaimerBanner(theme, text: kTriageDisclaimer),
        const SizedBox(height: 24),
        SizedBox(
          height: 50,
          child: FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_alt),
            label: const Text('Salvar resultado'),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
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

  String _durationLabel(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${minutes}min';
    return '${minutes}min';
  }
}
