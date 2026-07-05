import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Estatísticas locais de atividade por dia: contagens agregadas de cliques e
/// teclas (NUNCA quais teclas — apenas quantidades) e tempo em foco por app.
///
/// Privacidade: dados 100% locais, opt-in, sem envio a servidores. O objetivo
/// é educativo — correlacionar carga de interação com fadiga visual.
@immutable
class ActivityDayStat {
  const ActivityDayStat({
    this.clicks = 0,
    this.keys = 0,
    this.appSeconds = const <String, int>{},
  });

  /// Cliques do mouse no dia (agregado).
  final int clicks;

  /// Teclas pressionadas no dia (apenas contagem agregada).
  final int keys;

  /// Segundos em primeiro plano por app ({'Nome do app': segundos}).
  final Map<String, int> appSeconds;

  ActivityDayStat merge({int clicks = 0, int keys = 0}) => ActivityDayStat(
        clicks: this.clicks + clicks,
        keys: this.keys + keys,
        appSeconds: appSeconds,
      );

  ActivityDayStat withAppSeconds(String app, int seconds) {
    final next = Map<String, int>.from(appSeconds);
    next[app] = (next[app] ?? 0) + seconds;
    return ActivityDayStat(clicks: clicks, keys: keys, appSeconds: next);
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'c': clicks,
        'k': keys,
        'a': appSeconds,
      };

  factory ActivityDayStat.fromMap(Map<String, dynamic> map) {
    final rawApps = map['a'];
    final apps = <String, int>{};
    if (rawApps is Map) {
      rawApps.forEach((key, value) {
        if (key is String && value is num) apps[key] = value.toInt();
      });
    }
    return ActivityDayStat(
      clicks: (map['c'] as num?)?.toInt() ?? 0,
      keys: (map['k'] as num?)?.toInt() ?? 0,
      appSeconds: Map<String, int>.unmodifiable(apps),
    );
  }
}

/// Um app com o tempo agregado em foco (para rankings).
@immutable
class AppUsage {
  const AppUsage({required this.appName, required this.seconds});
  final String appName;
  final int seconds;
}

/// Mapa dia ('AAAA-MM-DD') → [ActivityDayStat], imutável e serializável.
@immutable
class ActivityStatsData {
  ActivityStatsData(Map<String, ActivityDayStat> byDay)
      : byDay = Map<String, ActivityDayStat>.unmodifiable(byDay);

  final Map<String, ActivityDayStat> byDay;

  /// Retenção máxima em dias (dados de atividade são mais sensíveis que os
  /// de tempo de tela — retenção menor).
  static const int maxRetainedDays = 180;

  factory ActivityStatsData.empty() =>
      ActivityStatsData(const <String, ActivityDayStat>{});

  static String dayKey(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  ActivityDayStat _day(DateTime date) =>
      byDay[dayKey(date)] ?? const ActivityDayStat();

  int clicksForDay(DateTime date) => _day(date).clicks;
  int keysForDay(DateTime date) => _day(date).keys;
  Map<String, int> appSecondsForDay(DateTime date) => _day(date).appSeconds;

  /// Nova instância com [clicks]/[keys] somados ao dia de [moment].
  ActivityStatsData incremented(
    DateTime moment, {
    int clicks = 0,
    int keys = 0,
  }) {
    final key = dayKey(moment);
    final next = Map<String, ActivityDayStat>.from(byDay);
    next[key] = (next[key] ?? const ActivityDayStat())
        .merge(clicks: clicks, keys: keys);
    return ActivityStatsData(next);
  }

  /// Nova instância com [seconds] somados ao app [appName] no dia de [moment].
  ActivityStatsData addAppSeconds(
    DateTime moment,
    String appName,
    int seconds,
  ) {
    if (appName.trim().isEmpty || seconds <= 0) return this;
    final key = dayKey(moment);
    final next = Map<String, ActivityDayStat>.from(byDay);
    next[key] =
        (next[key] ?? const ActivityDayStat()).withAppSeconds(appName, seconds);
    return ActivityStatsData(next);
  }

  bool _inRange(String key, DateTime start, DateTime end) {
    final s = dayKey(start);
    final e = dayKey(end);
    return key.compareTo(s) >= 0 && key.compareTo(e) <= 0;
  }

  int clicksForRange(DateTime start, DateTime end) => byDay.entries
      .where((e) => _inRange(e.key, start, end))
      .fold(0, (sum, e) => sum + e.value.clicks);

  int keysForRange(DateTime start, DateTime end) => byDay.entries
      .where((e) => _inRange(e.key, start, end))
      .fold(0, (sum, e) => sum + e.value.keys);

  /// Apps mais usados no intervalo, ordenados por tempo (desc).
  List<AppUsage> topApps(DateTime start, DateTime end, {int limit = 5}) {
    final totals = <String, int>{};
    for (final e in byDay.entries) {
      if (!_inRange(e.key, start, end)) continue;
      e.value.appSeconds.forEach((app, secs) {
        totals[app] = (totals[app] ?? 0) + secs;
      });
    }
    final list = totals.entries
        .map((e) => AppUsage(appName: e.key, seconds: e.value))
        .toList()
      ..sort((a, b) => b.seconds.compareTo(a.seconds));
    return list.length <= limit ? list : list.sublist(0, limit);
  }

  /// Descarta dias mais antigos que [maxRetainedDays] em relação a [now].
  ActivityStatsData pruned(DateTime now) {
    final cutoff = dayKey(now.subtract(const Duration(days: maxRetainedDays)));
    final next = <String, ActivityDayStat>{
      for (final e in byDay.entries)
        if (e.key.compareTo(cutoff) >= 0) e.key: e.value,
    };
    return ActivityStatsData(next);
  }

  String toJson() => jsonEncode(
        byDay.map((key, value) => MapEntry(key, value.toMap())),
      );

  factory ActivityStatsData.fromJson(String? source) {
    if (source == null || source.isEmpty) return ActivityStatsData.empty();
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map) return ActivityStatsData.empty();
      final byDay = <String, ActivityDayStat>{};
      decoded.forEach((key, value) {
        if (key is String && value is Map) {
          byDay[key] =
              ActivityDayStat.fromMap(Map<String, dynamic>.from(value));
        }
      });
      return ActivityStatsData(byDay);
    } catch (_) {
      return ActivityStatsData.empty();
    }
  }
}
