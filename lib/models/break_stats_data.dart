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

  /// Adesão padrão mínima para um dia "contar" na sequência (60%).
  static const double defaultMinAdherence = 0.6;

  /// Total de pausas concluídas em todo o histórico retido.
  int get totalCompleted =>
      byDay.values.fold(0, (acc, s) => acc + s.completed);

  /// Total de avisos de pausa emitidos em todo o histórico retido.
  int get totalReminders =>
      byDay.values.fold(0, (acc, s) => acc + s.reminders);

  /// Taxa de adesão (0–1) no intervalo [start, end]; 0 se não houve avisos.
  double adherenceForRange(DateTime start, DateTime end) {
    final sum = sumForRange(start, end);
    if (sum.reminders == 0) return 0;
    return sum.completed / sum.reminders;
  }

  /// Sequência atual de dias consecutivos atingindo a adesão mínima, contada
  /// para trás a partir de [now].
  ///
  /// Dias **sem avisos** (computador desligado / sem uso de tela) são neutros:
  /// não incrementam nem quebram a sequência — reforço de hábito sem punição.
  int currentStreak(DateTime now, {double minAdherence = defaultMinAdherence}) {
    var streak = 0;
    var day = DateTime(now.year, now.month, now.day);
    for (var i = 0; i <= maxRetainedDays; i++) {
      final s = forDay(day);
      if (s.reminders == 0) {
        // Dia neutro: pula sem contar nem zerar.
        day = day.subtract(const Duration(days: 1));
        continue;
      }
      if (s.completed / s.reminders >= minAdherence) {
        streak++;
        day = day.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  /// Maior sequência já alcançada em todo o histórico retido. Dias neutros
  /// preservam a sequência em curso (mesma semântica de [currentStreak]).
  int bestStreak({double minAdherence = defaultMinAdherence}) {
    if (byDay.isEmpty) return 0;
    final days = byDay.keys.map(_dayFromKey).toList()..sort();
    final first = days.first;
    final last = days.last;
    var best = 0;
    var run = 0;
    var day = first;
    while (!day.isAfter(last)) {
      final s = forDay(day);
      if (s.reminders == 0) {
        // Neutro: mantém a sequência em curso.
      } else if (s.completed / s.reminders >= minAdherence) {
        run++;
        if (run > best) best = run;
      } else {
        run = 0;
      }
      day = day.add(const Duration(days: 1));
    }
    return best;
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
