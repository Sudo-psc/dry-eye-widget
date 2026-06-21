import '../models/break_stats_data.dart';
import '../models/environment_checklist.dart';
import '../models/osdi_assessment.dart';
import '../models/report_options.dart';
import '../models/screen_time_data.dart';

/// Constrói o [ReportData] a partir dos dados brutos do app.
///
/// Camada **pura** (sem I/O, sem Flutter widgets) — todo o cálculo do relatório
/// vive aqui para ser facilmente testável: filtragem por período, médias,
/// adesão às pausas, variação do OSDI, derivação de sintomas a partir das
/// respostas OSDI, indicação geral e gatilhos de alerta educativo.
class ReportBuilder {
  const ReportBuilder();

  /// Limiares de tela (em segundos/dia) usados para indicação educativa.
  /// Revisar conforme evidência/posicionamento do produto.
  static const int highScreenTimeSeconds = 6 * 3600; // 6h/dia
  static const double lowAdherenceThreshold = 0.7; // < 70% de pausas concluídas

  /// Variação de escore OSDI considerada piora relevante (pontos).
  static const double relevantOsdiWorsening = 10;

  ReportData build({
    required UserProfile profile,
    required ReportOptions options,
    required List<OsdiAssessment> osdiHistory,
    required ScreenTimeData screenTime,
    required BreakStatsData breakStats,
    required List<String> symptomLabels,
    EnvironmentChecklist? environment,
    DateTime? now,
  }) {
    final generatedAt = now ?? DateTime.now();

    final osdi = _buildOsdiSummary(osdiHistory, options);
    final symptoms = options.includeSymptoms
        ? _buildSymptoms(osdi.history, symptomLabels)
        : const <SymptomStat>[];
    final screen = _buildScreenTimeSummary(screenTime, options);
    final breaks = _buildBreakSummary(breakStats, options);

    final alerts = _buildAlerts(osdi: osdi, symptoms: symptoms);
    final indication = _resolveIndication(
      osdi: osdi,
      symptoms: symptoms,
      screen: screen,
      breaks: breaks,
    );

    return ReportData(
      profile: profile,
      options: options,
      osdi: osdi,
      symptoms: symptoms,
      screenTime: screen,
      breaks: breaks,
      indication: indication,
      alerts: alerts,
      generatedAt: generatedAt,
      environment: options.includeEnvironment ? environment : null,
    );
  }

  // --- OSDI ---------------------------------------------------------------

  OsdiSummary _buildOsdiSummary(
    List<OsdiAssessment> history,
    ReportOptions options,
  ) {
    final filtered = history
        .where((e) => _inPeriod(e.completedAt, options))
        .toList()
      ..sort((a, b) => a.completedAt.compareTo(b.completedAt));

    OsdiAssessment? latest;
    OsdiAssessment? previous;
    if (filtered.isNotEmpty) {
      latest = filtered.last;
      if (filtered.length > 1) previous = filtered[filtered.length - 2];
    }
    return OsdiSummary(history: filtered, latest: latest, previous: previous);
  }

  // --- Sintomas (derivados das respostas OSDI) ----------------------------

  List<SymptomStat> _buildSymptoms(
    List<OsdiAssessment> history,
    List<String> labels,
  ) {
    if (labels.isEmpty) return const [];
    final result = <SymptomStat>[];

    for (var q = 0; q < labels.length; q++) {
      final answered = <int>[]; // respostas não nulas
      final firstHalf = <int>[];
      final secondHalf = <int>[];
      final mid = history.length ~/ 2;

      for (var i = 0; i < history.length; i++) {
        final answers = history[i].answers;
        if (q >= answers.length) continue;
        final value = answers[q];
        if (value == null) continue;
        answered.add(value);
        if (history.length > 1) {
          (i < mid ? firstHalf : secondHalf).add(value);
        }
      }

      final frequency = answered.where((v) => v > 0).length;
      final averageIntensity = answered.isEmpty
          ? 0.0
          : answered.reduce((a, b) => a + b) / answered.length;
      final trend = _symptomTrend(firstHalf, secondHalf);

      result.add(
        SymptomStat(
          label: labels[q],
          frequency: frequency,
          averageIntensity: averageIntensity,
          trend: trend,
        ),
      );
    }
    return result;
  }

  SymptomTrend _symptomTrend(List<int> firstHalf, List<int> secondHalf) {
    if (firstHalf.isEmpty || secondHalf.isEmpty) return SymptomTrend.unknown;
    final a = firstHalf.reduce((x, y) => x + y) / firstHalf.length;
    final b = secondHalf.reduce((x, y) => x + y) / secondHalf.length;
    final diff = b - a;
    if (diff > 0.5) return SymptomTrend.worsening;
    if (diff < -0.5) return SymptomTrend.improving;
    return SymptomTrend.stable;
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
    required OsdiSummary osdi,
    required List<SymptomStat> symptoms,
  }) {
    final alerts = <String>[];
    final latest = osdi.latest;

    if (latest != null &&
        (latest.severity == OsdiSeverity.moderate ||
            latest.severity == OsdiSeverity.severe)) {
      alerts.add('Escore OSDI em faixa elevada na avaliação mais recente.');
    }
    final variation = osdi.variation;
    if (variation != null && variation >= relevantOsdiWorsening) {
      alerts.add(
        'Piora relevante do escore OSDI (+${variation.toStringAsFixed(1)} pontos) '
        'em relação à avaliação anterior.',
      );
    }

    // Sintomas de alerta (dor, fotofobia/sensibilidade à luz, embaçamento)
    // persistentes. Mapeados pelos índices canônicos do OSDI: 0=luz, 2=dor,
    // 3=visão embaçada.
    void flagSymptom(int index, String message) {
      if (index < symptoms.length && symptoms[index].frequency >= 2) {
        alerts.add(message);
      }
    }

    flagSymptom(2, 'Dor ou desconforto ocular registrado de forma recorrente.');
    flagSymptom(0, 'Sensibilidade à luz (fotofobia) registrada de forma recorrente.');
    flagSymptom(3, 'Visão embaçada registrada de forma recorrente.');

    return alerts;
  }

  OverallIndication _resolveIndication({
    required OsdiSummary osdi,
    required List<SymptomStat> symptoms,
    required ScreenTimeSummary screen,
    required BreakSummary breaks,
  }) {
    final latest = osdi.latest;
    final variation = osdi.variation;

    final highOsdi = latest != null &&
        (latest.severity == OsdiSeverity.moderate ||
            latest.severity == OsdiSeverity.severe);
    final worsened = variation != null && variation >= relevantOsdiWorsening;

    final frequentSymptoms = symptoms.where((s) => s.frequency >= 2).length >= 2;
    final highScreen = screen.averageDailySeconds >= highScreenTimeSeconds;
    final lowAdherence = breaks.adherenceRate != null &&
        breaks.adherenceRate! < lowAdherenceThreshold;

    if (highOsdi ||
        worsened ||
        (highScreen && lowAdherence && frequentSymptoms)) {
      return OverallIndication.seekEvaluation;
    }
    if (lowAdherence || highScreen) {
      return OverallIndication.reinforceBreaks;
    }
    return OverallIndication.monitor;
  }

  // --- Helpers ------------------------------------------------------------

  bool _inPeriod(DateTime date, ReportOptions options) {
    final start = DateTime(
      options.startDate.year,
      options.startDate.month,
      options.startDate.day,
    );
    final end = DateTime(
      options.endDate.year,
      options.endDate.month,
      options.endDate.day,
    ).add(const Duration(days: 1));
    return !date.isBefore(start) && date.isBefore(end);
  }
}
