import 'dart:convert';

enum OsdiSeverity { normal, mild, moderate, severe }

class OsdiAssessment {
  const OsdiAssessment._({
    required this.completedAt,
    required this.answers,
    required this.rawScore,
    required this.answeredCount,
    required this.score,
  });

  static const int questionCount = 12;
  static const int maxHistoryLength = 50;

  final DateTime completedAt;
  final List<int?> answers;
  final int rawScore;
  final int answeredCount;
  final double score;

  OsdiSeverity get severity => severityForScore(score);

  factory OsdiAssessment.fromAnswers(
    List<int?> answers, {
    DateTime? completedAt,
  }) {
    if (answers.length != questionCount) {
      throw ArgumentError.value(
        answers.length,
        'answers.length',
        'OSDI requires exactly $questionCount answers.',
      );
    }

    var rawScore = 0;
    var answeredCount = 0;
    final normalized = <int?>[];
    for (final answer in answers) {
      if (answer == null) {
        normalized.add(null);
        continue;
      }
      if (answer < 0 || answer > 4) {
        throw ArgumentError.value(
          answer,
          'answers',
          'OSDI answers must be between 0 and 4, or null for N/A.',
        );
      }
      rawScore += answer;
      answeredCount++;
      normalized.add(answer);
    }

    if (answeredCount == 0) {
      throw ArgumentError('At least one OSDI question must be answered.');
    }

    final score = rawScore * 25 / answeredCount;
    return OsdiAssessment._(
      completedAt: completedAt ?? DateTime.now(),
      answers: List<int?>.unmodifiable(normalized),
      rawScore: rawScore,
      answeredCount: answeredCount,
      score: score,
    );
  }

  static OsdiSeverity severityForScore(double score) {
    if (score <= 12) return OsdiSeverity.normal;
    if (score <= 22) return OsdiSeverity.mild;
    if (score <= 32) return OsdiSeverity.moderate;
    return OsdiSeverity.severe;
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'completedAt': completedAt.toIso8601String(),
    'answers': answers,
  };

  factory OsdiAssessment.fromMap(Map<String, dynamic> map) {
    final rawAnswers = map['answers'];
    if (rawAnswers is! List) {
      throw ArgumentError.value(rawAnswers, 'answers', 'Expected a list.');
    }

    return OsdiAssessment.fromAnswers(
      rawAnswers.map<int?>((value) {
        if (value == null) return null;
        if (value is int) return value;
        if (value is num) return value.toInt();
        return null;
      }).toList(),
      completedAt: DateTime.parse(map['completedAt'] as String),
    );
  }

  static OsdiAssessment? tryFromMap(Object? value) {
    try {
      if (value is! Map<String, dynamic>) return null;
      return OsdiAssessment.fromMap(value);
    } catch (_) {
      return null;
    }
  }

  static String encodeHistory(List<OsdiAssessment> history) =>
      jsonEncode(history.map((item) => item.toMap()).toList());

  static List<OsdiAssessment> decodeHistory(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final assessments =
          decoded
              .map(OsdiAssessment.tryFromMap)
              .whereType<OsdiAssessment>()
              .toList()
            ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
      return List<OsdiAssessment>.unmodifiable(assessments);
    } catch (_) {
      return const [];
    }
  }
}
