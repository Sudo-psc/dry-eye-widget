import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Estatística de pausas visuais de um único dia.
@immutable
class BreakDayStat {
  const BreakDayStat({this.reminders = 0, this.completed = 0});

  /// Quantos avisos de pausa foram emitidos no dia.
  final int reminders;

  /// Quantas pausas foram efetivamente concluídas (ciclo de pausa finalizado).
  final int completed;

  /// Pausas ignoradas/interrompidas (nunca negativo).
  int get skipped => (reminders - completed).clamp(0, reminders);

  BreakDayStat copyWith({int? reminders, int? completed}) => BreakDayStat(
    reminders: reminders ?? this.reminders,
    completed: completed ?? this.completed,
  );
}

/// Histórico local das pausas visuais por dia.
///
/// Guarda um mapa imutável `'AAAA-MM-DD' -> {lembretes, concluídas}`. É o
/// análogo de [ScreenTimeData] para o ciclo de pausas: registra quantos avisos
/// foram emitidos e quantas pausas chegaram ao fim, permitindo calcular a taxa
/// de adesão no relatório. Serializável para JSON.
@immutable
class BreakStatsData {
  BreakStatsData(Map<String, BreakDayStat> byDay)
    : byDay = Map<String, BreakDayStat>.unmodifiable(byDay);

  /// Mapa dia (`'AAAA-MM-DD'`) -> estatística do dia.
  final Map<String, BreakDayStat> byDay;

  /// Retenção máxima de dias (cobre o histórico anual com folga).
  static const int maxRetainedDays = 400;

  factory BreakStatsData.empty() => BreakStatsData(const <String, BreakDayStat>{});

  // --- Chaves de dia ------------------------------------------------------

  static String dayKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static DateTime _dayFromKey(String key) {
    final parts = key.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  // --- Consultas ----------------------------------------------------------

  BreakDayStat forDay(DateTime date) =>
      byDay[dayKey(date)] ?? const BreakDayStat();

  /// Soma das estatísticas no intervalo [start, end] (ambos inclusivos, por dia).
  BreakDayStat sumForRange(DateTime start, DateTime end) {
    final from = DateTime(start.year, start.month, start.day);
    final to = DateTime(end.year, end.month, end.day);
    var reminders = 0;
    var completed = 0;
    for (final entry in byDay.entries) {
      final day = _dayFromKey(entry.key);
      if (!day.isBefore(from) && !day.isAfter(to)) {
        reminders += entry.value.reminders;
        completed += entry.value.completed;
      }
    }
    return BreakDayStat(reminders: reminders, completed: completed);
  }

  // --- Mutação imutável ---------------------------------------------------

  /// Devolve uma cópia com +[reminders] e +[completed] somados ao dia [date].
  BreakStatsData incremented(
    DateTime date, {
    int reminders = 0,
    int completed = 0,
  }) {
    final next = Map<String, BreakDayStat>.from(byDay);
    final key = dayKey(date);
    final current = next[key] ?? const BreakDayStat();
    next[key] = current.copyWith(
      reminders: current.reminders + reminders,
      completed: current.completed + completed,
    );
    return BreakStatsData(next);
  }

  /// Remove dias mais antigos que [maxRetainedDays] contados a partir de [now].
  BreakStatsData pruned(DateTime now) {
    final cutoff = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: maxRetainedDays));
    final next = <String, BreakDayStat>{};
    for (final entry in byDay.entries) {
      if (!_dayFromKey(entry.key).isBefore(cutoff)) {
        next[entry.key] = entry.value;
      }
    }
    return BreakStatsData(next);
  }

  // --- Serialização -------------------------------------------------------

  String toJson() => jsonEncode(
    byDay.map(
      (key, value) => MapEntry(key, {'r': value.reminders, 'c': value.completed}),
    ),
  );

  factory BreakStatsData.fromJson(String? source) {
    if (source == null || source.isEmpty) return BreakStatsData.empty();
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map) return BreakStatsData.empty();
      final result = <String, BreakDayStat>{};
      decoded.forEach((key, value) {
        if (key is! String || value is! Map) return;
        final r = value['r'];
        final c = value['c'];
        final reminders = r is num ? r.toInt() : 0;
        final completed = c is num ? c.toInt() : 0;
        if (reminders > 0 || completed > 0) {
          result[key] = BreakDayStat(reminders: reminders, completed: completed);
        }
      });
      return BreakStatsData(result);
    } catch (_) {
      return BreakStatsData.empty();
    }
  }
}
