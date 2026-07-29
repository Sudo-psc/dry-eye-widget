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
  }) =>
      builder.build(
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
      final breaks =
          BreakStatsData.empty().incremented(now, reminders: 10, completed: 8);
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
      final breaks =
          BreakStatsData.empty().incremented(now, reminders: 10, completed: 3);
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
