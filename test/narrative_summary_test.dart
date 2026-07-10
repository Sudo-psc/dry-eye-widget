import 'package:dry_eye_widget/models/break_stats_data.dart';
import 'package:dry_eye_widget/models/dvrs_assessment.dart';
import 'package:dry_eye_widget/models/report_options.dart';
import 'package:dry_eye_widget/models/screen_time_data.dart';
import 'package:dry_eye_widget/services/dvrs_engine.dart';
import 'package:dry_eye_widget/services/narrative_summary.dart';
import 'package:dry_eye_widget/services/report_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 7, 10, 12);

  DvrsResult dvrs(int value) {
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
    return evaluateDvrs(answers: answers, id: 'r1', now: now);
  }

  test('ReportBuilder preenche narrativa educativa sem linguagem diagnóstica', () {
    const builder = ReportBuilder();
    final data = builder.build(
      profile: const UserProfile(),
      options: ReportOptions(
        startDate: now.subtract(const Duration(days: 30)),
        endDate: now,
      ),
      screenTime: ScreenTimeData({
        ScreenTimeData.dayKey(now): 7200,
      }),
      breakStats: BreakStatsData({
        BreakStatsData.dayKey(now): const BreakDayStat(reminders: 4, completed: 3),
      }),
      dvrsHistory: [dvrs(2)],
      now: now,
    );

    expect(data.narrative, isNotNull);
    expect(data.narrative!, isNotEmpty);
    final lower = data.narrative!.toLowerCase();
    expect(lower.contains('diagnóstico confirmado'), isFalse);
    expect(lower.contains('você tem doença'), isFalse);
    expect(data.narrative!.contains('DVRS'), isTrue);

    final pure = NarrativeSummary.buildPt(data);
    expect(pure, contains('oftalmolog'));
  });
}
