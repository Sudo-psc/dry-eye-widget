import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/checklist.dart';
import '../../models/checklist_definitions.dart';
import '../../services/checklist_engine.dart';
import '../../services/checklist_storage_service.dart';
import '../liquid_glass.dart';
import 'checklist_ui.dart';

/// Fluxo genérico de um checklist (módulos 1–5): perguntas → cálculo →
/// resultado → salvar / incluir no PDF.
///
/// Toda a linguagem é educativa e de triagem, nunca diagnóstica.
class ChecklistRunDialog extends StatefulWidget {
  const ChecklistRunDialog({
    super.key,
    required this.type,
    required this.onClose,
  });

  /// Tipo de checklist (deve existir em [kChecklistDefinitions]).
  final ChecklistType type;

  /// Volta para a tela anterior.
  final VoidCallback onClose;

  @override
  State<ChecklistRunDialog> createState() => _ChecklistRunDialogState();
}

class _ChecklistRunDialogState extends State<ChecklistRunDialog> {
  late final ChecklistDefinition _def;

  /// Índice da opção escolhida por pergunta (`null` = ainda não respondida).
  late final Map<String, int> _selected;

  ChecklistResult? _result;
  bool _saved = false;
  bool _includedInPdf = false;

  @override
  void initState() {
    super.initState();
    _def = kChecklistDefinitions[widget.type]!;
    _selected = <String, int>{};
  }

  bool get _allAnswered => _selected.length == _def.questions.length;

  List<ChecklistAnswer> _buildAnswers() {
    final answers = <ChecklistAnswer>[];
    for (final q in _def.questions) {
      final idx = _selected[q.id];
      if (idx == null) continue;
      answers.add(
        ChecklistAnswer(
          questionId: q.id,
          score: q.options[idx].score,
          optionIndex: idx,
        ),
      );
    }
    return answers;
  }

  void _calculate() {
    final answers = _buildAnswers();
    final result = evaluate(
      def: _def,
      answers: answers,
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      now: DateTime.now(),
    );
    setState(() {
      _result = result;
      _saved = false;
      _includedInPdf = false;
    });
  }

  Future<void> _save({required bool includeInPdf}) async {
    final result = _result;
    if (result == null) return;
    final storage = context.read<ChecklistStorageService>();
    final messenger = ScaffoldMessenger.of(context);
    final toSave = result.copyWith(includeInPdf: includeInPdf);
    await storage.saveChecklistResult(toSave);
    if (!mounted) return;
    setState(() {
      _result = toSave;
      _saved = true;
      _includedInPdf = includeInPdf;
    });
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          includeInPdf
              ? 'Resultado salvo e marcado para incluir no PDF.'
              : 'Resultado salvo.',
        ),
      ),
    );
  }

  void _restart() {
    setState(() {
      _selected.clear();
      _result = null;
      _saved = false;
      _includedInPdf = false;
    });
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
                    ? _questionsView(theme)
                    : _resultView(theme, _result!),
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
                _def.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

  // --- Perguntas ----------------------------------------------------------

  Widget _questionsView(ThemeData theme) {
    final useSegmented = _def.questions.first.options.length <= 2;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(_def.shortDescription, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 16),
        ChecklistUi.disclaimerBanner(theme),
        const SizedBox(height: 20),
        for (var i = 0; i < _def.questions.length; i++) ...[
          _questionCard(theme, _def.questions[i], i + 1, useSegmented),
          const SizedBox(height: 16),
        ],
        if (!_allAnswered)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Algumas informações ainda não foram preenchidas. O resultado '
              'é apenas uma estimativa educativa.',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        SizedBox(
          height: 50,
          child: FilledButton.icon(
            onPressed: _selected.isEmpty ? null : _calculate,
            icon: const Icon(Icons.calculate_outlined),
            label: const Text('Calcular resultado'),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: OutlinedButton(
            onPressed: widget.onClose,
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Refazer depois'),
          ),
        ),
      ],
    );
  }

  Widget _questionCard(
    ThemeData theme,
    ChecklistQuestion q,
    int number,
    bool useSegmented,
  ) {
    final selected = _selected[q.id];
    return Container(
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
          Text(
            '$number. ${q.text}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (useSegmented)
            _segmentedOptions(q, selected)
          else
            _radioOptions(q, selected),
        ],
      ),
    );
  }

  Widget _segmentedOptions(ChecklistQuestion q, int? selected) {
    return Semantics(
      label: 'Resposta para: ${q.text}',
      child: SegmentedButton<int>(
        emptySelectionAllowed: true,
        segments: [
          for (var i = 0; i < q.options.length; i++)
            ButtonSegment<int>(value: i, label: Text(q.options[i].label)),
        ],
        selected: selected == null ? <int>{} : {selected},
        onSelectionChanged: (sel) {
          if (sel.isEmpty) return;
          setState(() => _selected[q.id] = sel.first);
        },
      ),
    );
  }

  Widget _radioOptions(ChecklistQuestion q, int? selected) {
    return RadioGroup<int>(
      groupValue: selected,
      onChanged: (v) {
        if (v == null) return;
        setState(() => _selected[q.id] = v);
      },
      // Material transparente: o RadioListTile pinta splashes no Material mais
      // próximo; sem ele, o Container com cor de fundo dispara assertion.
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            for (var i = 0; i < q.options.length; i++)
              RadioListTile<int>(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: i,
                title: Text(
                  q.options[i].label,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- Resultado ----------------------------------------------------------

  Widget _resultView(ThemeData theme, ChecklistResult result) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
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
        if (!_allAnswered) ...[
          const SizedBox(height: 12),
          Text(
            'Algumas informações ainda não foram preenchidas. O resultado é '
            'apenas uma estimativa educativa.',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
        const SizedBox(height: 16),
        ChecklistUi.disclaimerBanner(theme),
        const SizedBox(height: 24),
        SizedBox(
          height: 50,
          child: FilledButton.icon(
            onPressed: _saved && !_includedInPdf
                ? null
                : () => _save(includeInPdf: false),
            icon: const Icon(Icons.save_alt),
            label: Text(_saved ? 'Salvo' : 'Salvar'),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: FilledButton.tonalIcon(
            onPressed:
                _includedInPdf ? null : () => _save(includeInPdf: true),
            icon: Icon(
              _includedInPdf
                  ? Icons.check_circle_outline
                  : Icons.picture_as_pdf_outlined,
            ),
            label: Text(
              _includedInPdf ? 'Incluído no PDF' : 'Incluir no PDF',
            ),
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
          child: OutlinedButton.icon(
            onPressed: _restart,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Refazer'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: TextButton(
            onPressed: widget.onClose,
            child: const Text('Refazer depois'),
          ),
        ),
      ],
    );
  }
}
