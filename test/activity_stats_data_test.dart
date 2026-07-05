import 'package:dry_eye_widget/models/activity_stats_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final day1 = DateTime(2026, 7, 5, 10);
  final day2 = DateTime(2026, 7, 6, 9);

  group('ActivityStatsData', () {
    test('começa vazio e acumula cliques/teclas por dia', () {
      var d = ActivityStatsData.empty();
      d = d.incremented(day1, clicks: 5, keys: 20);
      d = d.incremented(day1, clicks: 3, keys: 10);
      d = d.incremented(day2, clicks: 1);
      expect(d.clicksForDay(day1), 8);
      expect(d.keysForDay(day1), 30);
      expect(d.clicksForDay(day2), 1);
      expect(d.keysForDay(day2), 0);
    });

    test('acumula tempo por app por dia', () {
      var d = ActivityStatsData.empty();
      d = d.addAppSeconds(day1, 'Safari', 300);
      d = d.addAppSeconds(day1, 'Xcode', 900);
      d = d.addAppSeconds(day1, 'Safari', 120);
      expect(d.appSecondsForDay(day1)['Safari'], 420);
      expect(d.appSecondsForDay(day1)['Xcode'], 900);
    });

    test('topApps agrega o intervalo e ordena por tempo', () {
      var d = ActivityStatsData.empty();
      d = d.addAppSeconds(day1, 'Safari', 300);
      d = d.addAppSeconds(day2, 'Safari', 300);
      d = d.addAppSeconds(day1, 'Xcode', 900);
      d = d.addAppSeconds(day2, 'Mail', 100);
      final top = d.topApps(day1, day2, limit: 2);
      expect(top.length, 2);
      expect(top.first.appName, 'Xcode');
      expect(top.first.seconds, 900);
      expect(top[1].appName, 'Safari');
      expect(top[1].seconds, 600);
    });

    test('totais de cliques/teclas no intervalo', () {
      var d = ActivityStatsData.empty();
      d = d.incremented(day1, clicks: 5, keys: 50);
      d = d.incremented(day2, clicks: 7, keys: 70);
      expect(d.clicksForRange(day1, day2), 12);
      expect(d.keysForRange(day1, day2), 120);
      expect(d.clicksForRange(day2, day2), 7);
    });

    test('round-trip json preserva tudo', () {
      var d = ActivityStatsData.empty();
      d = d.incremented(day1, clicks: 8, keys: 30);
      d = d.addAppSeconds(day1, 'Safari', 420);
      final restored = ActivityStatsData.fromJson(d.toJson());
      expect(restored.clicksForDay(day1), 8);
      expect(restored.keysForDay(day1), 30);
      expect(restored.appSecondsForDay(day1)['Safari'], 420);
    });

    test('fromJson tolera entrada inválida', () {
      expect(ActivityStatsData.fromJson(null).clicksForDay(day1), 0);
      expect(ActivityStatsData.fromJson('lixo').clicksForDay(day1), 0);
    });

    test('pruned descarta dias além da retenção', () {
      var d = ActivityStatsData.empty();
      final old = day1.subtract(
        const Duration(days: ActivityStatsData.maxRetainedDays + 10),
      );
      d = d.incremented(old, clicks: 5);
      d = d.incremented(day1, clicks: 1);
      final p = d.pruned(day1);
      expect(p.clicksForDay(old), 0);
      expect(p.clicksForDay(day1), 1);
    });
  });
}
