import '../models/checklist.dart';
import '../models/checklist_definitions.dart';

/// Engine PURO de cálculo, classificação e feedback dos checklists.
///
/// Não faz I/O e nunca chama `DateTime.now()`/`Random`: tudo é recebido por
/// parâmetro. Toda a linguagem produzida é educativa e de TRIAGEM — nunca
/// diagnóstica.

/// Soma a pontuação de uma lista de respostas.
int calculateChecklistScore(List<ChecklistAnswer> answers) {
  var total = 0;
  for (final answer in answers) {
    total += answer.score;
  }
  return total;
}

/// `true` se há ao menos um item crítico marcado (resposta com score > 0) entre
/// as perguntas críticas de [def].
bool hasMarkedCritical(ChecklistDefinition def, List<ChecklistAnswer> answers) {
  final criticalIds = <String>{
    for (final q in def.questions)
      if (q.critical) q.id,
  };
  if (criticalIds.isEmpty) return false;
  for (final answer in answers) {
    if (answer.score > 0 && criticalIds.contains(answer.questionId)) {
      return true;
    }
  }
  return false;
}

/// Classifica [score] na faixa correspondente de [def].
///
/// Se nenhuma faixa cobrir o score (definição incompleta), devolve a faixa mais
/// próxima por extremidade, evitando crash.
RiskBand classifyChecklistRisk(ChecklistDefinition def, int score) {
  for (final band in def.bands) {
    if (band.contains(score)) return band;
  }
  // Fallback defensivo: abaixo da primeira ou acima da última faixa.
  final bands = def.bands;
  if (bands.isEmpty) {
    return const RiskBand(
      minScore: 0,
      maxScore: 9999,
      level: ChecklistRiskLevel.low,
      classification: 'Sem classificação',
      feedback:
          'Não foi possível classificar este resultado. Acompanhe a evolução '
          'e, se necessário, considere avaliação oftalmológica. Este resultado '
          'não substitui consulta médica.',
    );
  }
  if (score < bands.first.minScore) return bands.first;
  return bands.last;
}

/// Avalia um questionário (módulos 1–5) e devolve o [ChecklistResult].
///
/// Para [ChecklistType.warningSigns], se houver qualquer item crítico marcado,
/// o resultado é elevado a [ChecklistRiskLevel.urgentAttention] com o feedback
/// de atenção prioritária.
ChecklistResult evaluate({
  required ChecklistDefinition def,
  required List<ChecklistAnswer> answers,
  required String id,
  required DateTime now,
  bool includeInPdf = false,
}) {
  final score = calculateChecklistScore(answers);
  final band = classifyChecklistRisk(def, score);

  var level = band.level;
  var classification = band.classification;
  var feedback = band.feedback;

  if (def.type == ChecklistType.warningSigns &&
      hasMarkedCritical(def, answers)) {
    level = ChecklistRiskLevel.urgentAttention;
    classification = kWarningSignsUrgentClassification;
    feedback = kWarningSignsUrgentFeedback;
  }

  return ChecklistResult(
    id: id,
    type: def.type,
    createdAt: now,
    answers: List<ChecklistAnswer>.unmodifiable(answers),
    totalScore: score,
    riskLevel: level,
    classification: classification,
    feedback: feedback,
    includeInPdf: includeInPdf,
    version: def.version,
  );
}

/// Aviso fixo anexado a todo resultado de triagem.
const String kTriageDisclaimer =
    'Esta triagem não confirma diagnóstico e não substitui consulta médica.';

/// Módulo 6: triagem combinada.
///
/// Cruza os dados disponíveis (OSDI, sintomas, sinais de alerta, tempo de tela,
/// adesão a pausas) e devolve um de quatro desfechos de triagem. Os dados são
/// todos opcionais; o desfecho usa o que estiver disponível.
///
/// Regras (em ordem de prioridade):
/// - Qualquer crítico em sinais de alerta OU OSDI muito alto → urgente.
/// - Sintomas frequentes/relevantes OU risco aumentado → considerar avaliação.
/// - Sinais de sobrecarga (atenção em sintomas, tempo de tela alto, baixa
///   adesão) → atenção.
/// - Caso contrário → acompanhamento habitual.
ChecklistResult buildTriage({
  required String id,
  required DateTime now,
  double? latestOsdiScore,
  ChecklistResult? symptoms,
  ChecklistResult? warningSigns,
  int? avgScreenSecondsPerDay,
  double? breakAdherence,
  bool includeInPdf = false,
}) {
  ChecklistRiskLevel level;
  String classification;
  String feedback;

  final warningUrgent =
      warningSigns?.riskLevel == ChecklistRiskLevel.urgentAttention;
  final osdiVeryHigh = latestOsdiScore != null && latestOsdiScore >= 33;

  final symptomsHigh = symptoms != null &&
      (symptoms.riskLevel == ChecklistRiskLevel.increased ||
          symptoms.riskLevel == ChecklistRiskLevel.recommendedEvaluation);
  final osdiModerate = latestOsdiScore != null &&
      latestOsdiScore >= 23 &&
      latestOsdiScore < 33;

  final symptomsAttention =
      symptoms?.riskLevel == ChecklistRiskLevel.attention;
  final warningAttention = warningSigns != null &&
      (warningSigns.riskLevel == ChecklistRiskLevel.attention ||
          warningSigns.riskLevel == ChecklistRiskLevel.increased);
  final screenHigh = avgScreenSecondsPerDay != null &&
      avgScreenSecondsPerDay >= 6 * 3600;
  final lowAdherence = breakAdherence != null && breakAdherence < 0.4;

  if (warningUrgent || osdiVeryHigh) {
    level = ChecklistRiskLevel.urgentAttention;
    classification = 'Procurar avaliação com prioridade';
    feedback =
        'Os sinais reunidos sugerem procurar avaliação oftalmológica com '
        'prioridade. $kTriageDisclaimer';
  } else if (symptomsHigh || osdiModerate) {
    level = ChecklistRiskLevel.recommendedEvaluation;
    classification = 'Considerar avaliação';
    feedback =
        'Os dados disponíveis indicam risco visual aumentado. Considere '
        'avaliação oftalmológica para entender melhor o quadro e acompanhe a '
        'evolução. $kTriageDisclaimer';
  } else if (symptomsAttention ||
      warningAttention ||
      screenHigh ||
      lowAdherence) {
    level = ChecklistRiskLevel.attention;
    classification = 'Atenção';
    feedback =
        'Há sinais de sobrecarga visual. Revise seu ambiente de trabalho, '
        'reforce as pausas e acompanhe a evolução. $kTriageDisclaimer';
  } else {
    level = ChecklistRiskLevel.low;
    classification = 'Acompanhamento habitual';
    feedback =
        'No momento, os dados disponíveis sugerem acompanhamento habitual. '
        'Mantenha seus cuidados visuais e acompanhe a evolução. '
        '$kTriageDisclaimer';
  }

  return ChecklistResult(
    id: id,
    type: ChecklistType.ophthalmologyTriage,
    createdAt: now,
    answers: const [],
    totalScore: 0,
    riskLevel: level,
    classification: classification,
    feedback: feedback,
    includeInPdf: includeInPdf,
    version: '1',
  );
}

/// Converte um nível para um "peso" comparável (maior = mais atenção).
int _levelWeight(ChecklistRiskLevel? level) {
  switch (level) {
    case ChecklistRiskLevel.low:
      return 0;
    case ChecklistRiskLevel.attention:
      return 1;
    case ChecklistRiskLevel.increased:
      return 2;
    case ChecklistRiskLevel.recommendedEvaluation:
      return 3;
    case ChecklistRiskLevel.urgentAttention:
      return 4;
    case null:
      return -1;
  }
}

/// Mapeia um peso de volta para um nível.
ChecklistRiskLevel _levelFromWeight(int weight) {
  if (weight >= 4) return ChecklistRiskLevel.urgentAttention;
  if (weight == 3) return ChecklistRiskLevel.recommendedEvaluation;
  if (weight == 2) return ChecklistRiskLevel.increased;
  if (weight == 1) return ChecklistRiskLevel.attention;
  return ChecklistRiskLevel.low;
}

/// Classifica o tempo de tela (segundos/dia) em um nível de risco simples.
ChecklistRiskLevel? _screenTimeLevel(int? avgScreenSecondsPerDay) {
  if (avgScreenSecondsPerDay == null) return null;
  if (avgScreenSecondsPerDay >= 8 * 3600) return ChecklistRiskLevel.increased;
  if (avgScreenSecondsPerDay >= 6 * 3600) return ChecklistRiskLevel.attention;
  return ChecklistRiskLevel.low;
}

/// Classifica a adesão a pausas (0..1) em um nível de risco simples.
ChecklistRiskLevel? _adherenceLevel(double? breakAdherence) {
  if (breakAdherence == null) return null;
  if (breakAdherence < 0.4) return ChecklistRiskLevel.increased;
  if (breakAdherence < 0.7) return ChecklistRiskLevel.attention;
  return ChecklistRiskLevel.low;
}

/// Módulo 7: resumo de risco visual.
///
/// Agrega os últimos resultados de cada módulo + OSDI + tempo de tela + adesão
/// em um panorama único, devolvendo nível geral e frase-resumo não-alarmista.
VisualRiskSummary buildVisualRiskSummary({
  required DateTime now,
  ChecklistResult? ergonomics,
  ChecklistResult? environment,
  ChecklistResult? symptoms,
  ChecklistResult? warningSigns,
  ChecklistResult? breakHabits,
  double? latestOsdiScore,
  int? avgScreenSecondsPerDay,
  double? breakAdherence,
  ChecklistTrend? trend,
}) {
  final screenTimeRisk = _screenTimeLevel(avgScreenSecondsPerDay);
  final adherenceRisk = breakHabits?.riskLevel ?? _adherenceLevel(breakAdherence);

  ChecklistRiskLevel? osdiRisk;
  if (latestOsdiScore != null) {
    if (latestOsdiScore >= 33) {
      osdiRisk = ChecklistRiskLevel.increased;
    } else if (latestOsdiScore >= 23) {
      osdiRisk = ChecklistRiskLevel.attention;
    } else if (latestOsdiScore >= 13) {
      osdiRisk = ChecklistRiskLevel.attention;
    } else {
      osdiRisk = ChecklistRiskLevel.low;
    }
  }

  final levels = <ChecklistRiskLevel?>[
    ergonomics?.riskLevel,
    environment?.riskLevel,
    symptoms?.riskLevel,
    warningSigns?.riskLevel,
    adherenceRisk,
    screenTimeRisk,
    osdiRisk,
  ];

  var maxWeight = -1;
  for (final level in levels) {
    final w = _levelWeight(level);
    if (w > maxWeight) maxWeight = w;
  }

  final ChecklistRiskLevel overall =
      maxWeight < 0 ? ChecklistRiskLevel.low : _levelFromWeight(maxWeight);

  String summaryText;
  String recommendation;
  switch (overall) {
    case ChecklistRiskLevel.low:
      summaryText =
          'Seu panorama visual está estável no momento, com poucos sinais de '
          'atenção.';
      recommendation =
          'Mantenha seus cuidados visuais e acompanhe a evolução.';
      break;
    case ChecklistRiskLevel.attention:
      summaryText =
          'Alguns indicadores apontam sinais de atenção no seu uso de telas.';
      recommendation =
          'Revise seu ambiente de trabalho e reforce as pausas; acompanhe a '
          'evolução.';
      break;
    case ChecklistRiskLevel.increased:
      summaryText =
          'Vários indicadores apontam risco visual aumentado relacionado ao '
          'uso de telas.';
      recommendation =
          'Considere avaliação oftalmológica e revise seus hábitos visuais. '
          'Este resultado não substitui consulta médica.';
      break;
    case ChecklistRiskLevel.recommendedEvaluation:
      summaryText =
          'O conjunto dos seus indicadores sugere risco visual aumentado.';
      recommendation =
          'Considere avaliação oftalmológica para entender melhor o quadro. '
          'Este resultado não substitui consulta médica.';
      break;
    case ChecklistRiskLevel.urgentAttention:
      summaryText =
          'Há sinais que merecem atenção prioritária no seu panorama visual.';
      recommendation =
          'Considere procurar avaliação oftalmológica com prioridade. Este '
          'resultado não substitui consulta médica.';
      break;
  }

  return VisualRiskSummary(
    createdAt: now,
    ergonomicRisk: ergonomics?.riskLevel,
    environmentRisk: environment?.riskLevel,
    symptomsRisk: symptoms?.riskLevel,
    warningSignsRisk: warningSigns?.riskLevel,
    breakAdherenceRisk: adherenceRisk,
    screenTimeRisk: screenTimeRisk,
    latestOsdiScore: latestOsdiScore,
    trend: trend,
    overallLevel: overall,
    summaryText: summaryText,
    recommendation: recommendation,
  );
}

/// Compara dois resultados do mesmo tipo e devolve a variação de score
/// (current - previous), ou `null` se não houver [previous].
///
/// Para a interpretação como tendência, use [compareChecklistTrend].
int? compareChecklistResults(
  ChecklistResult? previous,
  ChecklistResult current,
) {
  if (previous == null) return null;
  return current.totalScore - previous.totalScore;
}

/// Converte a variação de score em uma tendência.
///
/// Para a maioria dos módulos, score MAIOR = mais risco, logo aumento de score
/// significa piora. [margin] cria uma zona morta para "estável".
ChecklistTrend? compareChecklistTrend(
  ChecklistResult? previous,
  ChecklistResult current, {
  int margin = 1,
}) {
  final delta = compareChecklistResults(previous, current);
  if (delta == null) return null;
  if (delta > margin) return ChecklistTrend.worsening;
  if (delta < -margin) return ChecklistTrend.improving;
  return ChecklistTrend.stable;
}
