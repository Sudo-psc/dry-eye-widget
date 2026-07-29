import '../models/dvrs_assessment.dart';
import '../models/report_options.dart';

/// Engine PURO de cálculo, classificação, mensagens e alertas do DVRS.
///
/// Não faz I/O e nunca chama `DateTime.now()`/`Random`: tudo é recebido por
/// parâmetro. Toda a saída é educativa e de TRIAGEM — nunca diagnóstica.
/// Totalmente testável isoladamente.

/// Pesos de cada domínio na fórmula final (somam 1.0).
const Map<DvrsDomain, double> kDvrsDomainWeights = {
  DvrsDomain.symptoms: 0.35,
  DvrsDomain.functional: 0.25,
  DvrsDomain.exposure: 0.20,
  DvrsDomain.environment: 0.15,
  DvrsDomain.warning: 0.05,
};

/// Pontuação máxima possível por pergunta.
const int _maxPerQuestion = 4;

/// Calcula os scores normalizados (0–100) de cada domínio.
///
/// Para cada domínio: `soma / (nº de perguntas no domínio * 4) * 100`. Domínios
/// sem respostas resultam em 0 (evita divisão por zero).
DvrsDomainScores calculateDvrsDomainScores(List<DvrsAnswer> answers) {
  final sums = <DvrsDomain, int>{};
  final counts = <DvrsDomain, int>{};
  for (final answer in answers) {
    sums[answer.domain] = (sums[answer.domain] ?? 0) + answer.value;
    counts[answer.domain] = (counts[answer.domain] ?? 0) + 1;
  }

  double normalize(DvrsDomain domain) {
    final count = counts[domain] ?? 0;
    if (count == 0) return 0;
    final max = count * _maxPerQuestion;
    return (sums[domain] ?? 0) / max * 100;
  }

  return DvrsDomainScores(
    symptoms: normalize(DvrsDomain.symptoms),
    functional: normalize(DvrsDomain.functional),
    exposure: normalize(DvrsDomain.exposure),
    environment: normalize(DvrsDomain.environment),
    warning: normalize(DvrsDomain.warning),
  );
}

/// Aplica os pesos aos scores normalizados e devolve o score final 0–100.
int calculateDvrsTotalScore(DvrsDomainScores scores) {
  var total = 0.0;
  for (final entry in kDvrsDomainWeights.entries) {
    total += entry.value * scores.valueFor(entry.key);
  }
  final rounded = total.round();
  return rounded.clamp(0, 100);
}

/// Classifica o score final 0–100 em uma das cinco faixas.
DvrsClassification classifyDvrs(int totalScore) {
  if (totalScore <= 19) return DvrsClassification.low;
  if (totalScore <= 39) return DvrsClassification.mildAttention;
  if (totalScore <= 59) return DvrsClassification.moderateRisk;
  if (totalScore <= 79) return DvrsClassification.highRisk;
  return DvrsClassification.veryHighRisk;
}

/// Alerta de segurança clínica derivado da resposta da pergunta 16 (0–4).
///
/// Independe do score total (regra de segurança da especificação):
/// 0–1 → nenhum · 2 → atenção · 3 → avaliação médica · 4 → prioritária.
DvrsSafetyAlert getDvrsSafetyAlert(int answerQ16) {
  final DvrsSafetyAlertLevel level;
  if (answerQ16 >= 4) {
    level = DvrsSafetyAlertLevel.priorityEvaluation;
  } else if (answerQ16 == 3) {
    level = DvrsSafetyAlertLevel.medicalEvaluation;
  } else if (answerQ16 == 2) {
    level = DvrsSafetyAlertLevel.attention;
  } else {
    level = DvrsSafetyAlertLevel.none;
  }
  return DvrsSafetyAlert(level: level);
}

/// Avalia um conjunto completo de 16 respostas e devolve o [DvrsResult].
///
/// Exige exatamente 16 respostas (uma por pergunta). O alerta de segurança é
/// computado a partir da resposta do domínio de sinais de alerta (Q16) e
/// independe do score total.
DvrsResult evaluateDvrs({
  required List<DvrsAnswer> answers,
  required String id,
  required DateTime now,
  String? userId,
  bool includeInPdf = false,
}) {
  if (answers.length != 16) {
    throw ArgumentError.value(
      answers.length,
      'answers.length',
      'O DVRS exige exatamente 16 respostas.',
    );
  }

  final domainScores = calculateDvrsDomainScores(answers);
  final totalScore = calculateDvrsTotalScore(domainScores);
  final classification = classifyDvrs(totalScore);

  final warningAnswer = answers.firstWhere(
    (a) => a.domain == DvrsDomain.warning,
    orElse: () => throw ArgumentError(
      'O DVRS exige uma resposta do domínio de sinais de alerta.',
    ),
  );
  final alert = getDvrsSafetyAlert(warningAnswer.value);

  return DvrsResult(
    id: id,
    userId: userId,
    createdAt: now,
    answers: List<DvrsAnswer>.unmodifiable(answers),
    domainScores: domainScores,
    totalScore: totalScore,
    classification: classification,
    classificationLabel: classification.label,
    safetyAlertLevel: alert.level,
    includeInPdf: includeInPdf,
  );
}

/// Prepara os dados do DVRS para o relatório PDF a partir do histórico.
///
/// Devolve `null` se [history] estiver vazio. O resultado mais recente é o
/// último elemento (o histórico deve vir ordenado antigo → recente).
DvrsReportData? prepareDvrsForPdf(List<DvrsResult> history) {
  if (history.isEmpty) return null;
  final sorted = [...history]
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  return DvrsReportData(latest: sorted.last, history: sorted);
}
