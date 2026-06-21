import 'package:dry_eye_widget/models/break_stats_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final day = DateTime(2026, 6, 21, 10);

  test('incremented acumula lembretes e concluídas no mesmo dia', () {
    final data = BreakStatsData.empty()
        .incremented(day, reminders: 1)
        .incremented(day, reminders: 1, completed: 1)
        .incremented(day, completed: 1);
    final stat = data.forDay(day);
    expect(stat.reminders, 2);
    expect(stat.completed, 2);
    expect(stat.skipped, 0);
  });

  test('skipped nunca é negativo', () {
    final data = BreakStatsData.empty().incremented(day, completed: 3);
    expect(data.forDay(day).skipped, 0);
  });

  test('sumForRange soma apenas dias dentro do intervalo', () {
    final data = BreakStatsData.empty()
        .incremented(day, reminders: 5, completed: 4)
        .incremented(day.subtract(const Duration(days: 1)),
            reminders: 2, completed: 2)
        .incremented(day.subtract(const Duration(days: 40)),
            reminders: 9, completed: 9);
    final sum = data.sumForRange(
        day.subtract(const Duration(days: 7)), day);
    expect(sum.reminders, 7);
    expect(sum.completed, 6);
  });

  test('serialização round-trip preserva os dados', () {
    final data = BreakStatsData.empty()
        .incremented(day, reminders: 3, completed: 2);
    final restored = BreakStatsData.fromJson(data.toJson());
    expect(restored.forDay(day).reminders, 3);
    expect(restored.forDay(day).completed, 2);
  });

  test('fromJson tolera entrada inválida', () {
    expect(BreakStatsData.fromJson(null).byDay, isEmpty);
    expect(BreakStatsData.fromJson('lixo {[').byDay, isEmpty);
  });

  test('pruned remove dias além da retenção', () {
    final data = BreakStatsData.empty()
        .incremented(day, reminders: 1)
        .incremented(day.subtract(const Duration(days: 500)), reminders: 1);
    final pruned = data.pruned(day);
    expect(pruned.byDay, hasLength(1));
  });
}
