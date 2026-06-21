import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/osdi_assessment.dart';
import '../models/report_options.dart';

class PdfReportService {
  /// Gera o documento PDF em formato binário.
  Future<Uint8List> generateReport(ReportData data) async {
    final pdf = pw.Document(
      title: 'Relatório de Saúde Visual Digital',
      author: 'Dry Eye Widget',
    );

    // Definição de estilos baseados na paleta limpa: azul escuro, cinza, branco.
    final titleStyle = pw.TextStyle(
      color: PdfColors.blue900,
      fontSize: 24,
      fontWeight: pw.FontWeight.bold,
    );
    final headerStyle = pw.TextStyle(
      color: PdfColors.grey800,
      fontSize: 18,
      fontWeight: pw.FontWeight.bold,
    );
    final textStyle = const pw.TextStyle(
      color: PdfColors.black,
      fontSize: 12,
    );
    final warningStyle = pw.TextStyle(
      color: PdfColors.red900,
      fontSize: 12,
      fontWeight: pw.FontWeight.bold,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (context) {
          return pw.Column(
            children: [
              pw.Divider(),
              pw.Text(
                'Relatório gerado pelo Dry Eye Widget. Documento educativo e de triagem. '
                'Não constitui diagnóstico, prescrição ou substituição de avaliação oftalmológica. '
                'Em caso de sintomas persistentes, dor ocular, fotofobia, visão embaçada recorrente '
                'ou piora progressiva, procure um médico oftalmologista.',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Página ${context.pageNumber} de ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            ],
          );
        },
        build: (context) => [
          // Identificação do relatório
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Relatório de Saúde Visual Digital', style: titleStyle),
                    pw.SizedBox(height: 4),
                    pw.Text('App: Dry Eye Widget', style: textStyle),
                  ],
                ),
                pw.Text(
                  'Data: ${_formatDate(DateTime.now())}',
                  style: textStyle.copyWith(color: PdfColors.grey600),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          pw.Text('Período: ${_formatDate(data.options.startDate)} a ${_formatDate(data.options.endDate)}', style: textStyle),
          if (data.profile.name != null && data.profile.name!.trim().isNotEmpty)
            pw.Text('Usuário: ${data.profile.name}', style: textStyle),
          pw.SizedBox(height: 24),

          // Resumo Executivo
          pw.Text('Resumo Executivo', style: headerStyle),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (data.options.includeOsdi) ...[
                  pw.Text('Escore OSDI Mais Recente: ${_formatOsdi(data.latestOsdi)}', style: textStyle),
                  if (data.latestOsdi != null && data.previousOsdi != null)
                    pw.Text('Variação no período: ${_calculateOsdiVariation(data.previousOsdi!, data.latestOsdi!)}', style: textStyle),
                  pw.SizedBox(height: 8),
                ],
                if (data.options.includeScreenTime) ...[
                  pw.Text('Tempo Médio de Tela Diário: ${_formatDuration(data.averageScreenTimeSeconds)}', style: textStyle),
                  pw.Text('Total de Tela no Período: ${_formatDuration(data.totalScreenTimeSeconds)}', style: textStyle),
                ],
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // Alerta Clínico Educativo
          _buildClinicalAlert(data, headerStyle, warningStyle, textStyle),

          // Escore OSDI
          if (data.options.includeOsdi) ...[
            pw.Text('1. Escore OSDI', style: headerStyle),
            pw.SizedBox(height: 8),
            if (data.osdiHistory.isEmpty)
              pw.Text('Ainda não há dados suficientes de OSDI neste período.', style: textStyle)
            else ...[
              pw.TableHelper.fromTextArray(
                context: context,
                headers: ['Data', 'Escore', 'Classificação'],
                data: data.osdiHistory.map((e) => [
                  _formatDate(e.completedAt),
                  e.score.toStringAsFixed(1),
                  _severityLabel(e.severity),
                ]).toList(),
              ),
            ],
            pw.SizedBox(height: 8),
            pw.Text(
              'O escore OSDI é um instrumento de sintomas e não confirma diagnóstico isoladamente. '
              'Escores elevados, piora progressiva ou sintomas persistentes devem ser avaliados por um oftalmologista.',
              style: textStyle.copyWith(fontStyle: pw.FontStyle.italic),
            ),
            pw.SizedBox(height: 24),
          ],

          // Tempo de Tela
          if (data.options.includeScreenTime) ...[
            pw.Text('2. Tempo de Tela Ativo', style: headerStyle),
            pw.SizedBox(height: 8),
            if (data.totalScreenTimeSeconds == 0)
              pw.Text('Tempo de tela não registrado neste período.', style: textStyle)
            else ...[
              pw.Text('O tempo médio diário medido foi de ${_formatDuration(data.averageScreenTimeSeconds)}.', style: textStyle),
              pw.SizedBox(height: 8),
              pw.Text(
                'Maior tempo de tela pode estar associado a maior risco de sintomas visuais, '
                'especialmente quando combinado com pausas insuficientes, baixa umidade, '
                'ar-condicionado, brilho excessivo ou concentração visual prolongada.',
                style: textStyle.copyWith(fontStyle: pw.FontStyle.italic),
              ),
            ],
            pw.SizedBox(height: 24),
          ],

          // Observações Pessoais
          if (data.profile.observations != null && data.profile.observations!.trim().isNotEmpty) ...[
            pw.Text('3. Observações Pessoais', style: headerStyle),
            pw.SizedBox(height: 8),
            pw.Text(data.profile.observations!, style: textStyle),
            pw.SizedBox(height: 24),
          ],
          
          // Recomendações Educativas
          pw.Text('Recomendações Educativas', style: headerStyle),
          pw.SizedBox(height: 8),
          pw.Text(
            'Pausas visuais regulares podem ajudar a reduzir a sobrecarga visual durante o '
            'uso prolongado de telas. Uma estratégia simples é a regra 20-20-20: a cada 20 minutos, '
            'olhar por 20 segundos para uma distância aproximada de 20 pés ou 6 metros.',
            style: textStyle,
          ),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildClinicalAlert(ReportData data, pw.TextStyle headerStyle, pw.TextStyle warningStyle, pw.TextStyle textStyle) {
    bool shouldAlert = false;
    
    if (data.latestOsdi != null) {
      if (data.latestOsdi!.severity == OsdiSeverity.moderate || data.latestOsdi!.severity == OsdiSeverity.severe) {
        shouldAlert = true;
      }
    }
    
    if (data.latestOsdi != null && data.previousOsdi != null) {
      if (data.latestOsdi!.score - data.previousOsdi!.score > 10) {
        shouldAlert = true;
      }
    }

    if (!shouldAlert) return pw.SizedBox.shrink();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Quando procurar avaliação oftalmológica', style: headerStyle),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.yellow50,
            border: pw.Border.all(color: PdfColors.yellow600),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Atenção: Considere agendar avaliação oftalmológica.', style: warningStyle),
              pw.SizedBox(height: 4),
              pw.Text(
                'Notamos um escore elevado ou piora recente. Este relatório não substitui consulta médica. '
                'Ele organiza informações autorreferidas para facilitar o acompanhamento e a conversa com o oftalmologista.',
                style: textStyle,
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 24),
      ],
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _formatOsdi(OsdiAssessment? osdi) {
    if (osdi == null) return 'Sem dados';
    return '${osdi.score.toStringAsFixed(1)} (${_severityLabel(osdi.severity)})';
  }

  String _calculateOsdiVariation(OsdiAssessment prev, OsdiAssessment current) {
    final diff = current.score - prev.score;
    if (diff == 0) return 'Estável';
    final sign = diff > 0 ? '+' : '';
    return '$sign${diff.toStringAsFixed(1)} pontos';
  }

  String _severityLabel(OsdiSeverity severity) {
    switch (severity) {
      case OsdiSeverity.normal:
        return 'Normal';
      case OsdiSeverity.mild:
        return 'Leve';
      case OsdiSeverity.moderate:
        return 'Moderado';
      case OsdiSeverity.severe:
        return 'Grave';
    }
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes}min';
  }

  /// Salva o PDF no dispositivo em uma pasta temporária ou de documentos.
  Future<File> savePdfFile(Uint8List pdfData, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName.pdf');
    await file.writeAsBytes(pdfData);
    return file;
  }
}
