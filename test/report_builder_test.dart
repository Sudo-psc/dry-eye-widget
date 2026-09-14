import 'package:dry_eye_widget/models/break_stats_data.dart';
import 'package:dry_eye_widget/models/dvrs_assessment.dart';
import 'package:dry_eye_widget/models/report_options.dart';
import 'package:dry_eye_widget/models/screen_time_data.dart';
import 'package:dry_eye_widget/services/dvrs_engine.dart';
import 'package:dry_eye_widget/services/report_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const builder = ReportBuilder();
  final now = DateTime(2026, 6, 21, 12);

  /// Constrói um resultado DVRS com todas as 16 respostas no valor [value].
  DvrsResult dvrs(int value, {int daysAgo = 1, String id = 'r'}) {
    final answers = [
      for (var i = 0; i < 16; i++)
        DvrsAnswer(
          questionId: 'q${i + 1}',
          domain: i < 6
              ? DvrsDomain.symptoms
              : i < 9
              ? DvrsDomain.functional
              : i < 12
              ? DvrsDomain.exposure
              : i < 15
              ? DvrsDomain.environment
              : DvrsDomain.warning,
          value: value,
          label: 'opt',
        ),
    ];
    return evaluateDvrs(
      answers: answers,
      id: id,
      now: now.subtract(Duration(days: daysAgo)),
    );
  }

  ReportData build({
    List<DvrsResult> dvrsHistory = const [],
    ScreenTimeData? screenTime,
    BreakStatsData? breakStats,
    int days = 30,
  }) => builder.build(
    profile: const UserProfile(),
    options: ReportOptions(
      startDate: now.subtract(Duration(days: days)),
      endDate: now,
    ),
    screenTime: screenTime ?? ScreenTimeData.empty(),
    breakStats: breakStats ?? BreakStatsData.empty(),
    dvrsHistory: dvrsHistory,
    now: now,
  );

  group('DVRS', () {
    test('inclui o DVRS quando há histórico', () {
      final data = build(dvrsHistory: [dvrs(2, id: 'a')]);
      expect(data.dvrs, isNotNull);
      expect(data.dvrs!.latest.id, 'a');
      expect(data.dvrs!.latest.totalScore, 50);
    });

    test('dvrs é null sem histórico', () {
      expect(build().dvrs, isNull);
    });
  });

  group('Tempo de tela', () {
    test(
      'intervalo personalizado inclui os mesmos dias para tela e pausas',
      () {
        final screen = ScreenTimeData({
          '2026-09-11': 9999,
          '2026-09-12': 3600,
          '2026-09-13': 3600,
          '2026-09-14': 3600,
          '2026-09-15': 9999,
        });
        var breaks = BreakStatsData.empty();
        for (var day = 11; day <= 15; day++) {
          breaks = breaks.incremented(
            DateTime(2026, 9, day),
            reminders: 1,
            completed: 1,
          );
        }
        final data = builder.build(
          profile: const UserProfile(),
          options: ReportOptions(
            period: ReportPeriod.custom,
            startDate: DateTime(2026, 9, 12, 23),
            endDate: DateTime(2026, 9, 14, 1),
          ),
          screenTime: screen,
          breakStats: breaks,
        );
        expect(data.options.days, 3);
        expect(data.screenTime.series, hasLength(3));
        expect(data.screenTime.totalSeconds, 10800);
        expect(data.breaks.reminders, 3);
        expect(data.breaks.completed, 3);
      },
    );

    test('presets cobrem exatamente N dias civis até hoje', () {
      for (final period in [
        ReportPeriod.last7,
        ReportPeriod.last30,
        ReportPeriod.last90,
      ]) {
        final options = ReportOptions.forPeriod(
          period: period,
          endDate: DateTime(2026, 3, 9, 12),
        );
        final excluded = DateTime(
          options.startDate.year,
          options.startDate.month,
          options.startDate.day - 1,
        );
        final data = builder.build(
          profile: const UserProfile(),
          options: options,
          screenTime: ScreenTimeData.empty()
              .addSeconds(excluded, 9999)
              .addSeconds(options.startDate, 60)
              .addSeconds(options.endDate, 120),
          breakStats: BreakStatsData.empty()
              .incremented(excluded, reminders: 99)
              .incremented(options.startDate, reminders: 1)
              .incremented(options.endDate, reminders: 2),
        );
        expect(options.days, period.days);
        expect(data.screenTime.series, hasLength(period.days!));
        expect(data.screenTime.totalSeconds, 180);
        expect(data.breaks.reminders, 3);
      }
    });

    test('contagem civil inclui dias de 23h e de 25h', () {
      // Rodar também com TZ=America/New_York para cobrir as transições reais.
      for (final start in [DateTime(2026, 3, 8), DateTime(2026, 11, 1)]) {
        final end = DateTime(start.year, start.month, start.day + 1);
        expect(ReportOptions(startDate: start, endDate: end).days, 2);
      }
    });

    test('calcula média diária apenas sobre dias com dados', () {
      final st = ScreenTimeData({
        ScreenTimeData.dayKey(now): 3600,
        ScreenTimeData.dayKey(now.subtract(const Duration(days: 1))): 1800,
      });
      final data = build(screenTime: st);
      expect(data.screenTime.totalSeconds, 5400);
      expect(data.screenTime.daysWithData, 2);
      expect(data.screenTime.averageDailySeconds, 2700);
      expect(data.screenTime.peakDay!.seconds, 3600);
    });

    test('período sem tempo de tela retorna summary vazio', () {
      final data = build();
      expect(data.screenTime.hasData, isFalse);
      expect(data.screenTime.averageDailySeconds, 0);
    });
  });

  group('Pausas', () {
    test('calcula taxa de adesão concluídas/lembretes', () {
      final breaks = BreakStatsData.empty().incremented(
        now,
        reminders: 10,
        completed: 8,
      );
      final data = build(breakStats: breaks);
      expect(data.breaks.reminders, 10);
      expect(data.breaks.completed, 8);
      expect(data.breaks.skipped, 2);
      expect(data.breaks.adherenceRate, closeTo(0.8, 0.001));
    });

    test('sem pausas registradas, adesão é nula', () {
      final data = build();
      expect(data.breaks.hasData, isFalse);
      expect(data.breaks.adherenceRate, isNull);
    });
  });

  group('Indicação e alertas', () {
    test('resposta prioritária Q16 gera indicação de avaliação e alerta', () {
      // Todas as respostas em 4 incluem Q16=4, o gatilho de segurança.
      final data = build(dvrsHistory: [dvrs(4)]);
      expect(data.indication, OverallIndication.seekEvaluation);
      expect(data.alerts, isNotEmpty);
    });

    test('DVRS baixo sem outros gatilhos indica acompanhar', () {
      final data = build(dvrsHistory: [dvrs(0)]);
      expect(data.indication, OverallIndication.monitor);
      expect(data.alerts, isEmpty);
    });

    test('baixa adesão sem dados clínicos indica reforçar pausas', () {
      final breaks = BreakStatsData.empty().incremented(
        now,
        reminders: 10,
        completed: 3,
      );
      final data = build(breakStats: breaks);
      expect(data.indication, OverallIndication.reinforceBreaks);
    });
  });

  test('relatório totalmente vazio não lança e indica acompanhar', () {
    final data = build();
    expect(data.dvrs, isNull);
    expect(data.indication, OverallIndication.monitor);
    expect(data.alerts, isEmpty);
  });
}
