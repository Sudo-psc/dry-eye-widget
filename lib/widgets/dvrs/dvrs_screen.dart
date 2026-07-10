import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/dvrs_assessment.dart';
import '../../models/dvrs_definitions.dart';
import '../../providers/settings_provider.dart';
import '../../services/dvrs_engine.dart';
import '../../services/dvrs_storage_service.dart';
import '../liquid_glass.dart';
import 'dvrs_history_view.dart';
import 'dvrs_result_view.dart';
import 'dvrs_ui.dart';

/// Sub-telas do fluxo do DVRS.
enum _DvrsView { intro, questions, result, history }

/// Tela principal do **DVRS — Índice de Risco Visual Digital**.
///
/// Orquestra todo o fluxo: introdução → página única de perguntas → resultado
/// → histórico. É o único questionário principal do app. Linguagem sempre
/// educativa e de triagem.
class DvrsScreen extends StatefulWidget {
  const DvrsScreen({super.key, required this.onClose, this.onExportPdf});

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

  DvrsResult? _result;
  bool _saved = false;

  int get _answeredCount => _selected.length;

  bool get _allAnswered => _selected.length == kDvrsQuestions.length;

  // --- Navegação ----------------------------------------------------------

  void _start() => setState(() => _view = _DvrsView.questions);

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
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          context.read<SettingsProvider>().strings.dvrsResultSavedSnack,
        ),
      ),
    );
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
        setState(() => _view = _DvrsView.intro);
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
          tooltip: context.read<SettingsProvider>().strings.back,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _headerTitle,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
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
      Text(
        kDvrsIntroDescription,
        style: const TextStyle(fontSize: 14, height: 1.4),
      ),
      const SizedBox(height: 16),
      DvrsUi.disclaimerBanner(theme, text: kDvrsIntroDisclaimer),
      const SizedBox(height: 24),
      SizedBox(
        height: 52,
        child: FilledButton.icon(
          onPressed: _start,
          icon: const Icon(Icons.play_arrow),
          label: Text(context.read<SettingsProvider>().strings.dvrsStart),
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
          label: Text(context.read<SettingsProvider>().strings.dvrsViewHistory),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    ],
  );

  // --- Perguntas (página única) -------------------------------------------

  Widget _questionsView(ThemeData theme) {
    final total = kDvrsQuestions.length;
    final answered = _answeredCount;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$answered de $total respondidas',
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
                  value: answered / total,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.onSurface.withValues(
                    alpha: 0.08,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: kDvrsQuestions.length + 1,
            separatorBuilder: (_, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Text(
                  'Responda as 16 perguntas abaixo na mesma página. Role a '
                  'lista e calcule o resultado quando todas estiverem '
                  'marcadas.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                );
              }
              final questionIndex = index - 1;
              final question = kDvrsQuestions[questionIndex];
              return _questionCard(theme, question, questionIndex + 1);
            },
          ),
        ),
        _questionsFooter(theme, _allAnswered),
      ],
    );
  }

  Widget _questionCard(ThemeData theme, DvrsQuestion q, int questionNumber) {
    final selected = _selected[q.id];
    final domainColor = DvrsUi.domainColor(q.domain);
    return Container(
      key: ValueKey<String>('dvrs_question_${q.id}'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Pergunta $questionNumber',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: domainColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      DvrsUi.domainIcon(q.domain),
                      size: 14,
                      color: domainColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      kDvrsDomainLabels[q.domain] ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: domainColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            q.title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(q.text, style: const TextStyle(fontSize: 14, height: 1.4)),
          const SizedBox(height: 20),
          for (var i = 0; i < q.options.length; i++) ...[
            _optionTile(theme, q.options[i].label, selected == i, () {
              setState(() => _selected[q.id] = i);
            }),
            if (i < q.options.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
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
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
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

  Widget _questionsFooter(ThemeData theme, bool canCalculate) => Container(
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
            onPressed: () => setState(() => _view = _DvrsView.intro),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: Text(context.read<SettingsProvider>().strings.back),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: canCalculate ? _calculate : null,
            icon: const Icon(Icons.calculate_outlined, size: 18),
            label: Text(context.read<SettingsProvider>().strings.dvrsCalculate),
          ),
        ),
      ],
    ),
  );

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
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                _saved ? Icons.check_circle : Icons.save_alt,
                key: ValueKey(_saved),
              ),
            ),
            label: Text(_saved ? context.read<SettingsProvider>().strings.dvrsSaved : context.read<SettingsProvider>().strings.dvrsSaveResult),
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
            label: Text(context.read<SettingsProvider>().strings.dvrsViewHistory),
          ),
        ),
        if (widget.onExportPdf != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 46,
            child: OutlinedButton.icon(
              onPressed: _exportPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: Text(context.read<SettingsProvider>().strings.dvrsExportPdf),
            ),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          height: 46,
          child: OutlinedButton.icon(
            onPressed: _restart,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(context.read<SettingsProvider>().strings.dvrsRedo),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: TextButton(
            onPressed: widget.onClose,
            child: Text(context.read<SettingsProvider>().strings.dvrsRedoLater),
          ),
        ),
      ],
    );
  }
}
