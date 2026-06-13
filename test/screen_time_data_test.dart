import 'package:dry_eye_widget/models/screen_time_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScreenTimeData', () {
    test('addSeconds acumula por dia', () {
      final day = DateTime(2026, 6, 13, 10);
      var data = ScreenTimeData.empty();
      data = data.addSeconds(day, 30);
      data = data.addSeconds(DateTime(2026, 6, 13, 18), 70);
      expect(data.secondsForDay(day), 100);
      expect(data.secondsForDay(DateTime(2026, 6, 12)), 0);
    });

    test('dayKey é estável e zero-padded', () {
      expect(ScreenTimeData.dayKey(DateTime(2026, 1, 5)), '2026-01-05');
      expect(ScreenTimeData.dayKey(DateTime(2026, 12, 31)), '2026-12-31');
    });

    test('roundtrip JSON preserva o mapa', () {
      var data = ScreenTimeData.empty()
          .addSeconds(DateTime(2026, 6, 10), 120)
          .addSeconds(DateTime(2026, 6, 11), 240);
      final restored = ScreenTimeData.fromJson(data.toJson());
      expect(restored.secondsForDay(DateTime(2026, 6, 10)), 120);
      expect(restored.secondsForDay(DateTime(2026, 6, 11)), 240);
    });

    test('fromJson tolera entrada inválida', () {
      expect(ScreenTimeData.fromJson(null).secondsByDay, isEmpty);
      expect(ScreenTimeData.fromJson('').secondsByDay, isEmpty);
      expect(ScreenTimeData.fromJson('não-json').secondsByDay, isEmpty);
      expect(ScreenTimeData.fromJson('[1,2,3]').secondsByDay, isEmpty);
      // Valores negativos/zero são descartados.
      expect(
        ScreenTimeData.fromJson('{"2026-06-10": -5, "2026-06-11": 0}')
            .secondsByDay,
        isEmpty,
      );
    });

    test('weekSeries cobre segunda a domingo da semana de referência', () {
      // 2026-06-13 é um sábado.
      final ref = DateTime(2026, 6, 13);
      final data = ScreenTimeData.empty().addSeconds(ref, 600);
      final week = data.weekSeries(ref);
      expect(week.length, 7);
      // Primeiro dia é segunda (2026-06-08), último é domingo (2026-06-14).
      expect(ScreenTimeData.dayKey(week.first.day), '2026-06-08');
      expect(ScreenTimeData.dayKey(week.last.day), '2026-06-14');
      // O sábado contém os 600 s.
      expect(week.firstWhere((p) => p.day.weekday == 6).seconds, 600);
    });

    test('monthSeries tem um ponto por dia do mês', () {
      final ref = DateTime(2026, 2, 15); // fevereiro de 2026 tem 28 dias
      final month = ScreenTimeData.empty().monthSeries(ref);
      expect(month.length, 28);
      expect(month.first.day.day, 1);
      expect(month.last.day.day, 28);
    });

    test('yearSeries soma por mês', () {
      var data = ScreenTimeData.empty()
          .addSeconds(DateTime(2026, 1, 5), 100)
          .addSeconds(DateTime(2026, 1, 20), 50)
          .addSeconds(DateTime(2026, 3, 2), 300)
          .addSeconds(DateTime(2025, 1, 1), 999); // ano diferente: ignorado
      final year = data.yearSeries(DateTime(2026, 6, 1));
      expect(year.length, 12);
      expect(year[0].seconds, 150); // janeiro
      expect(year[1].seconds, 0); // fevereiro
      expect(year[2].seconds, 300); // março
    });

    test('pruned remove dias além da janela de retenção', () {
      final now = DateTime(2026, 6, 13);
      final old = now.subtract(
        const Duration(days: ScreenTimeData.maxRetainedDays + 10),
      );
      final recent = now.subtract(const Duration(days: 5));
      final data = ScreenTimeData.empty()
          .addSeconds(old, 100)
          .addSeconds(recent, 200)
          .pruned(now);
      expect(data.secondsForDay(old), 0);
      expect(data.secondsForDay(recent), 200);
    });
  });
}
