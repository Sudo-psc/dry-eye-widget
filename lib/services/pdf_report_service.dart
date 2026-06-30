import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/dvrs_assessment.dart';
import '../models/dvrs_definitions.dart';
import '../models/environment_checklist.dart';
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
          if (data.options.includeDvrs && data.dvrs != null) ...[
            _buildDvrsSection(context, data.dvrs!),
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
    final dvrs = data.dvrs;
    if (data.options.includeDvrs && dvrs != null) {
      rows.add([
        'DVRS mais recente',
        '${dvrs.latest.totalScore}/100 (${dvrs.latest.classificationLabel})',
      ]);
      if (dvrs.history.length >= 2) {
        final previous = dvrs.history[dvrs.history.length - 2];
        final delta = dvrs.latest.totalScore - previous.totalScore;
        rows.add(['Variação no período', '${_signed(delta.toDouble())} pontos']);
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

  // --- DVRS ---------------------------------------------------------------

  /// Seção do DVRS — Índice de Risco Visual Digital (questionário principal).
  pw.Widget _buildDvrsSection(pw.Context context, DvrsReportData dvrs) {
    final latest = dvrs.latest;
    final color = _dvrsColor(latest.classification);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('DVRS — Índice de Risco Visual Digital', style: _headerStyle),
        pw.SizedBox(height: 8),
        pw.Text('Preenchido em ${_formatDate(latest.createdAt)}',
            style: _mutedStyle),
        pw.SizedBox(height: 6),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('${latest.totalScore}',
                style: pw.TextStyle(
                  color: color,
                  fontSize: 30,
                  fontWeight: pw.FontWeight.bold,
                )),
            pw.Text(' /100',
                style: _mutedStyle.copyWith(fontSize: 12)),
            pw.SizedBox(width: 10),
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: color),
              ),
              child: pw.Text(latest.classificationLabel,
                  style: pw.TextStyle(
                      color: color, fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Text('Scores por domínio', style: _textStyle.copyWith(
            fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          context: context,
          cellStyle: _textStyle,
          headerStyle: _textStyle.copyWith(fontWeight: pw.FontWeight.bold),
          headerDecoration:
              const pw.BoxDecoration(color: PdfColors.blueGrey50),
          headers: const ['Domínio', 'Score (0–100)'],
          data: DvrsDomain.values
              .map((d) => [
                    kDvrsDomainLabels[d] ?? d.id,
                    latest.domainScores.valueFor(d).round().toString(),
                  ])
              .toList(),
        ),
        if (dvrs.hasEvolution) ...[
          pw.SizedBox(height: 12),
          pw.Text('Evolução do score', style: _textStyle.copyWith(
              fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            context: context,
            cellStyle: _textStyle,
            headerStyle: _textStyle.copyWith(fontWeight: pw.FontWeight.bold),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.blueGrey50),
            headers: const ['Data', 'Score', 'Classificação'],
            data: dvrs.history
                .map((r) => [
                      _formatDate(r.createdAt),
                      r.totalScore.toString(),
                      r.classificationLabel,
                    ])
                .toList(),
          ),
        ],
        pw.SizedBox(height: 10),
        pw.Text(latest.educationalMessage, style: _textStyle),
        if (latest.safetyAlertLevel != DvrsSafetyAlertLevel.none &&
            latest.safetyAlertMessage != null) ...[
          pw.SizedBox(height: 10),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              border: pw.Border.all(color: _dvrsColor(latest.classification)),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              'Atenção: ${latest.safetyAlertMessage}',
              style: _textStyle.copyWith(fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
        pw.SizedBox(height: 8),
        pw.Text(kDvrsPdfLegalNotice, style: _italicStyle),
      ],
    );
  }

  PdfColor _dvrsColor(DvrsClassification c) => switch (c) {
        DvrsClassification.low => PdfColors.green800,
        DvrsClassification.mildAttention => PdfColors.orange800,
        DvrsClassification.moderateRisk => PdfColors.deepOrange,
        DvrsClassification.highRisk => PdfColors.red,
        DvrsClassification.veryHighRisk => PdfColors.red900,
      };

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

  String _signed(double value, {int decimals = 1}) {
    final sign = value > 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(decimals)}';
  }

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
