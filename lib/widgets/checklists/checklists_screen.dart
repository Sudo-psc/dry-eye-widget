import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/checklist.dart';
import '../../services/checklist_storage_service.dart';
import '../liquid_glass.dart';
import 'checklist_history_view.dart';
import 'checklist_run_dialog.dart';
import 'checklist_triage_view.dart';
import 'checklist_ui.dart';
import 'visual_risk_summary_view.dart';

/// Tela principal "Checklists": 7 cards de saúde visual digital.
///
/// Módulos 1–5 abrem um questionário ([ChecklistRunDialog]); o módulo 6 abre a
/// triagem ([ChecklistTriageView]); o módulo 7 abre o resumo
/// ([VisualRiskSummaryView]). Toda a linguagem é educativa e de triagem.
class ChecklistsScreen extends StatefulWidget {
  const ChecklistsScreen({super.key, required this.onClose});

  /// Volta para a bolinha (fecha o painel inteiro).
  final VoidCallback onClose;

  @override
  State<ChecklistsScreen> createState() => _ChecklistsScreenState();
}

/// Descrição estática de um card da grade.
class _CardSpec {
  const _CardSpec({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
  });

  final ChecklistType type;
  final String title;
  final String description;
  final IconData icon;
}

const List<_CardSpec> _cards = [
  _CardSpec(
    type: ChecklistType.visualErgonomics,
    title: 'Ergonomia visual',
    description:
        'Avalie distância, altura, brilho, reflexos e conforto do posto de '
        'trabalho.',
    icon: Icons.desktop_windows_outlined,
  ),
  _CardSpec(
    type: ChecklistType.screenEnvironment,
    title: 'Ambiente de tela',
    description:
        'Revise ar-condicionado, umidade, iluminação e fatores ambientais.',
    icon: Icons.air_outlined,
  ),
  _CardSpec(
    type: ChecklistType.visualSymptoms,
    title: 'Sintomas visuais',
    description:
        'Registre frequência de ardência, secura, embaçamento e fadiga.',
    icon: Icons.remove_red_eye_outlined,
  ),
  _CardSpec(
    type: ChecklistType.warningSigns,
    title: 'Sinais de alerta',
    description:
        'Identifique sintomas que merecem avaliação oftalmológica.',
    icon: Icons.warning_amber_outlined,
  ),
  _CardSpec(
    type: ChecklistType.breakHabits,
    title: 'Pausas e hábitos',
    description:
        'Avalie sua adesão à regra 20-20-20 e pausas visuais.',
    icon: Icons.timer_outlined,
  ),
  _CardSpec(
    type: ChecklistType.ophthalmologyTriage,
    title: 'Triagem oftalmológica',
    description:
        'Combine sintomas, score e exposição para orientação educativa.',
    icon: Icons.medical_services_outlined,
  ),
  _CardSpec(
    type: ChecklistType.visualRiskSummary,
    title: 'Resumo de risco visual',
    description: 'Veja uma síntese do seu perfil atual.',
    icon: Icons.summarize_outlined,
  ),
];

class _ChecklistsScreenState extends State<ChecklistsScreen> {
  /// View interna ativa: `null` = grade de cards.
  Widget? _active;

  void _open(Widget view) => setState(() => _active = view);
  void _backToGrid() => setState(() => _active = null);

  void _onCardTap(ChecklistType type) {
    switch (type) {
      case ChecklistType.ophthalmologyTriage:
        _open(ChecklistTriageView(onClose: _backToGrid));
        break;
      case ChecklistType.visualRiskSummary:
        _open(VisualRiskSummaryView(onClose: _backToGrid));
        break;
      default:
        _open(ChecklistRunDialog(type: type, onClose: _onRunClosed));
    }
  }

  /// Ao fechar um questionário, recarrega a grade (para refletir o último
  /// resultado salvo) voltando à lista.
  void _onRunClosed() {
    _backToGrid();
  }

  @override
  Widget build(BuildContext context) {
    final active = _active;
    if (active != null) return active;

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
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const Text(
                      'Checklists rápidos e educativos para acompanhar sua '
                      'saúde visual digital. Não substituem consulta médica.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    for (final spec in _cards) ...[
                      _card(theme, spec),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
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
                'Checklists',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );

  Widget _card(ThemeData theme, _CardSpec spec) {
    // Para módulos 1–5, mostra o último risco + data salvos (se houver).
    ChecklistResult? latest;
    final isQuestionnaire = spec.type != ChecklistType.ophthalmologyTriage &&
        spec.type != ChecklistType.visualRiskSummary;
    if (isQuestionnaire) {
      latest = context.read<ChecklistStorageService>().latestByType(spec.type);
    }

    return Semantics(
      button: true,
      label: '${spec.title}. ${spec.description}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _onCardTap(spec.type),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(spec.icon, color: theme.colorScheme.primary, size: 26),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        spec.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        spec.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.8),
                        ),
                      ),
                      if (latest != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            ChecklistUi.riskChip(latest.riskLevel, dense: true),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'em ${ChecklistUi.formatDate(latest.createdAt)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.history, size: 18),
                              tooltip: 'Histórico',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _open(
                                ChecklistHistoryView(
                                  type: spec.type,
                                  title: spec.title,
                                  onClose: _backToGrid,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
