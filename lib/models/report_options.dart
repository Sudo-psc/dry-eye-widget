import 'package:flutter/foundation.dart';

import 'osdi_assessment.dart';
import 'screen_time_data.dart';

/// Período pré-definido do relatório. [custom] usa um intervalo de datas livre.
enum ReportPeriod { last7, last30, last90, custom }

extension ReportPeriodDays on ReportPeriod {
  /// Número de dias do período pré-definido (`null` para [custom]).
  int? get days => switch (this) {
    ReportPeriod.last7 => 7,
    ReportPeriod.last30 => 30,
    ReportPeriod.last90 => 90,
    ReportPeriod.custom => null,
  };
}

/// Indicação geral, educativa e não diagnóstica, exibida no resumo executivo.
enum OverallIndication { monitor, reinforceBreaks, seekEvaluation }

/// Tendência de um sintoma ao longo do período analisado.
enum SymptomTrend { improving, stable, worsening, unknown }

@immutable
class UserProfile {
  const UserProfile({
    this.name,
    this.observations,
    this.age,
    this.email,
  });

  final String? name;
  final String? observations;
  final int? age;
  final String? email;

  bool get hasName => name != null && name!.trim().isNotEmpty;
  bool get hasObservations =>
      observations != null && observations!.trim().isNotEmpty;
}

@immutable
class ReportOptions {
  const ReportOptions({
    required this.startDate,
    required this.endDate,
    this.period = ReportPeriod.last30,
    this.includeOsdi = true,
    this.includeScreenTime = true,
    this.includeBreaks = true,
    this.includeSymptoms = true,
    this.includeEnvironment = false,
  });

  final DateTime startDate;
  final DateTime endDate;
  final ReportPeriod period;
  final bool includeOsdi;
  final bool includeScreenTime;
  final bool includeBreaks;
  final bool includeSymptoms;
  final bool includeEnvironment;

  /// Quantidade de dias cobertos pelo intervalo (mínimo 1).
  int get days {
    final diff = endDate.difference(startDate).inDays;
    return diff < 1 ? 1 : diff;
  }
}

/// Estatística agregada de um sintoma derivado das respostas OSDI.
@immutable
class SymptomStat {
  const SymptomStat({
    required this.label,
    required this.frequency,
    required this.averageIntensity,
    required this.trend,
  });

  /// Rótulo do sintoma (texto da pergunta OSDI correspondente).
  final String label;

  /// Em quantas avaliações o sintoma esteve presente (resposta > 0).
  final int frequency;

  /// Intensidade média (0–4) considerando as avaliações respondidas.
  final double averageIntensity;

  final SymptomTrend trend;
}

/// Resumo do escore OSDI no período.
@immutable
class OsdiSummary {
  const OsdiSummary({
    required this.history,
    this.latest,
    this.previous,
  });

  final List<OsdiAssessment> history;
  final OsdiAssessment? latest;
  final OsdiAssessment? previous;

  bool get hasData => history.isNotEmpty;

  /// Variação absoluta do escore (atual − anterior); `null` sem base de comparação.
  double? get variation =>
      (latest != null && previous != null) ? latest!.score - previous!.score : null;

  /// Variação percentual em relação ao escore anterior; `null` se não calculável.
  double? get variationPercent {
    if (latest == null || previous == null || previous!.score == 0) return null;
    return (latest!.score - previous!.score) / previous!.score * 100;
  }
}

/// Resumo de tempo de tela no período.
@immutable
class ScreenTimeSummary {
  const ScreenTimeSummary({
    required this.series,
    required this.totalSeconds,
    required this.averageDailySeconds,
    required this.daysWithData,
    required this.weekdayAverageSeconds,
    required this.weekendAverageSeconds,
    this.peakDay,
  });

  final List<ScreenTimePoint> series;
  final int totalSeconds;
  final int averageDailySeconds;
  final int daysWithData;
  final int weekdayAverageSeconds;
  final int weekendAverageSeconds;
  final ScreenTimePoint? peakDay;

  bool get hasData => totalSeconds > 0;
}

/// Resumo de adesão às pausas visuais no período.
@immutable
class BreakSummary {
  const BreakSummary({
    required this.reminders,
    required this.completed,
  });

  final int reminders;
  final int completed;

  int get skipped => (reminders - completed).clamp(0, reminders);

  bool get hasData => reminders > 0 || completed > 0;

  /// Taxa de adesão (concluídas / lembretes); `null` sem lembretes.
  double? get adherenceRate => reminders > 0 ? completed / reminders : null;
}

/// Pacote completo, já calculado, pronto para renderização do PDF e da prévia.
@immutable
class ReportData {
  const ReportData({
    required this.profile,
    required this.options,
    required this.osdi,
    required this.symptoms,
    required this.screenTime,
    required this.breaks,
    required this.indication,
    required this.alerts,
    required this.generatedAt,
  });

  final UserProfile profile;
  final ReportOptions options;
  final OsdiSummary osdi;
  final List<SymptomStat> symptoms;
  final ScreenTimeSummary screenTime;
  final BreakSummary breaks;

  /// Indicação geral educativa (acompanhar / reforçar pausas / avaliação).
  final OverallIndication indication;

  /// Gatilhos educativos para a seção "Quando procurar avaliação oftalmológica".
  final List<String> alerts;

  final DateTime generatedAt;

  /// Sintoma mais frequente no período, se houver.
  SymptomStat? get topSymptom {
    if (symptoms.isEmpty) return null;
    final present = symptoms.where((s) => s.frequency > 0).toList()
      ..sort((a, b) => b.frequency.compareTo(a.frequency));
    return present.isEmpty ? null : present.first;
  }
}
