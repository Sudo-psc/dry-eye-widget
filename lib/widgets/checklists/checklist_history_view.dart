import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/checklist.dart';
import '../../services/checklist_engine.dart';
import '../../services/checklist_storage_service.dart';
import '../liquid_glass.dart';
import 'checklist_ui.dart';

/// Histórico de um tipo de checklist (módulos 1–5): lista os resultados com
/// comparação último x anterior ([compareChecklistTrend]) e exclusão.
class ChecklistHistoryView extends StatefulWidget {
  const ChecklistHistoryView({
    super.key,
    required this.type,
    required this.title,
    required this.onClose,
  });

  final ChecklistType type;
  final String title;
  final VoidCallback onClose;

  @override
  State<ChecklistHistoryView> createState() => _ChecklistHistoryViewState();
}

class _ChecklistHistoryViewState extends State<ChecklistHistoryView> {
  List<ChecklistResult> _history = const [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final storage = context.read<ChecklistStorageService>();
    setState(() {
      _history = storage.getChecklistHistory(type: widget.type);
    });
  }

  Future<void> _delete(ChecklistResult result) async {
    await context.read<ChecklistStorageService>().deleteChecklistResult(
          result.id,
        );
    if (!mounted) return;
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Mais recente primeiro.
    final items = _history.reversed.toList();
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
                child: items.isEmpty
                    ? _empty(theme)
                    : _list(theme, items),
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
            Expanded(
              child: Text(
                'Histórico — ${widget.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _empty(ThemeData theme) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Você ainda não preencheu este checklist. Os resultados aparecerão '
            'aqui para acompanhar a evolução ao longo do tempo.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      );

  Widget _list(ThemeData theme, List<ChecklistResult> items) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final result = items[index];
        // O anterior cronológico é o próximo na lista invertida.
        final previous = index + 1 < items.length ? items[index + 1] : null;
        final trend = compareChecklistTrend(previous, result);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ChecklistUi.formatDate(result.createdAt),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      tooltip: 'Excluir',
                      onPressed: () => _delete(result),
                    ),
                  ],
                ),
                ChecklistUi.riskChip(result.riskLevel, dense: true),
                const SizedBox(height: 8),
                Text(
                  result.classification,
                  style: const TextStyle(fontSize: 14),
                ),
                if (trend != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        ChecklistUi.trendIcon(trend),
                        size: 16,
                        color: ChecklistUi.trendColor(trend),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Em relação ao anterior: ${ChecklistUi.trendLabel(trend)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: ChecklistUi.trendColor(trend),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
