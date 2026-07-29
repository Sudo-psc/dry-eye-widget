import '../l10n/feature_strings.dart';
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
        'Último DVRS (${latest.version}), perfil educativo por domínios '
        '(0–100; números maiores representam maior carga autorrelatada, '
        'não risco clínico): sintomas ${latest.domainScores.symptoms.round()}, '
        'funcional ${latest.domainScores.functional.round()}, '
        'exposição ${latest.domainScores.exposure.round()}, '
        'ambiente ${latest.domainScores.environment.round()}, '
        'alerta ${latest.domainScores.warning.round()}.',
      );
      if (dvrs.history.length >= 2) {
        lines.add(
          'Há ${dvrs.history.length} registros no período para comparação '
          'descritiva por domínio; o total numérico legado não é apresentado '
          'como escore clínico.',
        );
      }
      final safetyMessage = FeatureStrings.of(
        'pt',
      ).dvrsSafetyMessage(latest.safetyAlertLevel);
      if (safetyMessage != null) {
        lines.add('Sinal de alerta do questionário (Q16): $safetyMessage');
      }
    } else {
      lines.add(
        'Não há DVRS registrado no período; recomenda-se triagem educativa '
        'quando houver sintomas visuais digitais persistentes.',
      );
    }

    if (data.breaks.hasData) {
      final adh = data.breaks.adherenceRate;
      final adhTxt = adh == null
          ? 'sem taxa'
          : '${(adh * 100).toStringAsFixed(0)}% de adesão';
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
