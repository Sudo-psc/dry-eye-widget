import 'package:dry_eye_widget/l10n/app_strings.dart';
import 'package:dry_eye_widget/models/break_stats_data.dart';
import 'package:dry_eye_widget/models/widget_settings.dart';
import 'package:dry_eye_widget/providers/settings_provider.dart';
import 'package:dry_eye_widget/services/dvrs_storage_service.dart';
import 'package:dry_eye_widget/services/storage_service.dart';
import 'package:dry_eye_widget/widgets/summary/day_summary_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('resumo do dia mostra título, insight e CTAs', (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    final dvrs = await DvrsStorageService.init();
    await storage.saveBreakStats(
      BreakStatsData({
        BreakStatsData.dayKey(DateTime.now()):
            const BreakDayStat(reminders: 4, completed: 3),
      }),
    );
    final settings = SettingsProvider(storage: storage);
    await settings.update(
      WidgetSettings.defaults().copyWith(onboardingComplete: true),
    );

    var started = 0;
    var openedDvrs = 0;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<StorageService>.value(value: storage),
          Provider<DvrsStorageService>.value(value: dvrs),
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 700,
              height: 900,
              child: DaySummaryScreen(
                onClose: () {},
                onStartBreak: () => started++,
                onDvrs: () => openedDvrs++,
                onProgress: () {},
                onDashboard: () {},
                onSnoozeDvrsNudge: () async {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(ptStrings.daySummaryTitle), findsOneWidget);
    expect(find.text(ptStrings.daySummaryCtaBreak), findsOneWidget);
    expect(find.text(ptStrings.daySummaryNudgeTitle), findsOneWidget);

    await tester.ensureVisible(find.text(ptStrings.daySummaryCtaBreak));
    await tester.tap(find.text(ptStrings.daySummaryCtaBreak));
    await tester.pump();
    expect(started, 1);

    await tester.ensureVisible(find.text(ptStrings.daySummaryNudgeDo));
    await tester.tap(find.text(ptStrings.daySummaryNudgeDo));
    await tester.pump();
    expect(openedDvrs, 1);
  });
}
