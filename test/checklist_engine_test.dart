import 'package:dry_eye_widget/models/checklist.dart';
import 'package:dry_eye_widget/models/checklist_definitions.dart';
import 'package:dry_eye_widget/services/checklist_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper: cria a lista de respostas escolhendo, para cada pergunta de [def],
/// o índice de opção indicado em [optionIndexes]. Perguntas sem entrada
/// (mapa parcial) ficam sem resposta — simula checklist incompleto.
List<ChecklistAnswer> _answersFor(
  ChecklistDefinition def,
  Map<String, int> optionIndexes,
) {
  final answers = <ChecklistAnswer>[];
  for (final q in def.questions) {
    final idx = optionIndexes[q.id];
    if (idx == null) continue;
    answers.add(
      ChecklistAnswer(
        questionId: q.id,
        score: q.options[idx].score,
        optionIndex: idx,
      ),
    );
  }
  return answers;
}

/// Helper: responde [count] perguntas com a opção [optionIndex].
List<ChecklistAnswer> _firstN(
  ChecklistDefinition def,
  int count,
  int optionIndex,
) {
  final answers = <ChecklistAnswer>[];
  for (var i = 0; i < count && i < def.questions.length; i++) {
    final q = def.questions[i];
    answers.add(
      ChecklistAnswer(
        questionId: q.id,
        score: q.options[optionIndex].score,
        optionIndex: optionIndex,
      ),
    );
  }
  return answers;
}

void main() {
  final now = DateTime.utc(2026, 6, 21, 10);
  const id = 'test-id';

  group('calculateChecklistScore', () {
    test('soma os scores das respostas', () {
      final answers = [
        const ChecklistAnswer(questionId: 'a', score: 2, optionIndex: 2),
        const ChecklistAnswer(questionId: 'b', score: 3, optionIndex: 3),
        const ChecklistAnswer(questionId: 'c', score: 0, optionIndex: 0),
      ];
      expect(calculateChecklistScore(answers), 5);
    });

    test('lista vazia soma zero', () {
      expect(calculateChecklistScore(const []), 0);
    });
  });

  group('classifyChecklistRisk por faixa (módulos 1-5)', () {
    test('ergonomia: baixo / atenção / aumentado', () {
      final def = kChecklistDefinitions[ChecklistType.visualErgonomics]!;
      expect(classifyChecklistRisk(def, 0).level, ChecklistRiskLevel.low);
      expect(classifyChecklistRisk(def, 2).level, ChecklistRiskLevel.low);
      expect(classifyChecklistRisk(def, 3).level, ChecklistRiskLevel.attention);
      expect(classifyChecklistRisk(def, 5).level, ChecklistRiskLevel.attention);
      expect(classifyChecklistRisk(def, 6).level, ChecklistRiskLevel.increased);
      expect(classifyChecklistRisk(def, 12).level, ChecklistRiskLevel.increased);
    });

    test('ambiente: favorável / atenção / aumentado', () {
      final def = kChecklistDefinitions[ChecklistType.screenEnvironment]!;
      expect(classifyChecklistRisk(def, 1).level, ChecklistRiskLevel.low);
      expect(classifyChecklistRisk(def, 4).level, ChecklistRiskLevel.attention);
      expect(classifyChecklistRisk(def, 8).level, ChecklistRiskLevel.increased);
    });

    test('sintomas: 4 faixas incluindo recommendedEvaluation', () {
      final def = kChecklistDefinitions[ChecklistType.visualSymptoms]!;
      expect(classifyChecklistRisk(def, 5).level, ChecklistRiskLevel.low);
      expect(classifyChecklistRisk(def, 20).level, ChecklistRiskLevel.attention);
      expect(
        classifyChecklistRisk(def, 30).level,
        ChecklistRiskLevel.increased,
      );
      expect(
        classifyChecklistRisk(def, 45).level,
        ChecklistRiskLevel.recommendedEvaluation,
      );
    });

    test('sinais de alerta: faixas por contagem', () {
      final def = kChecklistDefinitions[ChecklistType.warningSigns]!;
      expect(classifyChecklistRisk(def, 0).level, ChecklistRiskLevel.low);
      expect(classifyChecklistRisk(def, 2).level, ChecklistRiskLevel.attention);
      expect(classifyChecklistRisk(def, 4).level, ChecklistRiskLevel.increased);
    });

    test('pausas e hábitos: mapeia para low/attention/increased', () {
      final def = kChecklistDefinitions[ChecklistType.breakHabits]!;
      expect(classifyChecklistRisk(def, 1).level, ChecklistRiskLevel.low);
      expect(classifyChecklistRisk(def, 4).level, ChecklistRiskLevel.attention);
      expect(classifyChecklistRisk(def, 7).level, ChecklistRiskLevel.increased);
      expect(classifyChecklistRisk(def, 10).level, ChecklistRiskLevel.increased);
    });
  });

  group('evaluate', () {
    test('módulo de ergonomia gera resultado coerente', () {
      final def = kChecklistDefinitions[ChecklistType.visualErgonomics]!;
      // Marca 6 perguntas de risco com a opção que soma (índice 0 = "Sim" para
      // glare, mas usa _firstN com helper específico).
      final answers = _answersFor(def, {
        'erg_glare': 0, // Sim -> 1
        'erg_distance': 1, // Não -> 1
        'erg_height': 1, // Não -> 1
        'erg_font': 1, // Não -> 1
        'erg_squint': 0, // Sim -> 1
        'erg_lean': 0, // Sim -> 1
      });
      final result = evaluate(def: def, answers: answers, id: id, now: now);
      expect(result.totalScore, 6);
      expect(result.riskLevel, ChecklistRiskLevel.increased);
      expect(result.type, ChecklistType.visualErgonomics);
      expect(result.createdAt, now);
      expect(result.id, id);
    });

    test('item crítico em sinais de alerta -> urgentAttention', () {
      final def = kChecklistDefinitions[ChecklistType.warningSigns]!;
      // warn_pain é critical; "Sim" (índice 0) soma 1.
      final answers = _answersFor(def, {'warn_pain': 0});
      final result = evaluate(def: def, answers: answers, id: id, now: now);
      expect(result.riskLevel, ChecklistRiskLevel.urgentAttention);
      expect(result.classification, kWarningSignsUrgentClassification);
      expect(result.feedback, kWarningSignsUrgentFeedback);
    });

    test('sinais de alerta sem crítico classifica por contagem', () {
      final def = kChecklistDefinitions[ChecklistType.warningSigns]!;
      // warn_secretion não é crítico; "Sim" soma 1.
      final answers = _answersFor(def, {'warn_secretion': 0});
      final result = evaluate(def: def, answers: answers, id: id, now: now);
      expect(result.totalScore, 1);
      expect(result.riskLevel, ChecklistRiskLevel.attention);
    });

    test('checklist incompleto não quebra (respostas faltando)', () {
      final def = kChecklistDefinitions[ChecklistType.visualSymptoms]!;
      // Responde apenas 2 das 15 perguntas.
      final answers = _firstN(def, 2, 4); // 2 * 4 = 8
      final result = evaluate(def: def, answers: answers, id: id, now: now);
      expect(result.totalScore, 8);
      expect(result.riskLevel, ChecklistRiskLevel.low);
    });
  });

  group('buildTriage (4 desfechos)', () {
    test('urgente: crítico em sinais de alerta', () {
      final warning = ChecklistResult(
        id: 'w',
        type: ChecklistType.warningSigns,
        createdAt: now,
        answers: const [],
        totalScore: 1,
        riskLevel: ChecklistRiskLevel.urgentAttention,
        classification: '',
        feedback: '',
      );
      final triage =
          buildTriage(id: id, now: now, warningSigns: warning);
      expect(triage.riskLevel, ChecklistRiskLevel.urgentAttention);
      expect(triage.feedback, contains('não substitui consulta médica'));
    });

    test('urgente: OSDI muito alto', () {
      final triage = buildTriage(id: id, now: now, latestOsdiScore: 40);
      expect(triage.riskLevel, ChecklistRiskLevel.urgentAttention);
    });

    test('considerar avaliação: sintomas frequentes', () {
      final symptoms = ChecklistResult(
        id: 's',
        type: ChecklistType.visualSymptoms,
        createdAt: now,
        answers: const [],
        totalScore: 30,
        riskLevel: ChecklistRiskLevel.increased,
        classification: '',
        feedback: '',
      );
      final triage = buildTriage(id: id, now: now, symptoms: symptoms);
      expect(triage.riskLevel, ChecklistRiskLevel.recommendedEvaluation);
    });

    test('atenção: sinais de sobrecarga (tempo de tela alto)', () {
      final triage = buildTriage(
        id: id,
        now: now,
        avgScreenSecondsPerDay: 7 * 3600,
      );
      expect(triage.riskLevel, ChecklistRiskLevel.attention);
    });

    test('low: nenhum sinal relevante', () {
      final triage = buildTriage(
        id: id,
        now: now,
        latestOsdiScore: 5,
        avgScreenSecondsPerDay: 3 * 3600,
        breakAdherence: 0.9,
      );
      expect(triage.riskLevel, ChecklistRiskLevel.low);
    });
  });

  group('buildVisualRiskSummary', () {
    test('sem dados -> low', () {
      final summary = buildVisualRiskSummary(now: now);
      expect(summary.overallLevel, ChecklistRiskLevel.low);
      expect(summary.summaryText, isNotEmpty);
      expect(summary.recommendation, isNotEmpty);
    });

    test('pega o pior indicador como nível geral', () {
      final symptoms = ChecklistResult(
        id: 's',
        type: ChecklistType.visualSymptoms,
        createdAt: now,
        answers: const [],
        totalScore: 30,
        riskLevel: ChecklistRiskLevel.increased,
        classification: '',
        feedback: '',
      );
      final summary = buildVisualRiskSummary(
        now: now,
        symptoms: symptoms,
        latestOsdiScore: 5,
      );
      expect(summary.overallLevel, ChecklistRiskLevel.increased);
      expect(summary.symptomsRisk, ChecklistRiskLevel.increased);
    });

    test('tempo de tela alto eleva o resumo', () {
      final summary = buildVisualRiskSummary(
        now: now,
        avgScreenSecondsPerDay: 9 * 3600,
      );
      expect(summary.screenTimeRisk, ChecklistRiskLevel.increased);
      expect(summary.overallLevel, ChecklistRiskLevel.increased);
    });
  });

  group('compareChecklistResults / trend', () {
    final base = ChecklistResult(
      id: 'p',
      type: ChecklistType.visualSymptoms,
      createdAt: now,
      answers: const [],
      totalScore: 10,
      riskLevel: ChecklistRiskLevel.low,
      classification: '',
      feedback: '',
    );

    test('null quando não há anterior', () {
      expect(compareChecklistResults(null, base), isNull);
      expect(compareChecklistTrend(null, base), isNull);
    });

    test('variação de score', () {
      final current = base.copyWith(totalScore: 18);
      expect(compareChecklistResults(base, current), 8);
      expect(compareChecklistTrend(base, current), ChecklistTrend.worsening);
    });

    test('melhora quando score cai', () {
      final current = base.copyWith(totalScore: 4);
      expect(compareChecklistTrend(base, current), ChecklistTrend.improving);
    });

    test('estável dentro da margem', () {
      final current = base.copyWith(totalScore: 10);
      expect(compareChecklistTrend(base, current), ChecklistTrend.stable);
    });
  });
}
