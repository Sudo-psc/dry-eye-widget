import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../l10n/feature_strings.dart';
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

  /// Mensagem neutra gerada no momento da exportação, nunca lida do histórico.
  static const String dvrsEducationalMessage = kDvrsPdfEducationalMessage;

  /// Resolve o alerta de segurança atual em português a partir do nível
  /// semântico. Texto legado serializado nunca participa da exportação.
  static String? dvrsSafetyMessageFor(DvrsSafetyAlertLevel level) =>
      FeatureStrings.of('pt').dvrsSafetyMessage(level);

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

  // Fontes empacotadas são obrigatórias: relatórios podem conter acentos,
  // travessões e aspas curvas. Usar Helvetica como base e tentar um fallback
  // opcional permitia gerar um PDF sem alguns glifos quando o primeiro acesso
  // ao asset bundle falhava. O cache só é preenchido após carregar tudo; uma
  // falha transitória não envenena as próximas tentativas.
  static _PdfFonts? _fonts;

  Future<_PdfFonts> _loadFonts() async {
    final cached = _fonts;
    if (cached != null) return cached;

    final regular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Inter-Regular.ttf'),
    );
    final bold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Inter-Bold.ttf'),
    );
    final unicode = pw.Font.ttf(
      await rootBundle.load('assets/fonts/DejaVuSans.ttf'),
    );
    final loaded = _PdfFonts(regular: regular, bold: bold, unicode: unicode);
    _fonts = loaded;
    return loaded;
  }

  /// Gera o documento PDF em formato binário.
  Future<Uint8List> generateReport(ReportData data) async {
    final fonts = await _loadFonts();
    final pdf = pw.Document(
      title: 'Relatório de Saúde Visual Digital',
      author: 'Dry Eye Widget',
      theme: pw.ThemeData.withFont(
        base: fonts.regular,
        bold: fonts.bold,
        // O pacote ainda não traz uma face itálica. Reutilizar as faces
        // incorporadas é preferível a Helvetica oblíqua, que perde Unicode e
        // emite avisos de glifos. Uma futura face Inter Italic pode substituir
        // esta associação sem alterar o restante do documento.
        italic: fonts.regular,
        boldItalic: fonts.bold,
        fontFallback: [fonts.unicode],
      ),
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
          if (data.narrative != null && data.narrative!.trim().isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _buildNarrativeSection(data.narrative!),
          ],
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
                pw.Text(
                  'Relatório de Saúde Visual Digital',
                  style: _titleStyle,
                ),
                pw.SizedBox(height: 2),
                pw.Text('Dry Eye Widget', style: _mutedStyle),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Emitido em ${_formatDate(data.generatedAt)}',
                  style: _mutedStyle,
                ),
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

  // --- Narrativa para o oftalmologista ------------------------------------

  pw.Widget _buildNarrativeSection(String narrative) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Narrativa para o oftalmologista', style: _headerStyle),
        pw.SizedBox(height: 6),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.blueGrey50,
            border: pw.Border.all(color: PdfColors.blueGrey100),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Text(narrative, style: _textStyle.copyWith(height: 1.35)),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Texto educativo gerado a partir de dados autorreferidos. '
          'Não constitui diagnóstico.',
          style: _italicStyle,
        ),
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
        'Perfil educativo de ${_formatDate(dvrs.latest.createdAt)}',
      ]);
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
                      pw.Text(
                        r[1],
                        style: _textStyle.copyWith(
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
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
      child: pw.Text(
        label,
        style: pw.TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  // --- DVRS ---------------------------------------------------------------

  /// Seção do DVRS — autorregistro educativo por domínios.
  pw.Widget _buildDvrsSection(pw.Context context, DvrsReportData dvrs) {
    final latest = dvrs.latest;
    final dvrsStrings = FeatureStrings.of('pt');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('DVRS — autorregistro educativo', style: _headerStyle),
        pw.SizedBox(height: 8),
        pw.Text(
          'Preenchido em ${_formatDate(latest.createdAt)}. '
          'As respostas abaixo reproduzem o autorrelato registrado em cada '
          'domínio e não constituem escore ou classificação de risco.',
          style: _mutedStyle,
        ),
        pw.SizedBox(height: 6),
        pw.Text(dvrsEducationalMessage, style: _textStyle),
        pw.SizedBox(height: 6),
        pw.Text(
          'Perfil por domínio',
          style: _textStyle.copyWith(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          context: context,
          cellStyle: _textStyle,
          headerStyle: _textStyle.copyWith(fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
          headers: const ['Domínio', 'Respostas autorreferidas'],
          data: DvrsDomain.values
              .map(
                (domain) => [
                  dvrsStrings.dvrsDomainLabel(domain.id),
                  latest.answers
                      .where((answer) => answer.domain == domain)
                      .map((answer) => answer.label)
                      .join(' • '),
                ],
              )
              .toList(),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Use as respostas por domínio para acompanhar os sintomas, hábitos e '
          'condições que você relatou ao longo do tempo.',
          style: _textStyle,
        ),
        if (dvrsSafetyMessageFor(latest.safetyAlertLevel)
            case final safetyMessage?) ...[
          pw.SizedBox(height: 10),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              border: pw.Border.all(
                color: _dvrsSafetyColor(latest.safetyAlertLevel),
              ),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              'Atenção: $safetyMessage',
              style: _textStyle.copyWith(fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
        pw.SizedBox(height: 8),
        pw.Text(kDvrsPdfLegalNotice, style: _italicStyle),
      ],
    );
  }

  PdfColor _dvrsSafetyColor(DvrsSafetyAlertLevel level) => switch (level) {
    DvrsSafetyAlertLevel.none => PdfColors.blueGrey,
    DvrsSafetyAlertLevel.attention => PdfColors.orange800,
    DvrsSafetyAlertLevel.medicalEvaluation => PdfColors.red,
    DvrsSafetyAlertLevel.priorityEvaluation => PdfColors.red900,
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
          pw.Text(
            'Tempo de tela não registrado neste período.',
            style: _textStyle,
          )
        else ...[
          _kv('Tempo médio diário', _formatDuration(st.averageDailySeconds)),
          _kv('Total no período', _formatDuration(st.totalSeconds)),
          if (st.peakDay != null)
            _kv(
              'Dia de maior exposição',
              '${_formatDate(st.peakDay!.day)} (${_formatDuration(st.peakDay!.seconds)})',
            ),
          _kv('Média em dias úteis', _formatDuration(st.weekdayAverageSeconds)),
          _kv(
            'Média em fins de semana',
            _formatDuration(st.weekendAverageSeconds),
          ),
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
          pw.Text(
            'Pausas visuais ainda não foram registradas.',
            style: _textStyle,
          )
        else ...[
          _kv('Lembretes emitidos', '${b.reminders}'),
          _kv('Pausas concluídas', '${b.completed}'),
          _kv('Pausas ignoradas', '${b.skipped}'),
          _kv(
            'Taxa de adesão',
            '${((b.adherenceRate ?? 0) * 100).toStringAsFixed(0)}%',
          ),
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
            pw.Text(
              label,
              style: _textStyle.copyWith(
                color: color,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
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
          color: data.alerts.isEmpty
              ? PdfColors.blueGrey200
              : PdfColors.orange200,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Quando procurar avaliação oftalmológica',
            style: _headerStyle,
          ),
          pw.SizedBox(height: 8),
          if (data.alerts.isEmpty)
            pw.Text(
              'Nenhum sinal de alerta específico foi identificado neste período. '
              'Mantenha o acompanhamento e procure um oftalmologista se surgirem '
              'sintomas persistentes, dor ocular, fotofobia ou visão embaçada.',
              style: _textStyle,
            )
          else ...[
            pw.Text(
              'Foram identificados os seguintes pontos de atenção:',
              style: _textStyle,
            ),
            pw.SizedBox(height: 4),
            for (final alert in data.alerts)
              pw.Bullet(text: alert, style: _textStyle),
          ],
          pw.SizedBox(height: 8),
          pw.Text(
            mandatoryClosing,
            style: _textStyle.copyWith(fontWeight: pw.FontWeight.bold),
          ),
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
        pw.Text(
          value,
          style: _textStyle.copyWith(fontWeight: pw.FontWeight.bold),
        ),
      ],
    ),
  );

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

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

@immutable
class _PdfFonts {
  const _PdfFonts({
    required this.regular,
    required this.bold,
    required this.unicode,
  });

  final pw.Font regular;
  final pw.Font bold;
  final pw.Font unicode;
}
