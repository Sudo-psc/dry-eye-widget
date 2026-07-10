import '../models/dvrs_assessment.dart';
import '../models/report_options.dart';

/// Gera 5–8 linhas narrativas educativas para o oftalmologista a partir de
/// [ReportData] já calculado. Linguagem de triagem — nunca diagnóstica.
class NarrativeSummary {
  NarrativeSummary._();

  /// Texto multilinha (parágrafos curtos) em português (padrão do PDF).
  static String buildPt(ReportData data) {
    final lines = <String>[];
    final periodDays = data.options.days;
    lines.add(
      'Paciente autorrelata uso de telas e hábitos de pausa visual no período '
      'de $periodDays dia(s), com dados gerados localmente pelo Dry Eye Widget '
      '(ferramenta educativa, não diagnóstica).',
    );

    final dvrs = data.dvrs;
    if (dvrs != null) {
      final latest = dvrs.latest;
      lines.add(
        'Último DVRS (${latest.version}): score ${latest.totalScore}/100 — '
        '${latest.classificationLabel}. '
        'Domínios (0–100): sintomas ${latest.domainScores.symptoms.round()}, '
        'funcional ${latest.domainScores.functional.round()}, '
        'exposição ${latest.domainScores.exposure.round()}, '
        'ambiente ${latest.domainScores.environment.round()}, '
        'alerta ${latest.domainScores.warning.round()}.',
      );
      if (dvrs.history.length >= 2) {
        final prev = dvrs.history[dvrs.history.length - 2];
        final delta = latest.totalScore - prev.totalScore;
        final trend = delta > 1
            ? 'piora'
            : delta < -1
                ? 'melhora'
                : 'estabilidade';
        lines.add(
          'Em relação à avaliação anterior (score ${prev.totalScore}), '
          'observa-se $trend do score total '
          '(${delta >= 0 ? '+' : ''}$delta pontos).',
        );
      }
      if (latest.safetyAlertLevel != DvrsSafetyAlertLevel.none &&
          latest.safetyAlertMessage != null) {
        lines.add(
          'Sinal de alerta do questionário (Q16): ${latest.safetyAlertMessage}',
        );
      }
    } else {
      lines.add(
        'Não há DVRS registrado no período; recomenda-se triagem educativa '
        'quando houver sintomas visuais digitais persistentes.',
      );
    }

    if (data.breaks.hasData) {
      final adh = data.breaks.adherenceRate;
      final adhTxt =
          adh == null ? 'sem taxa' : '${(adh * 100).toStringAsFixed(0)}% de adesão';
      lines.add(
        'Pausas 20-20-20 no período: ${data.breaks.completed} concluídas de '
        '${data.breaks.reminders} lembretes ($adhTxt).',
      );
    }

    if (data.screenTime.hasData) {
      final h = data.screenTime.averageDailySeconds ~/ 3600;
      final m = (data.screenTime.averageDailySeconds % 3600) ~/ 60;
      lines.add(
        'Tempo médio de tela estimado: ${h}h ${m}min por dia com dados '
        '(${data.screenTime.daysWithData} dia(s) com registro).',
      );
    }

    lines.add(
      'Indicação educativa do relatório: ${_indicationPt(data.indication)}. '
      'Este texto organiza informações autorreferidas para facilitar a conversa '
      'clínica e não substitui exame oftalmológico.',
    );

    // Limita a ~8 frases densas.
    return lines.take(8).join('\n\n');
  }

  static String _indicationPt(OverallIndication i) {
    switch (i) {
      case OverallIndication.monitor:
        return 'acompanhar hábitos e sintomas';
      case OverallIndication.reinforceBreaks:
        return 'reforçar pausas visuais e ergonomia';
      case OverallIndication.seekEvaluation:
        return 'considerar avaliação oftalmológica se sintomas persistirem';
    }
  }
}
