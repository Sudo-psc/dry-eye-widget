import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Tipos de checklist de saúde visual digital.
///
/// Os cinco primeiros são questionários (módulos 1–5). [ophthalmologyTriage]
/// (módulo 6) e [visualRiskSummary] (módulo 7) não são questionários: são
/// resultados computados pelo engine a partir dos demais dados.
enum ChecklistType {
  visualErgonomics,
  screenEnvironment,
  visualSymptoms,
  warningSigns,
  breakHabits,
  ophthalmologyTriage,
  visualRiskSummary,
}

/// Extensão com id string estável para serialização e parse reverso.
extension ChecklistTypeId on ChecklistType {
  /// Id estável usado em JSON (não muda mesmo se a ordem do enum mudar).
  String get id {
    switch (this) {
      case ChecklistType.visualErgonomics:
        return 'visual_ergonomics';
      case ChecklistType.screenEnvironment:
        return 'screen_environment';
      case ChecklistType.visualSymptoms:
        return 'visual_symptoms';
      case ChecklistType.warningSigns:
        return 'warning_signs';
      case ChecklistType.breakHabits:
        return 'break_habits';
      case ChecklistType.ophthalmologyTriage:
        return 'ophthalmology_triage';
      case ChecklistType.visualRiskSummary:
        return 'visual_risk_summary';
    }
  }

  /// Faz o parse reverso a partir do [id]; retorna `null` se desconhecido.
  static ChecklistType? fromId(String? id) {
    for (final type in ChecklistType.values) {
      if (type.id == id) return type;
    }
    return null;
  }
}

/// Nível de risco visual reportado por um checklist.
///
/// Linguagem de TRIAGEM, nunca diagnóstica: indica o grau de atenção sugerido,
/// não a presença de doença.
enum ChecklistRiskLevel {
  low,
  attention,
  increased,
  recommendedEvaluation,
  urgentAttention,
}

/// Extensão com id string estável para [ChecklistRiskLevel].
extension ChecklistRiskLevelId on ChecklistRiskLevel {
  String get id {
    switch (this) {
      case ChecklistRiskLevel.low:
        return 'low';
      case ChecklistRiskLevel.attention:
        return 'attention';
      case ChecklistRiskLevel.increased:
        return 'increased';
      case ChecklistRiskLevel.recommendedEvaluation:
        return 'recommended_evaluation';
      case ChecklistRiskLevel.urgentAttention:
        return 'urgent_attention';
    }
  }

  static ChecklistRiskLevel? fromId(String? id) {
    for (final level in ChecklistRiskLevel.values) {
      if (level.id == id) return level;
    }
    return null;
  }
}

/// Uma opção de resposta de uma pergunta, com a pontuação associada.
@immutable
class ChecklistOption {
  const ChecklistOption({required this.label, required this.score});

  /// Texto exibido (ex.: "Sim", "Às vezes").
  final String label;

  /// Pontuação somada ao total quando esta opção é escolhida.
  final int score;
}

/// Uma pergunta do questionário, com suas opções de resposta.
@immutable
class ChecklistQuestion {
  const ChecklistQuestion({
    required this.id,
    required this.text,
    required this.options,
    this.critical = false,
    this.detail,
  });

  /// Id estável da pergunta (usado para casar respostas com perguntas).
  final String id;

  /// Enunciado da pergunta.
  final String text;

  /// Opções de resposta, na ordem de exibição.
  final List<ChecklistOption> options;

  /// Marca itens de alerta crítico (apenas no módulo de sinais de alerta).
  /// Quando `true` e a resposta soma pontos, dispara atenção prioritária.
  final bool critical;

  /// Especificação/orientação educativa com valores de referência (opcional).
  /// Exibida abaixo do enunciado para ajudar o usuário a responder e a ajustar
  /// o posto de trabalho. É informativa — não constitui prescrição.
  final String? detail;
}

/// Uma resposta dada pelo usuário a uma pergunta.
@immutable
class ChecklistAnswer {
  const ChecklistAnswer({
    required this.questionId,
    required this.score,
    required this.optionIndex,
  });

  /// Id da pergunta respondida.
  final String questionId;

  /// Pontuação da opção escolhida.
  final int score;

  /// Índice da opção escolhida na lista de opções da pergunta.
  final int optionIndex;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'questionId': questionId,
    'score': score,
    'optionIndex': optionIndex,
  };

  factory ChecklistAnswer.fromMap(Map<String, dynamic> map) => ChecklistAnswer(
    questionId: map['questionId'] as String? ?? '',
    score: (map['score'] as num?)?.toInt() ?? 0,
    optionIndex: (map['optionIndex'] as num?)?.toInt() ?? 0,
  );
}

/// Resultado consolidado de um checklist respondido (ou computado).
///
/// É imutável e serializável. O [id] é gerado por quem chama (passe via
/// parâmetro; em testes use `createdAt.millisecondsSinceEpoch`). Construtores
/// puros nunca chamam `DateTime.now()`/`Random` internamente.
@immutable
class ChecklistResult {
  const ChecklistResult({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.answers,
    required this.totalScore,
    required this.riskLevel,
    required this.classification,
    required this.feedback,
    this.includeInPdf = false,
    this.version = '1',
  });

  /// Identificador único do resultado (gerado externamente).
  final String id;

  /// Tipo de checklist a que este resultado pertence.
  final ChecklistType type;

  /// Momento de criação do resultado.
  final DateTime createdAt;

  /// Respostas que originaram o resultado (vazio para módulos computados 6 e 7).
  final List<ChecklistAnswer> answers;

  /// Pontuação total somada das respostas.
  final int totalScore;

  /// Nível de risco visual de triagem.
  final ChecklistRiskLevel riskLevel;

  /// Rótulo curto da classificação (ex.: "Sinais de atenção").
  final String classification;

  /// Texto educativo de feedback (sempre não-diagnóstico).
  final String feedback;

  /// Se o usuário optou por incluir este resultado no relatório PDF.
  final bool includeInPdf;

  /// Versão do conteúdo/definição que gerou o resultado.
  final String version;

  ChecklistResult copyWith({
    String? id,
    ChecklistType? type,
    DateTime? createdAt,
    List<ChecklistAnswer>? answers,
    int? totalScore,
    ChecklistRiskLevel? riskLevel,
    String? classification,
    String? feedback,
    bool? includeInPdf,
    String? version,
  }) => ChecklistResult(
    id: id ?? this.id,
    type: type ?? this.type,
    createdAt: createdAt ?? this.createdAt,
    answers: answers ?? this.answers,
    totalScore: totalScore ?? this.totalScore,
    riskLevel: riskLevel ?? this.riskLevel,
    classification: classification ?? this.classification,
    feedback: feedback ?? this.feedback,
    includeInPdf: includeInPdf ?? this.includeInPdf,
    version: version ?? this.version,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'type': type.id,
    'createdAt': createdAt.toIso8601String(),
    'answers': answers.map((a) => a.toMap()).toList(),
    'totalScore': totalScore,
    'riskLevel': riskLevel.id,
    'classification': classification,
    'feedback': feedback,
    'includeInPdf': includeInPdf,
    'version': version,
  };

  factory ChecklistResult.fromMap(Map<String, dynamic> map) {
    final rawAnswers = map['answers'];
    final answers = <ChecklistAnswer>[];
    if (rawAnswers is List) {
      for (final item in rawAnswers) {
        if (item is Map) {
          answers.add(ChecklistAnswer.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }
    return ChecklistResult(
      id: map['id'] as String? ?? '',
      type: ChecklistTypeId.fromId(map['type'] as String?) ??
          ChecklistType.visualSymptoms,
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime(2000),
      answers: List<ChecklistAnswer>.unmodifiable(answers),
      totalScore: (map['totalScore'] as num?)?.toInt() ?? 0,
      riskLevel: ChecklistRiskLevelId.fromId(map['riskLevel'] as String?) ??
          ChecklistRiskLevel.low,
      classification: map['classification'] as String? ?? '',
      feedback: map['feedback'] as String? ?? '',
      includeInPdf: map['includeInPdf'] as bool? ?? false,
      version: map['version'] as String? ?? '1',
    );
  }

  String toJson() => jsonEncode(toMap());

  static ChecklistResult? fromJson(String? source) {
    if (source == null || source.isEmpty) return null;
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map) return null;
      return ChecklistResult.fromMap(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }
}

/// Tendência de evolução entre dois resultados do mesmo tipo.
enum ChecklistTrend { improving, stable, worsening }

/// Indicadores agregados do módulo 7 (resumo de risco visual).
///
/// Reúne, de forma educativa e não-alarmista, os sinais disponíveis em um único
/// panorama. Todos os campos são opcionais (`null` = sem dados).
@immutable
class VisualRiskSummary {
  const VisualRiskSummary({
    required this.createdAt,
    required this.overallLevel,
    required this.summaryText,
    required this.recommendation,
    this.ergonomicRisk,
    this.environmentRisk,
    this.symptomsRisk,
    this.warningSignsRisk,
    this.breakAdherenceRisk,
    this.screenTimeRisk,
    this.latestOsdiScore,
    this.trend,
  });

  final DateTime createdAt;

  /// Risco ergonômico (módulo 1).
  final ChecklistRiskLevel? ergonomicRisk;

  /// Risco ambiental (módulo 2).
  final ChecklistRiskLevel? environmentRisk;

  /// Risco de sintomas (módulo 3).
  final ChecklistRiskLevel? symptomsRisk;

  /// Risco de sinais de alerta (módulo 4).
  final ChecklistRiskLevel? warningSignsRisk;

  /// Risco por baixa adesão a pausas (módulo 5).
  final ChecklistRiskLevel? breakAdherenceRisk;

  /// Risco por tempo de tela elevado.
  final ChecklistRiskLevel? screenTimeRisk;

  /// Pontuação OSDI mais recente, se houver.
  final double? latestOsdiScore;

  /// Tendência geral (quando há histórico para comparar).
  final ChecklistTrend? trend;

  /// Nível geral consolidado.
  final ChecklistRiskLevel overallLevel;

  /// Frase-resumo educativa (não-alarmista).
  final String summaryText;

  /// Recomendação curta de próxima ação.
  final String recommendation;
}
