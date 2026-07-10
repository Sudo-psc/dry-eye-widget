import 'package:dry_eye_widget/l10n/app_strings.dart';
import 'package:dry_eye_widget/models/break_stats_data.dart';
import 'package:dry_eye_widget/services/daily_insight.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 7, 9, 12);

  group('DailyInsightEngine.isDvrsNudgeDue', () {
    test('respeita opt-out', () {
      expect(
        DailyInsightEngine.isDvrsNudgeDue(
          now: now,
          enabled: false,
          lastDvrsAt: null,
          totalCompletedBreaks: 10,
        ),
        isFalse,
      );
    });

    test('nunca feito: só após uso mínimo', () {
      expect(
        DailyInsightEngine.isDvrsNudgeDue(
          now: now,
          enabled: true,
          lastDvrsAt: null,
          totalCompletedBreaks: 2,
        ),
        isFalse,
      );
      expect(
        DailyInsightEngine.isDvrsNudgeDue(
          now: now,
          enabled: true,
          lastDvrsAt: null,
          totalCompletedBreaks: 3,
        ),
        isTrue,
      );
    });

    test('reavaliação após intervalo de 14 dias', () {
      expect(
        DailyInsightEngine.isDvrsNudgeDue(
          now: now,
          enabled: true,
          lastDvrsAt: DateTime(2026, 7, 1),
          totalCompletedBreaks: 20,
        ),
        isFalse,
      );
      expect(
        DailyInsightEngine.isDvrsNudgeDue(
          now: now,
          enabled: true,
          lastDvrsAt: DateTime(2026, 6, 20),
          totalCompletedBreaks: 20,
        ),
        isTrue,
      );
    });

    test('snooze bloqueia o nudge', () {
      expect(
        DailyInsightEngine.isDvrsNudgeDue(
          now: now,
          enabled: true,
          lastDvrsAt: DateTime(2026, 6, 1),
          snoozedUntil: DateTime(2026, 7, 16),
          totalCompletedBreaks: 20,
        ),
        isFalse,
      );
    });
  });

  group('DailyInsightEngine.buildInsight', () {
    test('prioriza DVRS quando vencido', () {
      final stats = BreakStatsData({
        '2026-07-09': const BreakDayStat(reminders: 4, completed: 3),
      });
      final insight = DailyInsightEngine.buildInsight(
        strings: ptStrings,
        stats: stats,
        now: now,
        lastDvrsAt: DateTime(2026, 6, 1),
        dvrsNudgeDue: true,
      );
      expect(insight.kind, InsightKind.dvrsDue);
      expect(insight.dvrsNudge, isTrue);
      expect(insight.message, contains('dias'));
    });

    test('streak quando há sequência', () {
      final stats = BreakStatsData({
        '2026-07-07': const BreakDayStat(reminders: 5, completed: 4),
        '2026-07-08': const BreakDayStat(reminders: 5, completed: 4),
        '2026-07-09': const BreakDayStat(reminders: 5, completed: 4),
      });
      final insight = DailyInsightEngine.buildInsight(
        strings: ptStrings,
        stats: stats,
        now: now,
        dvrsNudgeDue: false,
      );
      expect(insight.kind, InsightKind.streak);
      expect(insight.message, contains('3'));
    });

    test('início sem dados', () {
      final insight = DailyInsightEngine.buildInsight(
        strings: ptStrings,
        stats: BreakStatsData.empty(),
        now: now,
      );
      expect(insight.kind, InsightKind.start);
    });
  });

  group('DaySummarySnapshot', () {
    test('agrega hoje e flag de nudge', () {
      final stats = BreakStatsData({
        '2026-07-09': const BreakDayStat(reminders: 6, completed: 4),
      });
      final snap = DailyInsightEngine.buildSnapshot(
        strings: ptStrings,
        stats: stats,
        now: now,
        lastDvrs: null,
        dvrsReminderEnabled: true,
      );
      expect(snap.todayCompleted, 4);
      expect(snap.todayReminders, 6);
      // totalCompleted = 4 >= 3 → nudge de "nunca fez"
      expect(snap.dvrsNudgeDue, isTrue);
      expect(snap.insight.dvrsNudge, isTrue);
    });
  });

  test('snoozeUntil avança 7 dias a partir da meia-noite', () {
    final until = DailyInsightEngine.snoozeUntil(now);
    expect(until, DateTime(2026, 7, 16));
  });
}
