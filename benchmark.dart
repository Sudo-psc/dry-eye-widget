void main() {
  final regExp = RegExp(r'(\d+)\.(\d+)\.(\d+)');

  String normalizeOld(String tag) {
    final m = RegExp(r'(\d+)\.(\d+)\.(\d+)').firstMatch(tag);
    return m == null ? '' : '${m[1]}.${m[2]}.${m[3]}';
  }

  String normalizeNew(String tag) {
    final m = regExp.firstMatch(tag);
    return m == null ? '' : '${m[1]}.${m[2]}.${m[3]}';
  }

  final tags = ['v1.2.3', '1.0.0-beta', '2.3.4'];

  // Warmup
  for (var i = 0; i < 10000; i++) {
    for (final tag in tags) {
      normalizeOld(tag);
      normalizeNew(tag);
    }
  }

  final watchOld = Stopwatch()..start();
  for (var i = 0; i < 1000000; i++) {
    for (final tag in tags) {
      normalizeOld(tag);
    }
  }
  watchOld.stop();

  final watchNew = Stopwatch()..start();
  for (var i = 0; i < 1000000; i++) {
    for (final tag in tags) {
      normalizeNew(tag);
    }
  }
  watchNew.stop();

  print('Old: ${watchOld.elapsedMilliseconds} ms');
  print('New: ${watchNew.elapsedMilliseconds} ms');
}
