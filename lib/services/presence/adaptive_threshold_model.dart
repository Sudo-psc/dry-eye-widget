import 'dart:math' as math;

/// Estima, por faixa horária, o limiar de inatividade que separa "presença
/// parada" de "ausência real", aprendido continuamente.
///
/// Usa um histograma compacto de contagens (bins de [binWidth] s até
/// [maxThreshold] s, mais um bin de overflow) por bucket horário. A estimativa
/// de percentil é O(1) por evento, determinística e interpretável; o estado
/// total são contagens inteiras (agregado, sem eventos brutos nem timestamps).
class AdaptiveThresholdModel {
  AdaptiveThresholdModel({
    this.targetPercentile = 0.85,
    this.minThreshold = 60,
    this.maxThreshold = 600,
    this.coldStartThreshold = 120,
    this.minObservations = 5,
    this.binWidth = 30,
    this.maxLearnableGap = 900,
  })  : _bins = List.generate(_bucketCount,
            (_) => List<int>.filled(_binCount(maxThreshold, binWidth), 0)),
        _counts = List<int>.filled(_bucketCount, 0);

  final double targetPercentile;
  final int minThreshold;
  final int maxThreshold;
  final int coldStartThreshold;
  final int minObservations;
  final int binWidth;

  /// Gaps acima disso são tratados como ausência real e não alimentam o
  /// aprendizado (evita inflar o limiar quando o usuário realmente saiu).
  final int maxLearnableGap;

  static const int _bucketCount = 4; // 00-06, 06-12, 12-18, 18-24
  final List<List<int>> _bins;
  final List<int> _counts;

  static int _binCount(int maxThreshold, int binWidth) =>
      (maxThreshold / binWidth).ceil() + 1; // +1 = overflow

  int _bucketIndex(int hour) => (hour ~/ 6).clamp(0, _bucketCount - 1);

  /// Apaga todo o aprendizado, voltando ao estado de cold start.
  void reset() {
    for (var b = 0; b < _bucketCount; b++) {
      _counts[b] = 0;
      for (var i = 0; i < _bins[b].length; i++) {
        _bins[b][i] = 0;
      }
    }
  }

  /// Registra um gap (em segundos) durante o qual o usuário estava presente.
  void observePresentGap(int hour, double gapSeconds) {
    if (gapSeconds <= 0 || gapSeconds > maxLearnableGap) return;
    final b = _bucketIndex(hour);
    final idx = (gapSeconds ~/ binWidth).clamp(0, _bins[b].length - 1);
    _bins[b][idx]++;
    _counts[b]++;
  }

  /// Limiar atual para a hora informada, em segundos.
  int thresholdForHour(int hour) {
    final b = _bucketIndex(hour);
    if (_counts[b] < minObservations) return coldStartThreshold;
    final target = targetPercentile * _counts[b];
    var acc = 0;
    for (var i = 0; i < _bins[b].length; i++) {
      acc += _bins[b][i];
      if (acc >= target) {
        final upper = (i + 1) * binWidth; // limite superior do bin
        return upper.clamp(minThreshold, maxThreshold);
      }
    }
    return maxThreshold;
  }

  Map<String, dynamic> toMap() => {
        'v': 1,
        'binWidth': binWidth,
        'targetPercentile': targetPercentile,
        'minThreshold': minThreshold,
        'maxThreshold': maxThreshold,
        'coldStartThreshold': coldStartThreshold,
        'minObservations': minObservations,
        'maxLearnableGap': maxLearnableGap,
        'counts': _counts,
        'bins': _bins,
      };

  /// Carrega contagens agregadas de um mapa para dentro deste modelo,
  /// preservando a configuração atual. Estado corrompido -> reset.
  void loadFrom(Map<String, dynamic> map) {
    reset();
    try {
      final counts = (map['counts'] as List).cast<num>();
      final bins = (map['bins'] as List)
          .map((row) => (row as List).map((e) => (e as num).toInt()).toList())
          .toList();
      for (var b = 0; b < math.min(counts.length, _bucketCount); b++) {
        _counts[b] = counts[b].toInt();
        for (var i = 0; i < math.min(bins[b].length, _bins[b].length); i++) {
          _bins[b][i] = bins[b][i];
        }
      }
    } catch (_) {
      reset();
    }
  }

  factory AdaptiveThresholdModel.fromMap(Map<String, dynamic> map) {
    return AdaptiveThresholdModel(
      binWidth: (map['binWidth'] as num?)?.toInt() ?? 30,
      targetPercentile: (map['targetPercentile'] as num?)?.toDouble() ?? 0.85,
      minThreshold: (map['minThreshold'] as num?)?.toInt() ?? 60,
      maxThreshold: (map['maxThreshold'] as num?)?.toInt() ?? 600,
      coldStartThreshold: (map['coldStartThreshold'] as num?)?.toInt() ?? 120,
      minObservations: (map['minObservations'] as num?)?.toInt() ?? 5,
      maxLearnableGap: (map['maxLearnableGap'] as num?)?.toInt() ?? 900,
    )..loadFrom(map);
  }
}
