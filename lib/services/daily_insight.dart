import 'package:flutter/foundation.dart';

import '../l10n/app_strings.dart';
import '../models/break_stats_data.dart';
import '../models/dvrs_assessment.dart';
import '../utils/constants.dart';

/// Tipo de insight proativo gerado a partir de dados locais.
enum InsightKind {
  /// Ainda sem histórico de pausas.
  start,

  /// Sequência ativa de adesão.
  streak,

  /// Adesão recente (7 dias).
  adherence,

  /// Total acumulado de pausas.
  consistency,

  /// Nunca fez o DVRS (com uso suficiente do app).
  dvrsNever,

  /// DVRS vencido para reavaliação.
  dvrsDue,

  /// Dia em andamento sem narrativa forte.
  today,
}

/// Insight local, sem telemetria — texto já localizado.
@immutable
class DailyInsight {
  const DailyInsight({
    required this.kind,
    required this.message,
    this.dvrsNudge = false,
  });

  final InsightKind kind;
  final String message;

  /// Quando verdadeiro, a UI deve destacar o CTA de reavaliação do DVRS.
  final bool dvrsNudge;
}

/// Snapshot do “Resumo do dia” (números + insight), 100% local.
@immutable
class DaySummarySnapshot {
  const DaySummarySnapshot({
    required this.todayCompleted,
    required this.todayReminders,
    required this.streak,
    required this.adherence7,
    required this.hasAdherence7,
    required this.lastDvrs,
    required this.daysSinceDvrs,
    required this.dvrsNudgeDue,
    required this.insight,
  });

  final int todayCompleted;
  final int todayReminders;
  final int streak;
  final double adherence7;
  final bool hasAdherence7;
  final DvrsResult? lastDvrs;

  /// `null` se nunca fez o DVRS.
  final int? daysSinceDvrs;
  final bool dvrsNudgeDue;
  final DailyInsight insight;
}

/// Regras puras de insight e nudge de reavaliação do DVRS.
class DailyInsightEngine {
  DailyInsightEngine._();

  /// Intervalo padrão entre reavaliações educacionais do DVRS.
  static const int defaultDvrsIntervalDays = AppDefaults.dvrsReminderDays;

  /// Dias de silêncio após o usuário adiar o lembrete.
  static const int defaultSnoozeDays = 7;

  /// Uso mínimo do app antes de notificar quem nunca fez o DVRS.
  static const int minBreaksBeforeFirstDvrsNudge = 3;

  /// Indica se o lembrete de reavaliação está ativo neste momento.
  static bool isDvrsNudgeDue({
    required DateTime now,
    required bool enabled,
    DateTime? lastDvrsAt,
    DateTime? snoozedUntil,
    int intervalDays = defaultDvrsIntervalDays,
    int totalCompletedBreaks = 0,
  }) {
    if (!enabled) return false;
    if (snoozedUntil != null && !now.isAfter(snoozedUntil)) return false;

    if (lastDvrsAt == null) {
      // Nunca fez: só incentiva depois de algum uso real (evita barulho no dia 1).
      return totalCompletedBreaks >= minBreaksBeforeFirstDvrsNudge;
    }

    final lastDay = DateTime(
      lastDvrsAt.year,
      lastDvrsAt.month,
      lastDvrsAt.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    return today.difference(lastDay).inDays >= intervalDays;
  }

  /// Data até a qual o lembrete fica adiado a partir de [now].
  static DateTime snoozeUntil(
    DateTime now, {
    int snoozeDays = defaultSnoozeDays,
  }) {
    return DateTime(now.year, now.month, now.day)
        .add(Duration(days: snoozeDays));
  }

  /// Monta o insight prioritário (DVRS > streak > adesão > consistência).
  static DailyInsight buildInsight({
    required AppStrings strings,
    required BreakStatsData stats,
    required DateTime now,
    DateTime? lastDvrsAt,
    bool dvrsNudgeDue = false,
  }) {
    if (dvrsNudgeDue) {
      if (lastDvrsAt == null) {
        return DailyInsight(
          kind: InsightKind.dvrsNever,
          message: strings.insightDvrsNever,
          dvrsNudge: true,
        );
      }
      final days = _daysBetween(lastDvrsAt, now);
      return DailyInsight(
        kind: InsightKind.dvrsDue,
        message: strings.insightDvrsDueText(days),
        dvrsNudge: true,
      );
    }

    final streak = stats.currentStreak(now);
    if (streak >= 2) {
      return DailyInsight(
        kind: InsightKind.streak,
        message: strings.progressInsightStreakText(streak),
      );
    }

    final from7 = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));
    final sum7 = stats.sumForRange(from7, now);
    if (sum7.reminders > 0) {
      final pct = (stats.adherenceForRange(from7, now) * 100).round();
      return DailyInsight(
        kind: InsightKind.adherence,
        message: strings.progressInsightAdherenceText(pct),
      );
    }

    final today = stats.forDay(now);
    if (today.completed > 0) {
      return DailyInsight(
        kind: InsightKind.today,
        message: strings.insightTodayText(today.completed, today.reminders),
      );
    }

    if (stats.totalCompleted > 0) {
      return DailyInsight(
        kind: InsightKind.consistency,
        message:
            strings.progressInsightConsistencyText(stats.totalCompleted),
      );
    }

    return DailyInsight(
      kind: InsightKind.start,
      message: strings.progressInsightStart,
    );
  }

  /// Agrega números do dia + insight para a tela hub.
  static DaySummarySnapshot buildSnapshot({
    required AppStrings strings,
    required BreakStatsData stats,
    required DateTime now,
    DvrsResult? lastDvrs,
    DateTime? snoozedUntil,
    bool dvrsReminderEnabled = true,
    int intervalDays = defaultDvrsIntervalDays,
  }) {
    final today = stats.forDay(now);
    final from7 = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));
    final sum7 = stats.sumForRange(from7, now);
    final lastAt = lastDvrs?.createdAt;
    final nudge = isDvrsNudgeDue(
      now: now,
      enabled: dvrsReminderEnabled,
      lastDvrsAt: lastAt,
      snoozedUntil: snoozedUntil,
      intervalDays: intervalDays,
      totalCompletedBreaks: stats.totalCompleted,
    );

    return DaySummarySnapshot(
      todayCompleted: today.completed,
      todayReminders: today.reminders,
      streak: stats.currentStreak(now),
      adherence7: stats.adherenceForRange(from7, now),
      hasAdherence7: sum7.reminders > 0,
      lastDvrs: lastDvrs,
      daysSinceDvrs: lastAt == null ? null : _daysBetween(lastAt, now),
      dvrsNudgeDue: nudge,
      insight: buildInsight(
        strings: strings,
        stats: stats,
        now: now,
        lastDvrsAt: lastAt,
        dvrsNudgeDue: nudge,
      ),
    );
  }

  static int _daysBetween(DateTime from, DateTime to) {
    final a = DateTime(from.year, from.month, from.day);
    final b = DateTime(to.year, to.month, to.day);
    return b.difference(a).inDays;
  }
}
