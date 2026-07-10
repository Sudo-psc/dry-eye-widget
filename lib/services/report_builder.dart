import '../models/break_stats_data.dart';
import '../models/dvrs_assessment.dart';
import '../models/environment_checklist.dart';
import '../models/report_options.dart';
import '../models/screen_time_data.dart';
import 'dvrs_engine.dart';
import 'narrative_summary.dart';

/// Constrói o [ReportData] a partir dos dados brutos do app.
///
/// Camada **pura** (sem I/O, sem Flutter widgets) — todo o cálculo do relatório
/// vive aqui para ser facilmente testável: preparação do DVRS, médias de tempo
/// de tela, adesão às pausas, indicação geral e gatilhos de alerta educativo.
/// Toda a saída é de triagem/educação, nunca diagnóstica.
class ReportBuilder {
  const ReportBuilder();

  /// Limiares de tela (em segundos/dia) usados para indicação educativa.
  /// Revisar conforme evidência/posicionamento do produto.
  static const int highScreenTimeSeconds = 6 * 3600; // 6h/dia
  static const double lowAdherenceThreshold = 0.7; // < 70% de pausas concluídas

  ReportData build({
    required UserProfile profile,
    required ReportOptions options,
    required ScreenTimeData screenTime,
    required BreakStatsData breakStats,
    EnvironmentChecklist? environment,
    List<DvrsResult> dvrsHistory = const [],
    DateTime? now,
  }) {
    final generatedAt = now ?? DateTime.now();

    final dvrs = options.includeDvrs ? prepareDvrsForPdf(dvrsHistory) : null;
    final screen = _buildScreenTimeSummary(screenTime, options);
    final breaks = _buildBreakSummary(breakStats, options);

    final alerts = _buildAlerts(dvrs: dvrs, screen: screen, breaks: breaks);
    final indication = _resolveIndication(
      dvrs: dvrs,
      screen: screen,
      breaks: breaks,
    );

    final data = ReportData(
      profile: profile,
      options: options,
      screenTime: screen,
      breaks: breaks,
      indication: indication,
      alerts: alerts,
      generatedAt: generatedAt,
      dvrs: dvrs,
      environment: options.includeEnvironment ? environment : null,
    );
    // Segunda passagem só para a narrativa (usa o ReportData já calculado).
    return ReportData(
      profile: profile,
      options: options,
      screenTime: screen,
      breaks: breaks,
      indication: indication,
      alerts: alerts,
      generatedAt: generatedAt,
      dvrs: dvrs,
      environment: data.environment,
      narrative: NarrativeSummary.buildPt(data),
    );
  }

  // --- Tempo de tela ------------------------------------------------------

  ScreenTimeSummary _buildScreenTimeSummary(
    ScreenTimeData data,
    ReportOptions options,
  ) {
    final series = _screenSeries(data, options);

    var total = 0;
    var daysWithData = 0;
    var weekdayTotal = 0;
    var weekdayCount = 0;
    var weekendTotal = 0;
    var weekendCount = 0;
    ScreenTimePoint? peak;

    for (final point in series) {
      if (point.seconds > 0) {
        total += point.seconds;
        daysWithData++;
        if (peak == null || point.seconds > peak.seconds) peak = point;
      }
      final isWeekend = point.day.weekday == DateTime.saturday ||
          point.day.weekday == DateTime.sunday;
      if (isWeekend) {
        weekendTotal += point.seconds;
        weekendCount++;
      } else {
        weekdayTotal += point.seconds;
        weekdayCount++;
      }
    }

    return ScreenTimeSummary(
      series: series,
      totalSeconds: total,
      averageDailySeconds: daysWithData > 0 ? total ~/ daysWithData : 0,
      daysWithData: daysWithData,
      weekdayAverageSeconds: weekdayCount > 0 ? weekdayTotal ~/ weekdayCount : 0,
      weekendAverageSeconds: weekendCount > 0 ? weekendTotal ~/ weekendCount : 0,
      peakDay: peak,
    );
  }

  List<ScreenTimePoint> _screenSeries(
    ScreenTimeData data,
    ReportOptions options,
  ) {
    final end = DateTime(
      options.endDate.year,
      options.endDate.month,
      options.endDate.day,
    );
    return data.dailySeries(end, options.days);
  }

  // --- Pausas -------------------------------------------------------------

  BreakSummary _buildBreakSummary(BreakStatsData data, ReportOptions options) {
    final stat = data.sumForRange(options.startDate, options.endDate);
    return BreakSummary(reminders: stat.reminders, completed: stat.completed);
  }

  // --- Indicação geral e alertas -----------------------------------------

  List<String> _buildAlerts({
    required DvrsReportData? dvrs,
    required ScreenTimeSummary screen,
    required BreakSummary breaks,
  }) {
    final alerts = <String>[];
    final latest = dvrs?.latest;

    if (latest != null) {
      if (latest.classification == DvrsClassification.highRisk ||
          latest.classification == DvrsClassification.veryHighRisk) {
        alerts.add(
          'DVRS em faixa elevada (${latest.totalScore}/100 — '
          '${latest.classificationLabel}) na avaliação mais recente.',
        );
      }
      if (latest.safetyAlertLevel != DvrsSafetyAlertLevel.none &&
          latest.safetyAlertMessage != null) {
        alerts.add(latest.safetyAlertMessage!);
      }
      // Piora relevante do score desde a avaliação anterior.
      if (dvrs!.history.length >= 2) {
        final previous = dvrs.history[dvrs.history.length - 2];
        final delta = latest.totalScore - previous.totalScore;
        if (delta >= 15) {
          alerts.add(
            'Piora relevante do DVRS (+$delta pontos) em relação à avaliação '
            'anterior.',
          );
        }
      }
    }

    if (screen.averageDailySeconds >= highScreenTimeSeconds) {
      alerts.add('Tempo médio de tela elevado no período.');
    }
    if (breaks.adherenceRate != null &&
        breaks.adherenceRate! < lowAdherenceThreshold) {
      alerts.add('Baixa adesão às pausas visuais no período.');
    }

    return alerts;
  }

  OverallIndication _resolveIndication({
    required DvrsReportData? dvrs,
    required ScreenTimeSummary screen,
    required BreakSummary breaks,
  }) {
    final latest = dvrs?.latest;

    final highDvrs = latest != null &&
        (latest.classification == DvrsClassification.highRisk ||
            latest.classification == DvrsClassification.veryHighRisk);
    final safetyEvaluation = latest != null &&
        (latest.safetyAlertLevel == DvrsSafetyAlertLevel.medicalEvaluation ||
            latest.safetyAlertLevel == DvrsSafetyAlertLevel.priorityEvaluation);
    final moderateDvrs =
        latest != null && latest.classification == DvrsClassification.moderateRisk;

    final highScreen = screen.averageDailySeconds >= highScreenTimeSeconds;
    final lowAdherence = breaks.adherenceRate != null &&
        breaks.adherenceRate! < lowAdherenceThreshold;

    if (highDvrs || safetyEvaluation) {
      return OverallIndication.seekEvaluation;
    }
    if (moderateDvrs || lowAdherence || highScreen) {
      return OverallIndication.reinforceBreaks;
    }
    return OverallIndication.monitor;
  }
}
