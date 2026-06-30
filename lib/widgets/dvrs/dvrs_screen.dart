import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/dvrs_assessment.dart';
import '../../models/dvrs_definitions.dart';
import '../../services/dvrs_engine.dart';
import '../../services/dvrs_storage_service.dart';
import '../liquid_glass.dart';
import 'dvrs_history_view.dart';
import 'dvrs_result_view.dart';
import 'dvrs_ui.dart';

/// Sub-telas do fluxo do DVRS.
enum _DvrsView { intro, questions, review, result, history }

/// Tela principal do **DVRS — Índice de Risco Visual Digital**.
///
/// Orquestra todo o fluxo: introdução → 16 perguntas (uma por vez) → revisão →
/// resultado → histórico. É o único questionário principal do app. Linguagem
/// sempre educativa e de triagem.
class DvrsScreen extends StatefulWidget {
  const DvrsScreen({
    super.key,
    required this.onClose,
    this.onExportPdf,
  });

  /// Volta para a tela anterior (fecha o questionário).
  final VoidCallback onClose;

  /// Exporta o resultado no relatório PDF. Quando `null`, o botão de exportar
  /// não é exibido.
  final Future<void> Function(DvrsResult result)? onExportPdf;

  @override
  State<DvrsScreen> createState() => _DvrsScreenState();
}

class _DvrsScreenState extends State<DvrsScreen> {
  _DvrsView _view = _DvrsView.intro;

  /// Índice da opção escolhida por pergunta (`null` = não respondida).
  final Map<String, int> _selected = {};

  /// Índice da pergunta atual (0..15).
  int _index = 0;

  DvrsResult? _result;
  bool _saved = false;

  bool get _allAnswered => _selected.length == kDvrsQuestions.length;

  // --- Navegação ----------------------------------------------------------

  void _start() => setState(() {
        _index = 0;
        _view = _DvrsView.questions;
      });

  void _next() {
    if (_index < kDvrsQuestions.length - 1) {
      setState(() => _index++);
    } else {
      setState(() => _view = _DvrsView.review);
    }
  }

  void _back() {
    if (_index > 0) {
      setState(() => _index--);
    } else {
      setState(() => _view = _DvrsView.intro);
    }
  }

  void _calculate() {
    if (!_allAnswered) return;
    final answers = <DvrsAnswer>[
      for (final q in kDvrsQuestions)
        DvrsAnswer(
          questionId: q.id,
          domain: q.domain,
          value: q.options[_selected[q.id]!].score,
          label: q.options[_selected[q.id]!].label,
        ),
    ];
    final now = DateTime.now();
    final result = evaluateDvrs(
      answers: answers,
      id: now.millisecondsSinceEpoch.toString(),
      now: now,
    );
    setState(() {
      _result = result;
      _saved = false;
      _view = _DvrsView.result;
    });
  }

  void _restart() => setState(() {
        _selected.clear();
        _index = 0;
        _result = null;
        _saved = false;
        _view = _DvrsView.intro;
      });

  Future<void> _save() async {
    final result = _result;
    if (result == null || _saved) return;
    final storage = context.read<DvrsStorageService>();
    final messenger = ScaffoldMessenger.of(context);
    await storage.saveDvrsResult(result);
    if (!mounted) return;
    setState(() => _saved = true);
    messenger.showSnackBar(const SnackBar(content: Text('Resultado salvo.')));
  }

  Future<void> _exportPdf() async {
    final result = _result;
    final handler = widget.onExportPdf;
    if (result == null || handler == null) return;
    final storage = context.read<DvrsStorageService>();
    // Salva (marcado para PDF) antes de exportar.
    final toSave = result.copyWith(includeInPdf: true);
    await storage.saveDvrsResult(toSave);
    if (!mounted) return;
    setState(() {
      _result = toSave;
      _saved = true;
    });
    await handler(toSave);
  }

  // --- Build --------------------------------------------------------------

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
              Expanded(child: _body(theme)),
            ],
          ),
        ),
      ),
    );
  }

  String get _headerTitle {
    switch (_view) {
      case _DvrsView.history:
        return 'Histórico do DVRS';
      default:
        return 'Índice de Risco Visual Digital — DVRS';
    }
  }

  void _onHeaderBack() {
    switch (_view) {
      case _DvrsView.intro:
        widget.onClose();
        break;
      case _DvrsView.questions:
        _back();
        break;
      case _DvrsView.review:
        setState(() {
          _index = kDvrsQuestions.length - 1;
          _view = _DvrsView.questions;
        });
        break;
      case _DvrsView.result:
      case _DvrsView.history:
        setState(() => _view = _DvrsView.intro);
        break;
    }
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
              onPressed: _onHeaderBack,
              tooltip: 'Voltar',
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _headerTitle,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );

  Widget _body(ThemeData theme) {
    switch (_view) {
      case _DvrsView.intro:
        return _introView(theme);
      case _DvrsView.questions:
        return _questionsView(theme);
      case _DvrsView.review:
        return _reviewView(theme);
      case _DvrsView.result:
        return _resultScreen(theme);
      case _DvrsView.history:
        return const DvrsHistoryView();
    }
  }

  // --- Intro --------------------------------------------------------------

  Widget _introView(ThemeData theme) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Índice de Risco Visual Digital',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Ferramenta educativa de triagem e acompanhamento · período '
            'avaliado: $kDvrsPeriodLabel',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          Text(kDvrsIntroDescription,
              style: const TextStyle(fontSize: 14, height: 1.4)),
          const SizedBox(height: 16),
          DvrsUi.disclaimerBanner(theme, text: kDvrsIntroDisclaimer),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _start,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Iniciar DVRS'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _view = _DvrsView.history),
              icon: const Icon(Icons.history, size: 18),
              label: const Text('Ver histórico'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );

  // --- Perguntas (uma por vez) -------------------------------------------

  Widget _questionsView(ThemeData theme) {
    final q = kDvrsQuestions[_index];
    final selected = _selected[q.id];
    final total = kDvrsQuestions.length;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pergunta ${_index + 1} de $total',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_index + 1) / total,
                  minHeight: 6,
                  backgroundColor:
                      theme.colorScheme.onSurface.withValues(alpha: 0.08),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                q.title,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(q.text, style: const TextStyle(fontSize: 14, height: 1.4)),
              const SizedBox(height: 20),
              for (var i = 0; i < q.options.length; i++) ...[
                _optionTile(theme, q.options[i].label, selected == i, () {
                  setState(() => _selected[q.id] = i);
                }),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
        _questionsFooter(theme, selected != null),
      ],
    );
  }

  Widget _optionTile(
    ThemeData theme,
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    final color = theme.colorScheme.primary;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: 0.12)
                  : theme.colorScheme.surface.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? color
                    : theme.colorScheme.onSurface.withValues(alpha: 0.12),
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: selected
                      ? color
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.3,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _questionsFooter(ThemeData theme, bool canAdvance) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _back,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Voltar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: canAdvance ? _next : null,
                icon: Icon(
                  _index == kDvrsQuestions.length - 1
                      ? Icons.fact_check_outlined
                      : Icons.arrow_forward,
                  size: 18,
                ),
                label: Text(
                  _index == kDvrsQuestions.length - 1 ? 'Revisar' : 'Próxima',
                ),
              ),
            ),
          ],
        ),
      );

  // --- Revisão ------------------------------------------------------------

  Widget _reviewView(ThemeData theme) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Revise suas respostas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Toque em uma resposta para alterá-la antes de calcular.',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < kDvrsQuestions.length; i++)
            _reviewRow(theme, i),
          const SizedBox(height: 16),
          if (!_allAnswered)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Responda todas as 16 perguntas para calcular o resultado.',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _allAnswered ? _calculate : null,
              icon: const Icon(Icons.calculate_outlined),
              label: const Text('Calcular resultado'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );

  Widget _reviewRow(ThemeData theme, int i) {
    final q = kDvrsQuestions[i];
    final sel = _selected[q.id];
    final answerLabel = sel == null ? 'Sem resposta' : q.options[sel].label;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() {
        _index = i;
        _view = _DvrsView.questions;
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 26,
              child: Text(
                '${i + 1}.',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(q.title, style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(
                    answerLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: sel == null
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit_outlined,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  // --- Resultado ----------------------------------------------------------

  Widget _resultScreen(ThemeData theme) {
    final result = _result!;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        DvrsResultView(result: result),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: _saved ? null : _save,
            icon: const Icon(Icons.save_alt),
            label: Text(_saved ? 'Salvo' : 'Salvar resultado'),
            style: FilledButton.styleFrom(
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 46,
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _view = _DvrsView.history),
            icon: const Icon(Icons.history, size: 18),
            label: const Text('Ver histórico'),
          ),
        ),
        if (widget.onExportPdf != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 46,
            child: OutlinedButton.icon(
              onPressed: _exportPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: const Text('Exportar no PDF'),
            ),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          height: 46,
          child: OutlinedButton.icon(
            onPressed: _restart,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Refazer'),
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
