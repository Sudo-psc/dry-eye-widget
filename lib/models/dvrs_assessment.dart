import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Modelo histórico do **DVRS**, exibido como registro educativo visual (v1.1).
///
/// Instrumento EDUCATIVO de triagem e acompanhamento. Nunca diagnóstico: os
/// tipos abaixo carregam `isDiagnostic = false` e toda a linguagem produzida é
/// de triagem. Construtores são puros (não chamam `DateTime.now()`/`Random`);
/// `id` e `createdAt` são fornecidos por quem cria o resultado.
///
/// v1.1: versionamento explícito do instrumento, rascunho local e comparação
/// de domínios no histórico (sem mudança na fórmula de score).

/// Os cinco domínios do DVRS.
enum DvrsDomain { symptoms, functional, exposure, environment, warning }

/// Id string estável de [DvrsDomain] para serialização e parse reverso.
extension DvrsDomainId on DvrsDomain {
  String get id {
    switch (this) {
      case DvrsDomain.symptoms:
        return 'symptoms';
      case DvrsDomain.functional:
        return 'functional';
      case DvrsDomain.exposure:
        return 'exposure';
      case DvrsDomain.environment:
        return 'environment';
      case DvrsDomain.warning:
        return 'warning';
    }
  }

  static DvrsDomain? fromId(String? id) {
    for (final d in DvrsDomain.values) {
      if (d.id == id) return d;
    }
    return null;
  }
}

/// Faixas internas de organização do registro; não são risco ou limiar clínico.
enum DvrsClassification {
  low,
  mildAttention,
  moderateRisk,
  highRisk,
  veryHighRisk,
}

/// Id estável + rótulo curto de [DvrsClassification].
extension DvrsClassificationId on DvrsClassification {
  String get id {
    switch (this) {
      case DvrsClassification.low:
        return 'low';
      case DvrsClassification.mildAttention:
        return 'mild_attention';
      case DvrsClassification.moderateRisk:
        return 'moderate_risk';
      case DvrsClassification.highRisk:
        return 'high_risk';
      case DvrsClassification.veryHighRisk:
        return 'very_high_risk';
    }
  }

  /// Rótulo curto exibido ao usuário (fonte única de verdade).
  String get label {
    switch (this) {
      case DvrsClassification.low:
        return 'Carga relatada baixa';
      case DvrsClassification.mildAttention:
        return 'Alguns sinais relatados';
      case DvrsClassification.moderateRisk:
        return 'Carga relatada moderada';
      case DvrsClassification.highRisk:
        return 'Carga relatada elevada';
      case DvrsClassification.veryHighRisk:
        return 'Carga relatada muito elevada';
    }
  }

  static DvrsClassification? fromId(String? id) {
    for (final c in DvrsClassification.values) {
      if (c.id == id) return c;
    }
    return null;
  }
}

/// Nível do alerta de segurança clínica derivado da pergunta 16.
enum DvrsSafetyAlertLevel {
  none,
  attention,
  medicalEvaluation,
  priorityEvaluation,
}

/// Id estável de [DvrsSafetyAlertLevel].
extension DvrsSafetyAlertLevelId on DvrsSafetyAlertLevel {
  String get id {
    switch (this) {
      case DvrsSafetyAlertLevel.none:
        return 'none';
      case DvrsSafetyAlertLevel.attention:
        return 'attention';
      case DvrsSafetyAlertLevel.medicalEvaluation:
        return 'medical_evaluation';
      case DvrsSafetyAlertLevel.priorityEvaluation:
        return 'priority_evaluation';
    }
  }

  static DvrsSafetyAlertLevel? fromId(String? id) {
    for (final l in DvrsSafetyAlertLevel.values) {
      if (l.id == id) return l;
    }
    return null;
  }
}

/// Resultado semântico de alerta. O texto é derivado na superfície ativa.
@immutable
class DvrsSafetyAlert {
  const DvrsSafetyAlert({required this.level});

  final DvrsSafetyAlertLevel level;
}

/// Uma resposta dada pelo usuário a uma pergunta do DVRS.
@immutable
class DvrsAnswer {
  const DvrsAnswer({
    required this.questionId,
    required this.domain,
    required this.value,
    required this.label,
  });

  /// Id estável da pergunta (ex.: `q1`).
  final String questionId;

  /// Domínio a que a pergunta pertence.
  final DvrsDomain domain;

  /// Pontuação da opção escolhida (0–4).
  final int value;

  /// Rótulo da opção escolhida (para histórico/relatório).
  final String label;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'questionId': questionId,
    'domain': domain.id,
    'value': value,
    'label': label,
  };

  factory DvrsAnswer.fromMap(Map<String, dynamic> map) => DvrsAnswer(
    questionId: map['questionId'] as String? ?? '',
    domain:
        DvrsDomainId.fromId(map['domain'] as String?) ?? DvrsDomain.symptoms,
    value: (map['value'] as num?)?.toInt() ?? 0,
    label: map['label'] as String? ?? '',
  );
}

/// Scores normalizados (0–100) por domínio.
@immutable
class DvrsDomainScores {
  const DvrsDomainScores({
    required this.symptoms,
    required this.functional,
    required this.exposure,
    required this.environment,
    required this.warning,
  });

  final double symptoms;
  final double functional;
  final double exposure;
  final double environment;
  final double warning;

  /// Score normalizado de um domínio específico.
  double valueFor(DvrsDomain domain) {
    switch (domain) {
      case DvrsDomain.symptoms:
        return symptoms;
      case DvrsDomain.functional:
        return functional;
      case DvrsDomain.exposure:
        return exposure;
      case DvrsDomain.environment:
        return environment;
      case DvrsDomain.warning:
        return warning;
    }
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'symptoms': symptoms,
    'functional': functional,
    'exposure': exposure,
    'environment': environment,
    'warning': warning,
  };

  factory DvrsDomainScores.fromMap(Map<String, dynamic> map) {
    double read(String k) => (map[k] as num?)?.toDouble() ?? 0;
    return DvrsDomainScores(
      symptoms: read('symptoms'),
      functional: read('functional'),
      exposure: read('exposure'),
      environment: read('environment'),
      warning: read('warning'),
    );
  }
}

/// Resultado consolidado e serializável de um DVRS respondido.
@immutable
class DvrsResult {
  const DvrsResult({
    required this.id,
    required this.createdAt,
    required this.answers,
    required this.domainScores,
    required this.totalScore,
    required this.classification,
    required this.classificationLabel,
    required this.safetyAlertLevel,
    this.userId,
    this.version = dvrsVersion,
    this.isDiagnostic = false,
    this.includeInPdf = false,
  });

  /// Versão do instrumento (semântica de conteúdo das 16 perguntas + pesos).
  /// Resultados antigos (DVRS_v1.0) continuam legíveis; novos gravam 1.1.
  static const String dvrsVersion = 'DVRS_v1.1';

  final String id;
  final String? userId;
  final DateTime createdAt;
  final String version;
  final List<DvrsAnswer> answers;
  final DvrsDomainScores domainScores;

  /// Score final 0–100 (inteiro).
  final int totalScore;
  final DvrsClassification classification;
  final String classificationLabel;
  final DvrsSafetyAlertLevel safetyAlertLevel;

  /// Sempre `false`: o DVRS é educativo, nunca diagnóstico.
  final bool isDiagnostic;

  /// Se o usuário optou por incluir este resultado no relatório PDF.
  final bool includeInPdf;

  DvrsResult copyWith({bool? includeInPdf}) => DvrsResult(
    id: id,
    userId: userId,
    createdAt: createdAt,
    version: version,
    answers: answers,
    domainScores: domainScores,
    totalScore: totalScore,
    classification: classification,
    classificationLabel: classificationLabel,
    safetyAlertLevel: safetyAlertLevel,
    isDiagnostic: isDiagnostic,
    includeInPdf: includeInPdf ?? this.includeInPdf,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    if (userId != null) 'userId': userId,
    'createdAt': createdAt.toIso8601String(),
    'version': version,
    'answers': answers.map((a) => a.toMap()).toList(),
    'domainScores': domainScores.toMap(),
    'totalScore': totalScore,
    'classification': classification.id,
    'classificationLabel': classificationLabel,
    'safetyAlertLevel': safetyAlertLevel.id,
    'isDiagnostic': false,
    'includeInPdf': includeInPdf,
  };

  factory DvrsResult.fromMap(Map<String, dynamic> map) {
    final rawAnswers = map['answers'];
    final answers = <DvrsAnswer>[];
    if (rawAnswers is List) {
      for (final item in rawAnswers) {
        if (item is Map) {
          answers.add(DvrsAnswer.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }
    final classification =
        DvrsClassificationId.fromId(map['classification'] as String?) ??
        DvrsClassification.low;
    return DvrsResult(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String?,
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime(2000),
      version: map['version'] as String? ?? dvrsVersion,
      answers: List<DvrsAnswer>.unmodifiable(answers),
      domainScores: map['domainScores'] is Map
          ? DvrsDomainScores.fromMap(
              Map<String, dynamic>.from(map['domainScores'] as Map),
            )
          : const DvrsDomainScores(
              symptoms: 0,
              functional: 0,
              exposure: 0,
              environment: 0,
              warning: 0,
            ),
      totalScore: (map['totalScore'] as num?)?.toInt() ?? 0,
      classification: classification,
      classificationLabel:
          map['classificationLabel'] as String? ?? classification.label,
      safetyAlertLevel:
          DvrsSafetyAlertLevelId.fromId(map['safetyAlertLevel'] as String?) ??
          DvrsSafetyAlertLevel.none,
      includeInPdf: map['includeInPdf'] as bool? ?? false,
    );
  }

  String toJson() => jsonEncode(toMap());

  static DvrsResult? fromJson(String? source) {
    if (source == null || source.isEmpty) return null;
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map) return null;
      return DvrsResult.fromMap(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }
}
