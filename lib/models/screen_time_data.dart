import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Um ponto de uso de tela: o dia (à meia-noite local) e os segundos acumulados.
@immutable
class ScreenTimePoint {
  const ScreenTimePoint(this.day, this.seconds);

  /// Data normalizada para meia-noite local.
  final DateTime day;

  /// Segundos de uso ativo de tela naquele dia.
  final int seconds;
}

/// Histórico local do tempo de uso diário de tela.
///
/// Guarda um mapa imutável `'AAAA-MM-DD' -> segundos`. Apenas tempo ativo é
/// contabilizado (a inatividade é descartada pelo `TimerProvider`). É
/// serializável para JSON e oferece agregações (semana/mês/ano) para a janela
/// de visualização.
@immutable
class ScreenTimeData {
  ScreenTimeData(Map<String, int> secondsByDay)
    : secondsByDay = Map<String, int>.unmodifiable(secondsByDay);

  /// Mapa dia (`'AAAA-MM-DD'`) -> segundos de uso ativo.
  final Map<String, int> secondsByDay;

  /// Retenção máxima de dias (cobre o histórico anual com folga).
  static const int maxRetainedDays = 400;

  factory ScreenTimeData.empty() => ScreenTimeData(const <String, int>{});

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

  int secondsForDay(DateTime date) => secondsByDay[dayKey(date)] ?? 0;

  /// Segundos do dia [date]; usado pelo destaque "hoje".
  int secondsForKey(String key) => secondsByDay[key] ?? 0;

  /// Série diária para os [days] dias terminando em [end] (inclusive),
  /// em ordem cronológica crescente.
  List<ScreenTimePoint> dailySeries(DateTime end, int days) {
    final base = DateTime(end.year, end.month, end.day);
    return List<ScreenTimePoint>.generate(days, (i) {
      final day = base.subtract(Duration(days: days - 1 - i));
      return ScreenTimePoint(day, secondsForDay(day));
    });
  }

  /// Semana (segunda a domingo) que contém [reference].
  List<ScreenTimePoint> weekSeries(DateTime reference) {
    final ref = DateTime(reference.year, reference.month, reference.day);
    final monday = ref.subtract(Duration(days: ref.weekday - 1));
    return List<ScreenTimePoint>.generate(7, (i) {
      final day = monday.add(Duration(days: i));
      return ScreenTimePoint(day, secondsForDay(day));
    });
  }

  /// Todos os dias do mês de [reference], em ordem.
  List<ScreenTimePoint> monthSeries(DateTime reference) {
    final daysInMonth = DateTime(
      reference.year,
      reference.month + 1,
      0,
    ).day;
    return List<ScreenTimePoint>.generate(daysInMonth, (i) {
      final day = DateTime(reference.year, reference.month, i + 1);
      return ScreenTimePoint(day, secondsForDay(day));
    });
  }

  /// Soma por mês (12 meses) do ano de [reference]. O campo `day` aponta para
  /// o primeiro dia de cada mês.
  List<ScreenTimePoint> yearSeries(DateTime reference) {
    final yearPrefix = '${reference.year.toString().padLeft(4, '0')}-';

    final totals = secondsByDay.entries
        .where((e) => e.key.startsWith(yearPrefix))
        .fold<List<int>>(
          List<int>.filled(12, 0),
          (acc, e) {
            final month = int.parse(e.key.substring(5, 7));
            acc[month - 1] += e.value;
            return acc;
          },
        );

    return List<ScreenTimePoint>.generate(
      12,
      (i) => ScreenTimePoint(DateTime(reference.year, i + 1, 1), totals[i]),
    );
  }

  // --- Mutação imutável ---------------------------------------------------

  /// Devolve uma cópia com [delta] segundos somados ao dia [date].
  ScreenTimeData addSeconds(DateTime date, int delta) {
    final next = Map<String, int>.from(secondsByDay);
    final key = dayKey(date);
    next[key] = (next[key] ?? 0) + delta;
    return ScreenTimeData(next);
  }

  /// Remove dias mais antigos que [maxRetainedDays] contados a partir de [now].
  ScreenTimeData pruned(DateTime now) {
    final cutoff = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: maxRetainedDays));
    final next = <String, int>{};
    for (final entry in secondsByDay.entries) {
      if (!_dayFromKey(entry.key).isBefore(cutoff)) {
        next[entry.key] = entry.value;
      }
    }
    return ScreenTimeData(next);
  }

  // --- Serialização -------------------------------------------------------

  String toJson() => jsonEncode(secondsByDay);

  factory ScreenTimeData.fromJson(String? source) {
    if (source == null || source.isEmpty) return ScreenTimeData.empty();
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map) return ScreenTimeData.empty();
      final result = <String, int>{};
      decoded.forEach((key, value) {
        if (key is String && value is num && value > 0) {
          result[key] = value.toInt();
        }
      });
      return ScreenTimeData(result);
    } catch (_) {
      return ScreenTimeData.empty();
    }
  }
}
