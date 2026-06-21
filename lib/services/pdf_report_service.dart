import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/checklist.dart';
import '../models/environment_checklist.dart';
import '../models/osdi_assessment.dart';
import '../models/report_options.dart';

/// Gera o "Relatório de Saúde Visual Digital" em PDF.
///
/// Biblioteca escolhida: pacote `pdf` (+ `printing` para compartilhar/imprimir).
/// É a opção idiomática para Flutter desktop, gera o documento **localmente**
/// (sem servidor, alinhado à LGPD) e funciona offline em macOS/Windows/Linux.
class PdfReportService {
  static const String legalFooter =
      'Relatório gerado pelo Dry Eye Widget. Documento educativo e de triagem. '
      'Não constitui diagnóstico, prescrição ou substituição de avaliação '
      'oftalmológica. Em caso de sintomas persistentes, dor ocular, fotofobia, '
      'visão embaçada recorrente ou piora progressiva, procure um médico '
      'oftalmologista.';

  static const String osdiDisclaimer =
      'O escore OSDI é um instrumento de sintomas e não confirma diagnóstico '
      'isoladamente. Escores elevados, piora progressiva ou sintomas persistentes '
      'devem ser avaliados por um oftalmologista.';

  static const String mandatoryClosing =
      'Este relatório não substitui consulta médica. Ele organiza informações '
      'autorreferidas para facilitar o acompanhamento e a conversa com o '
      'oftalmologista.';

  static const String privacyNotice =
      'Este relatório pode conter informações pessoais de saúde. Compartilhe '
      'apenas com pessoas ou profissionais de sua confiança. O documento é '
      'gerado localmente no seu dispositivo e não é enviado a terceiros sem '
      'a sua ação explícita.';

  // --- Estilos (paleta discreta: azul escuro, cinza, branco) --------------

  static final _titleStyle = pw.TextStyle(
    color: PdfColors.blue900,
    fontSize: 22,
    fontWeight: pw.FontWeight.bold,
  );
  static final _headerStyle = pw.TextStyle(
    color: PdfColors.blueGrey800,
    fontSize: 15,
    fontWeight: pw.FontWeight.bold,
  );
  static const _textStyle = pw.TextStyle(color: PdfColors.black, fontSize: 11);
  static final _mutedStyle = _textStyle.copyWith(color: PdfColors.grey600);
  static final _italicStyle = _textStyle.copyWith(
    fontStyle: pw.FontStyle.italic,
    color: PdfColors.grey700,
  );

  // Fonte Unicode embutida (DejaVuSans) usada como *fallback*: a Helvetica
  // padrão cobre o português acentuado e tem negrito/itálico próprios, mas não
  // desenha símbolos fora do WinAnsi (em-dash, aspas curvas, etc.) que o
  // usuário pode colar nas observações. Carregada uma única vez.
  static pw.Font? _fallbackFont;
  static bool _fallbackAttempted = false;

  Future<List<pw.Font>> _loadFontFallback() async {
    if (!_fallbackAttempted) {
      _fallbackAttempted = true;
      try {
        final data = await rootBundle.load('assets/fonts/DejaVuSans.ttf');
        _fallbackFont = pw.Font.ttf(data);
      } catch (_) {
        _fallbackFont = null; // ambientes sem asset bundle (ex.: testes puros)
      }
    }
    return _fallbackFont == null ? const [] : [_fallbackFont!];
  }

  /// Gera o documento PDF em formato binário.
  Future<Uint8List> generateReport(ReportData data) async {
    final fallback = await _loadFontFallback();
    final pdf = pw.Document(
      title: 'Relatório de Saúde Visual Digital',
      author: 'Dry Eye Widget',
      theme: pw.ThemeData.withFont(fontFallback: fallback),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 48),
        footer: _buildFooter,
        build: (context) => [
          _buildHeader(data),
          pw.SizedBox(height: 16),
          _buildExecutiveSummary(data),
          pw.SizedBox(height: 20),
          if (data.options.includeOsdi) ...[
            _buildOsdiSection(context, data),
            pw.SizedBox(height: 20),
          ],
          if (data.options.includeSymptoms) ...[
            _buildSymptomsSection(context, data),
            pw.SizedBox(height: 20),
          ],
          if (data.options.includeScreenTime) ...[
            _buildScreenTimeSection(data),
            pw.SizedBox(height: 20),
          ],
          if (data.options.includeBreaks) ...[
            _buildBreaksSection(data),
            pw.SizedBox(height: 20),
          ],
          if (data.options.includeEnvironment && data.environment != null) ...[
            _buildEnvironmentSection(data.environment!),
            pw.SizedBox(height: 20),
          ],
          if (data.options.includeChecklists && data.checklists.isNotEmpty) ...[
            _buildChecklistsSection(context, data),
            pw.SizedBox(height: 20),
          ],
          _buildEvaluationSection(data),
          pw.SizedBox(height: 20),
          if (data.profile.hasObservations) ...[
            _buildObservationsSection(data),
            pw.SizedBox(height: 20),
          ],
          _buildPrivacySection(),
        ],
      ),
    );

    return pdf.save();
  }

  // --- Cabeçalho / identificação -----------------------------------------

  pw.Widget _buildHeader(ReportData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Relatório de Saúde Visual Digital', style: _titleStyle),
                pw.SizedBox(height: 2),
                pw.Text('Dry Eye Widget', style: _mutedStyle),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Emitido em ${_formatDate(data.generatedAt)}',
                    style: _mutedStyle),
                pw.Text(
                  'Período: ${_formatDate(data.options.startDate)} a ${_formatDate(data.options.endDate)}',
                  style: _mutedStyle,
                ),
              ],
            ),
          ],
        ),
        if (data.profile.hasName) ...[
          pw.SizedBox(height: 6),
          pw.Text('Usuário: ${data.profile.name}', style: _textStyle),
        ],
        pw.SizedBox(height: 8),
        pw.Divider(color: PdfColors.blueGrey200),
      ],
    );
  }

  // --- Resumo executivo ---------------------------------------------------

  pw.Widget _buildExecutiveSummary(ReportData data) {
    final rows = <List<String>>[];
    final osdi = data.osdi;
    if (data.options.includeOsdi) {
      rows.add([
        'Escore OSDI mais recente',
        osdi.latest == null
            ? 'Sem dados'
            : '${osdi.latest!.score.toStringAsFixed(1)} (${_severityLabel(osdi.latest!.severity)})',
      ]);
      final variation = osdi.variation;
      if (variation != null) {
        final pct = osdi.variationPercent;
        rows.add([
          'Variação no período',
          '${_signed(variation)} pontos'
              '${pct != null ? ' (${_signed(pct, decimals: 0)}%)' : ''}',
        ]);
      }
    }
    if (data.options.includeScreenTime) {
      rows.add([
        'Tempo médio de tela/dia',
        data.screenTime.hasData
            ? _formatDuration(data.screenTime.averageDailySeconds)
            : 'Sem dados',
      ]);
      rows.add([
        'Total de tela no período',
        data.screenTime.hasData
            ? _formatDuration(data.screenTime.totalSeconds)
            : 'Sem dados',
      ]);
    }
    if (data.options.includeBreaks) {
      rows.add([
        'Pausas concluídas',
        data.breaks.hasData
            ? '${data.breaks.completed} de ${data.breaks.reminders}'
            : 'Sem dados',
      ]);
      final adh = data.breaks.adherenceRate;
      rows.add([
        'Adesão às pausas',
        adh != null ? '${(adh * 100).toStringAsFixed(0)}%' : 'Sem dados',
      ]);
    }
    if (data.options.includeSymptoms) {
      final top = data.topSymptom;
      rows.add(['Sintoma mais frequente', top?.label ?? 'Sem registro']);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Resumo executivo', style: _headerStyle),
        pw.SizedBox(height: 8),
        _indicationBanner(data.indication),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Column(
            children: [
              for (final r in rows)
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(r[0], style: _textStyle),
                      pw.Text(r[1],
                          style: _textStyle.copyWith(
                              fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _indicationBanner(OverallIndication indication) {
    final (PdfColor bg, PdfColor fg, String label) = switch (indication) {
      OverallIndication.monitor => (
          PdfColors.green50,
          PdfColors.green900,
          'Indicação geral: acompanhar a evolução.',
        ),
      OverallIndication.reinforceBreaks => (
          PdfColors.amber50,
          PdfColors.orange900,
          'Indicação geral: reforçar as pausas visuais.',
        ),
      OverallIndication.seekEvaluation => (
          PdfColors.red50,
          PdfColors.red900,
          'Indicação geral: considere agendar avaliação oftalmológica.',
        ),
    };
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Text(label,
          style: pw.TextStyle(
              color: fg, fontSize: 12, fontWeight: pw.FontWeight.bold)),
    );
  }

  // --- OSDI ---------------------------------------------------------------

  pw.Widget _buildOsdiSection(pw.Context context, ReportData data) {
    final osdi = data.osdi;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('1. Escore OSDI', style: _headerStyle),
        pw.SizedBox(height: 8),
        if (!osdi.hasData)
          pw.Text('Ainda não há dados suficientes de OSDI neste período.',
              style: _textStyle)
        else ...[
          _buildOsdiChart(osdi.history),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            context: context,
            cellStyle: _textStyle,
            headerStyle:
                _textStyle.copyWith(fontWeight: pw.FontWeight.bold),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.blueGrey50),
            headers: const ['Data', 'Escore', 'Classificação'],
            data: osdi.history
                .map((e) => [
                      _formatDate(e.completedAt),
                      e.score.toStringAsFixed(1),
                      _severityLabel(e.severity),
                    ])
                .toList(),
          ),
        ],
        pw.SizedBox(height: 8),
        pw.Text(osdiDisclaimer, style: _italicStyle),
      ],
    );
  }

  /// Gráfico de barras simples (sem dependência de fontes de eixo) com a
  /// evolução do escore OSDI. Mostra as até 12 avaliações mais recentes.
  pw.Widget _buildOsdiChart(List<OsdiAssessment> history) {
    final items =
        history.length > 12 ? history.sublist(history.length - 12) : history;
    if (items.length < 2) return pw.SizedBox();
    const maxScore = 100.0;
    const chartHeight = 70.0;

    return pw.Container(
      height: chartHeight + 28,
      padding: const pw.EdgeInsets.only(top: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: items.map((e) {
          final h = (e.score / maxScore).clamp(0.04, 1.0) * chartHeight;
          return pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(e.score.toStringAsFixed(0),
                  style: const pw.TextStyle(fontSize: 7)),
              pw.SizedBox(height: 2),
              pw.Container(
                width: 16,
                height: h,
                color: _severityColor(e.severity),
              ),
              pw.SizedBox(height: 2),
              pw.Text(_formatShortDate(e.completedAt),
                  style: const pw.TextStyle(
                      fontSize: 6, color: PdfColors.grey600)),
            ],
          );
        }).toList(),
      ),
    );
  }

  // --- Sintomas -----------------------------------------------------------

  pw.Widget _buildSymptomsSection(pw.Context context, ReportData data) {
    final present = data.symptoms.where((s) => s.frequency > 0).toList()
      ..sort((a, b) => b.frequency.compareTo(a.frequency));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('2. Sintomas registrados', style: _headerStyle),
        pw.SizedBox(height: 8),
        if (!data.osdi.hasData)
          pw.Text(
            'Os sintomas são derivados das avaliações OSDI. Preencha o '
            'questionário para acompanhar a frequência e a tendência.',
            style: _textStyle,
          )
        else if (present.isEmpty)
          pw.Text('Nenhum sintoma relevante foi registrado neste período.',
              style: _textStyle)
        else
          pw.TableHelper.fromTextArray(
            context: context,
            cellStyle: _textStyle,
            cellAlignments: const {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
            },
            headerStyle: _textStyle.copyWith(fontWeight: pw.FontWeight.bold),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.blueGrey50),
            headers: const [
              'Sintoma',
              'Frequência',
              'Intensidade média',
              'Tendência',
            ],
            data: present
                .map((s) => [
                      s.label,
                      '${s.frequency}x',
                      s.averageIntensity.toStringAsFixed(1),
                      _trendLabel(s.trend),
                    ])
                .toList(),
          ),
      ],
    );
  }

  // --- Tempo de tela ------------------------------------------------------

  pw.Widget _buildScreenTimeSection(ReportData data) {
    final st = data.screenTime;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('3. Tempo de tela ativo', style: _headerStyle),
        pw.SizedBox(height: 8),
        if (!st.hasData)
          pw.Text('Tempo de tela não registrado neste período.',
              style: _textStyle)
        else ...[
          _kv('Tempo médio diário', _formatDuration(st.averageDailySeconds)),
          _kv('Total no período', _formatDuration(st.totalSeconds)),
          if (st.peakDay != null)
            _kv('Dia de maior exposição',
                '${_formatDate(st.peakDay!.day)} (${_formatDuration(st.peakDay!.seconds)})'),
          _kv('Média em dias úteis',
              _formatDuration(st.weekdayAverageSeconds)),
          _kv('Média em fins de semana',
              _formatDuration(st.weekendAverageSeconds)),
          pw.SizedBox(height: 8),
          pw.Text(
            'Maior tempo de tela pode estar associado a maior risco de sintomas '
            'visuais, especialmente quando combinado com pausas insuficientes, '
            'baixa umidade, ar-condicionado, brilho excessivo ou concentração '
            'visual prolongada.',
            style: _italicStyle,
          ),
        ],
      ],
    );
  }

  // --- Pausas -------------------------------------------------------------

  pw.Widget _buildBreaksSection(ReportData data) {
    final b = data.breaks;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('4. Pausas visuais', style: _headerStyle),
        pw.SizedBox(height: 8),
        if (!b.hasData)
          pw.Text('Pausas visuais ainda não foram registradas.',
              style: _textStyle)
        else ...[
          _kv('Lembretes emitidos', '${b.reminders}'),
          _kv('Pausas concluídas', '${b.completed}'),
          _kv('Pausas ignoradas', '${b.skipped}'),
          _kv('Taxa de adesão',
              '${((b.adherenceRate ?? 0) * 100).toStringAsFixed(0)}%'),
        ],
        pw.SizedBox(height: 8),
        pw.Text(
          'Pausas visuais regulares podem ajudar a reduzir a sobrecarga visual '
          'durante o uso prolongado de telas. Uma estratégia simples é a regra '
          '20-20-20: a cada 20 minutos, olhar por 20 segundos para uma distância '
          'aproximada de 20 pés ou 6 metros.',
          style: _italicStyle,
        ),
      ],
    );
  }

  // --- Ambiente visual ----------------------------------------------------

  pw.Widget _buildEnvironmentSection(EnvironmentChecklist env) {
    final (PdfColor color, String label) = switch (env.risk) {
      EnvironmentRisk.adequate => (PdfColors.green700, 'Adequado'),
      EnvironmentRisk.attention => (PdfColors.orange700, 'Atenção'),
      EnvironmentRisk.increased => (PdfColors.red700, 'Risco aumentado'),
    };

    final rows = <List<String>>[
      ['Distância da tela', env.screenDistanceOk ? 'Adequada' : 'Inadequada'],
      ['Altura do monitor', env.monitorHeightOk ? 'Adequada' : 'Inadequada'],
      ['Brilho', env.brightnessOk ? 'Confortável' : 'Desconfortável'],
      ['Contraste', env.contrastOk ? 'Confortável' : 'Desconfortável'],
      ['Iluminação do ambiente', env.lightingOk ? 'Adequada' : 'Inadequada'],
      ['Reflexo na tela', env.glare ? 'Presente' : 'Ausente'],
      ['Ar-condicionado', env.airConditioning ? 'Sim' : 'Não'],
      ['Ambiente seco / baixa umidade', env.dryAir ? 'Sim' : 'Não'],
      ['Múltiplos monitores', env.multiMonitor ? 'Sim' : 'Não'],
      ['Home office', env.homeOffice ? 'Sim' : 'Não'],
      ['Ventilador direcionado ao rosto', env.fanOnFace ? 'Sim' : 'Não'],
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('5. Ambiente visual', style: _headerStyle),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            pw.Text('Classificação do ambiente: ', style: _textStyle),
            pw.Text(label,
                style: _textStyle.copyWith(
                    color: color, fontWeight: pw.FontWeight.bold)),
          ],
        ),
        pw.SizedBox(height: 8),
        for (final r in rows) _kv(r[0], r[1]),
      ],
    );
  }

  // --- Checklists de saúde visual digital --------------------------------

  pw.Widget _buildChecklistsSection(pw.Context context, ReportData data) {
    final results = [...data.checklists]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final hasAttentionFlag = results.any((r) =>
        r.riskLevel == ChecklistRiskLevel.urgentAttention ||
        r.riskLevel == ChecklistRiskLevel.recommendedEvaluation);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('6. Checklists de saúde visual digital', style: _headerStyle),
        pw.SizedBox(height: 8),
        if (hasAttentionFlag) ...[
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.amber50,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: PdfColors.orange200),
            ),
            child: pw.Text(
              'Alguns checklists indicam sinais de atenção — considere '
              'avaliação oftalmológica.',
              style: _textStyle.copyWith(
                  color: PdfColors.orange900, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 10),
        ],
        pw.TableHelper.fromTextArray(
          context: context,
          cellStyle: _textStyle,
          cellAlignments: const {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.center,
            2: pw.Alignment.centerLeft,
            3: pw.Alignment.centerLeft,
          },
          headerStyle: _textStyle.copyWith(fontWeight: pw.FontWeight.bold),
          headerDecoration:
              const pw.BoxDecoration(color: PdfColors.blueGrey50),
          headers: const ['Checklist', 'Data', 'Resultado', 'Recomendação'],
          data: results
              .map((r) => [
                    _checklistTypeLabel(r.type),
                    _formatDate(r.createdAt),
                    r.classification,
                    _checklistRecommendation(r),
                  ])
              .toList(),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Resultados autorreferidos e educativos. Esta triagem não confirma '
          'diagnóstico e não substitui consulta médica.',
          style: _italicStyle,
        ),
      ],
    );
  }

  String _checklistTypeLabel(ChecklistType type) => switch (type) {
        ChecklistType.visualErgonomics => 'Ergonomia visual',
        ChecklistType.screenEnvironment => 'Ambiente de tela',
        ChecklistType.visualSymptoms => 'Sintomas visuais',
        ChecklistType.warningSigns => 'Sinais de alerta',
        ChecklistType.breakHabits => 'Pausas e hábitos',
        ChecklistType.ophthalmologyTriage => 'Triagem oftalmológica',
        ChecklistType.visualRiskSummary => 'Resumo de risco visual',
      };

  /// Recomendação curta: 1ª frase do feedback, ou um texto por nível de risco.
  String _checklistRecommendation(ChecklistResult result) {
    final feedback = result.feedback.trim();
    if (feedback.isNotEmpty) {
      final match = RegExp(r'^.*?[.!?](\s|$)').firstMatch(feedback);
      final sentence = (match?.group(0) ?? feedback).trim();
      if (sentence.isNotEmpty) return sentence;
    }
    return _checklistRiskRecommendation(result.riskLevel);
  }

  String _checklistRiskRecommendation(ChecklistRiskLevel level) =>
      switch (level) {
        ChecklistRiskLevel.low =>
          'Mantenha os hábitos saudáveis e o acompanhamento.',
        ChecklistRiskLevel.attention =>
          'Observe os sinais de atenção e reforce hábitos visuais.',
        ChecklistRiskLevel.increased =>
          'Considere ajustar hábitos e acompanhar a evolução.',
        ChecklistRiskLevel.recommendedEvaluation =>
          'Considere avaliação oftalmológica.',
        ChecklistRiskLevel.urgentAttention =>
          'Considere avaliação oftalmológica com prioridade.',
      };

  // --- Quando procurar avaliação -----------------------------------------

  pw.Widget _buildEvaluationSection(ReportData data) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: data.alerts.isEmpty ? PdfColors.blueGrey50 : PdfColors.amber50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(
          color:
              data.alerts.isEmpty ? PdfColors.blueGrey200 : PdfColors.orange200,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Quando procurar avaliação oftalmológica',
              style: _headerStyle),
          pw.SizedBox(height: 8),
          if (data.alerts.isEmpty)
            pw.Text(
              'Nenhum sinal de alerta específico foi identificado neste período. '
              'Mantenha o acompanhamento e procure um oftalmologista se surgirem '
              'sintomas persistentes, dor ocular, fotofobia ou visão embaçada.',
              style: _textStyle,
            )
          else ...[
            pw.Text('Foram identificados os seguintes pontos de atenção:',
                style: _textStyle),
            pw.SizedBox(height: 4),
            for (final alert in data.alerts)
              pw.Bullet(text: alert, style: _textStyle),
          ],
          pw.SizedBox(height: 8),
          pw.Text(mandatoryClosing,
              style: _textStyle.copyWith(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  // --- Observações --------------------------------------------------------

  pw.Widget _buildObservationsSection(ReportData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Observações pessoais', style: _headerStyle),
        pw.SizedBox(height: 8),
        pw.Text(data.profile.observations!, style: _textStyle),
      ],
    );
  }

  // --- Privacidade --------------------------------------------------------

  pw.Widget _buildPrivacySection() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Avisos e privacidade', style: _headerStyle),
        pw.SizedBox(height: 8),
        pw.Text(privacyNotice, style: _textStyle),
      ],
    );
  }

  // --- Rodapé -------------------------------------------------------------

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.Text(
          legalFooter,
          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          'Página ${context.pageNumber} de ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
        ),
      ],
    );
  }

  // --- Helpers de layout/formatação --------------------------------------

  pw.Widget _kv(String key, String value) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(key, style: _textStyle),
            pw.Text(value,
                style: _textStyle.copyWith(fontWeight: pw.FontWeight.bold)),
          ],
        ),
      );

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _formatShortDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  String _signed(double value, {int decimals = 1}) {
    final sign = value > 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(decimals)}';
  }

  String _severityLabel(OsdiSeverity severity) => switch (severity) {
        OsdiSeverity.normal => 'Normal',
        OsdiSeverity.mild => 'Leve',
        OsdiSeverity.moderate => 'Moderado',
        OsdiSeverity.severe => 'Grave',
      };

  PdfColor _severityColor(OsdiSeverity severity) => switch (severity) {
        OsdiSeverity.normal => PdfColors.green400,
        OsdiSeverity.mild => PdfColors.blue400,
        OsdiSeverity.moderate => PdfColors.orange400,
        OsdiSeverity.severe => PdfColors.red400,
      };

  String _trendLabel(SymptomTrend trend) => switch (trend) {
        SymptomTrend.improving => 'Melhorando',
        SymptomTrend.worsening => 'Piorando',
        SymptomTrend.stable => 'Estável',
        // Hífen ASCII: a Helvetica embutida do PDF não cobre o em-dash (U+2014).
        SymptomTrend.unknown => '-',
      };

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${minutes}min';
    return '${minutes}min';
  }

  // --- Arquivo ------------------------------------------------------------

  /// Salva o PDF em uma pasta temporária (usado para compartilhamento).
  Future<File> savePdfFile(Uint8List pdfData, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName.pdf');
    await file.writeAsBytes(pdfData);
    return file;
  }

  /// Salva o PDF de forma persistente no dispositivo (Downloads ou Documentos).
  Future<File> savePdfToDevice(Uint8List pdfData, String fileName) async {
    Directory? dir;
    try {
      dir = await getDownloadsDirectory();
    } catch (_) {
      dir = null;
    }
    dir ??= await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName.pdf');
    await file.writeAsBytes(pdfData);
    return file;
  }
}
