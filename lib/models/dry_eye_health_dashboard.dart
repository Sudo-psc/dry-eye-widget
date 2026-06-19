import 'package:flutter/foundation.dart';

enum DryEyeMetricKind {
  screenTime,
  osdi,
  eyeDrops,
  medications,
  sleep,
  averageHeartRate,
  symptoms,
  breakFrequency,
  twentyTwentyTwentyAdherence,
  clickCount,
  keystrokeCount,
  pauseCount,
  blinkSuggestions,
}

enum DryEyeMetricSource { app, healthKit, userReported, derived }

enum DryEyeMetricUnit {
  seconds,
  count,
  beatsPerMinute,
  osdiScore,
  percent,
  categorical,
  text,
}

enum DryEyeTimeGrain { day, week, month }

enum DryEyeAvailability {
  available,
  unavailable,
  notCollected,
  permissionDenied,
}

@immutable
class DryEyeMetricDefinition {
  const DryEyeMetricDefinition({
    required this.kind,
    required this.label,
    required this.preferredSource,
    required this.allowedSources,
    required this.unit,
    required this.defaultTimeGrain,
    required this.description,
    this.healthKitIdentifier,
    this.absenceLabel,
    this.privacyNote,
  });

  final DryEyeMetricKind kind;
  final String label;
  final DryEyeMetricSource preferredSource;
  final Set<DryEyeMetricSource> allowedSources;
  final DryEyeMetricUnit unit;
  final DryEyeTimeGrain defaultTimeGrain;
  final String description;
  final String? healthKitIdentifier;
  final String? absenceLabel;
  final String? privacyNote;

  bool get isHealthKitBacked =>
      allowedSources.contains(DryEyeMetricSource.healthKit);
}

@immutable
class DryEyeMetricValue {
  const DryEyeMetricValue({
    required this.kind,
    required this.source,
    required this.start,
    required this.end,
    required this.availability,
    this.numericValue,
    this.textValue,
    this.absenceReason,
    this.metadata = const <String, Object?>{},
  });

  final DryEyeMetricKind kind;
  final DryEyeMetricSource source;
  final DateTime start;
  final DateTime end;
  final DryEyeAvailability availability;
  final double? numericValue;
  final String? textValue;
  final String? absenceReason;
  final Map<String, Object?> metadata;

  bool get hasData => availability == DryEyeAvailability.available;

  factory DryEyeMetricValue.unavailable({
    required DryEyeMetricKind kind,
    required DryEyeMetricSource source,
    required DateTime start,
    required DateTime end,
    required DryEyeAvailability availability,
    required String reason,
  }) {
    return DryEyeMetricValue(
      kind: kind,
      source: source,
      start: start,
      end: end,
      availability: availability,
      absenceReason: reason,
    );
  }
}

@immutable
class DryEyeDashboardPeriod {
  const DryEyeDashboardPeriod({
    required this.start,
    required this.end,
    required this.grain,
    required this.values,
  });

  final DateTime start;
  final DateTime end;
  final DryEyeTimeGrain grain;
  final List<DryEyeMetricValue> values;

  Map<DryEyeMetricKind, DryEyeMetricValue> get byKind => {
    for (final value in values) value.kind: value,
  };

  List<DryEyeMetricValue> get missingValues =>
      values.where((value) => !value.hasData).toList(growable: false);
}

@immutable
class HealthKitImportPlan {
  const HealthKitImportPlan({
    required this.sleepIdentifier,
    required this.heartRateIdentifier,
    required this.screenTimeHealthKitIdentifier,
    required this.notes,
  });

  final String sleepIdentifier;
  final String heartRateIdentifier;
  final String? screenTimeHealthKitIdentifier;
  final String notes;
}

const healthKitImportPlan = HealthKitImportPlan(
  sleepIdentifier: 'HKCategoryTypeIdentifierSleepAnalysis',
  heartRateIdentifier: 'HKQuantityTypeIdentifierHeartRate',
  screenTimeHealthKitIdentifier: null,
  notes:
      'HealthKit supplies sleep analysis and heart-rate samples when the user '
      'grants read permission. Screen time is not modeled here as a HealthKit '
      'sample type; Dry Eye Widget uses its local active-screen-time history.',
);

const dryEyeDashboardMetricDefinitions = <DryEyeMetricDefinition>[
  DryEyeMetricDefinition(
    kind: DryEyeMetricKind.screenTime,
    label: 'Tempo de tela',
    preferredSource: DryEyeMetricSource.app,
    allowedSources: {DryEyeMetricSource.app},
    unit: DryEyeMetricUnit.seconds,
    defaultTimeGrain: DryEyeTimeGrain.day,
    description:
        'Tempo ativo de tela medido pelo Dry Eye Widget, descartando '
        'periodos de inatividade.',
    absenceLabel: 'Coleta de tempo de tela desativada ou sem dados no periodo.',
  ),
  DryEyeMetricDefinition(
    kind: DryEyeMetricKind.osdi,
    label: 'OSDI',
    preferredSource: DryEyeMetricSource.app,
    allowedSources: {DryEyeMetricSource.app},
    unit: DryEyeMetricUnit.osdiScore,
    defaultTimeGrain: DryEyeTimeGrain.day,
    description:
        'Pontuacao longitudinal do questionario OSDI salva localmente.',
    absenceLabel: 'Sem questionario OSDI preenchido no periodo.',
  ),
  DryEyeMetricDefinition(
    kind: DryEyeMetricKind.eyeDrops,
    label: 'Uso de colirios',
    preferredSource: DryEyeMetricSource.app,
    allowedSources: {DryEyeMetricSource.app, DryEyeMetricSource.userReported},
    unit: DryEyeMetricUnit.count,
    defaultTimeGrain: DryEyeTimeGrain.day,
    description:
        'Eventos de lembrete ou confirmacao de uso de colirio, quando '
        'registrados pelo app ou informados pelo usuario.',
    absenceLabel: 'Sem lembretes ou registros de uso de colirio no periodo.',
  ),
  DryEyeMetricDefinition(
    kind: DryEyeMetricKind.medications,
    label: 'Medicacoes',
    preferredSource: DryEyeMetricSource.userReported,
    allowedSources: {DryEyeMetricSource.userReported},
    unit: DryEyeMetricUnit.text,
    defaultTimeGrain: DryEyeTimeGrain.day,
    description:
        'Medicacoes relevantes ao olho seco informadas pelo usuario ou pelo '
        'clinico. Nao entra no MVP como leitura HealthKit.',
    absenceLabel: 'Nenhuma medicacao registrada.',
  ),
  DryEyeMetricDefinition(
    kind: DryEyeMetricKind.sleep,
    label: 'Sono',
    preferredSource: DryEyeMetricSource.healthKit,
    allowedSources: {DryEyeMetricSource.healthKit},
    unit: DryEyeMetricUnit.seconds,
    defaultTimeGrain: DryEyeTimeGrain.day,
    description:
        'Duracao de sono derivada de amostras autorizadas de sleep analysis.',
    healthKitIdentifier: 'HKCategoryTypeIdentifierSleepAnalysis',
    absenceLabel: 'Sono indisponivel, nao autorizado ou sem amostras.',
  ),
  DryEyeMetricDefinition(
    kind: DryEyeMetricKind.averageHeartRate,
    label: 'Frequencia cardiaca media',
    preferredSource: DryEyeMetricSource.healthKit,
    allowedSources: {DryEyeMetricSource.healthKit},
    unit: DryEyeMetricUnit.beatsPerMinute,
    defaultTimeGrain: DryEyeTimeGrain.day,
    description:
        'Media diaria de frequencia cardiaca a partir de amostras autorizadas.',
    healthKitIdentifier: 'HKQuantityTypeIdentifierHeartRate',
    absenceLabel:
        'Frequencia cardiaca indisponivel, nao autorizada ou sem amostras.',
  ),
  DryEyeMetricDefinition(
    kind: DryEyeMetricKind.symptoms,
    label: 'Sintomas',
    preferredSource: DryEyeMetricSource.userReported,
    allowedSources: {DryEyeMetricSource.userReported, DryEyeMetricSource.app},
    unit: DryEyeMetricUnit.categorical,
    defaultTimeGrain: DryEyeTimeGrain.day,
    description:
        'Sintomas informados pelo usuario e, quando aplicavel, resumidos pelo '
        'OSDI.',
    absenceLabel: 'Sem sintomas registrados no periodo.',
  ),
  DryEyeMetricDefinition(
    kind: DryEyeMetricKind.breakFrequency,
    label: 'Frequencia de pausas',
    preferredSource: DryEyeMetricSource.app,
    allowedSources: {DryEyeMetricSource.app, DryEyeMetricSource.derived},
    unit: DryEyeMetricUnit.count,
    defaultTimeGrain: DryEyeTimeGrain.day,
    description:
        'Quantidade de pausas sugeridas ou realizadas durante o periodo.',
    absenceLabel: 'Sem eventos de pausa registrados.',
  ),
  DryEyeMetricDefinition(
    kind: DryEyeMetricKind.twentyTwentyTwentyAdherence,
    label: 'Aderencia a regra 20-20-20',
    preferredSource: DryEyeMetricSource.derived,
    allowedSources: {DryEyeMetricSource.derived},
    unit: DryEyeMetricUnit.percent,
    defaultTimeGrain: DryEyeTimeGrain.day,
    description:
        'Percentual derivado entre pausas esperadas pelo tempo de tela e '
        'pausas realizadas ou concluídas.',
    absenceLabel: 'Sem dados suficientes para calcular aderencia.',
  ),
  DryEyeMetricDefinition(
    kind: DryEyeMetricKind.clickCount,
    label: 'Numero de cliques',
    preferredSource: DryEyeMetricSource.app,
    allowedSources: {DryEyeMetricSource.app},
    unit: DryEyeMetricUnit.count,
    defaultTimeGrain: DryEyeTimeGrain.day,
    description:
        'Contagem agregada futura de cliques durante uso ativo, sem '
        'coordenadas, conteudo ou historico de cursor.',
    absenceLabel: 'Metrica ainda nao coletada.',
    privacyNote:
        'Exige opt-in e deve permanecer agregada; nao registrar coordenadas.',
  ),
  DryEyeMetricDefinition(
    kind: DryEyeMetricKind.keystrokeCount,
    label: 'Numero de teclas digitadas',
    preferredSource: DryEyeMetricSource.app,
    allowedSources: {DryEyeMetricSource.app},
    unit: DryEyeMetricUnit.count,
    defaultTimeGrain: DryEyeTimeGrain.day,
    description:
        'Contagem agregada futura de teclas durante uso ativo, sem conteudo, '
        'sequencia, atalhos ou nomes de teclas.',
    absenceLabel: 'Metrica ainda nao coletada.',
    privacyNote:
        'Exige opt-in e deve contar apenas volume agregado, nunca conteudo.',
  ),
  DryEyeMetricDefinition(
    kind: DryEyeMetricKind.pauseCount,
    label: 'Numero de pausas',
    preferredSource: DryEyeMetricSource.app,
    allowedSources: {DryEyeMetricSource.app},
    unit: DryEyeMetricUnit.count,
    defaultTimeGrain: DryEyeTimeGrain.day,
    description: 'Total de pausas disparadas, iniciadas ou concluídas.',
    absenceLabel: 'Sem pausas registradas no periodo.',
  ),
  DryEyeMetricDefinition(
    kind: DryEyeMetricKind.blinkSuggestions,
    label: 'Numero de piscadas sugeridas',
    preferredSource: DryEyeMetricSource.app,
    allowedSources: {DryEyeMetricSource.app},
    unit: DryEyeMetricUnit.count,
    defaultTimeGrain: DryEyeTimeGrain.day,
    description:
        'Quantidade de microlembretes visuais ou sonoros de piscada sugeridos.',
    absenceLabel: 'Sem lembretes de piscada registrados no periodo.',
  ),
];

DryEyeMetricDefinition definitionFor(DryEyeMetricKind kind) =>
    dryEyeDashboardMetricDefinitions.firstWhere(
      (definition) => definition.kind == kind,
    );
