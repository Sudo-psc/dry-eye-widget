import 'package:flutter/foundation.dart';

import 'dvrs_assessment.dart';
import 'environment_checklist.dart';
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
    this.includeDvrs = true,
    this.includeScreenTime = true,
    this.includeBreaks = true,
    this.includeEnvironment = false,
  });

  final DateTime startDate;
  final DateTime endDate;
  final ReportPeriod period;

  /// Inclui a seção do DVRS (questionário principal).
  final bool includeDvrs;
  final bool includeScreenTime;
  final bool includeBreaks;
  final bool includeEnvironment;

  /// Quantidade de dias cobertos pelo intervalo (mínimo 1).
  int get days {
    final diff = endDate.difference(startDate).inDays;
    return diff < 1 ? 1 : diff;
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

/// Dados do DVRS preparados para o relatório PDF.
@immutable
class DvrsReportData {
  const DvrsReportData({required this.latest, required this.history});

  /// Resultado mais recente (exibido em destaque).
  final DvrsResult latest;

  /// Histórico ordenado (antigo → recente) para a curva de evolução.
  final List<DvrsResult> history;

  bool get hasEvolution => history.length >= 2;
}

/// Pacote completo, já calculado, pronto para renderização do PDF e da prévia.
@immutable
class ReportData {
  const ReportData({
    required this.profile,
    required this.options,
    required this.screenTime,
    required this.breaks,
    required this.indication,
    required this.alerts,
    required this.generatedAt,
    this.dvrs,
    this.environment,
  });

  /// Dados do DVRS (questionário principal). `null` se não houver resultados.
  final DvrsReportData? dvrs;

  final UserProfile profile;
  final ReportOptions options;
  final ScreenTimeSummary screenTime;
  final BreakSummary breaks;

  /// Checklist ambiental autorreferido (opcional).
  final EnvironmentChecklist? environment;

  /// Indicação geral educativa (acompanhar / reforçar pausas / avaliação).
  final OverallIndication indication;

  /// Gatilhos educativos para a seção "Quando procurar avaliação oftalmológica".
  final List<String> alerts;

  final DateTime generatedAt;
}
