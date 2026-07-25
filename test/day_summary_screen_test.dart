import 'package:dry_eye_widget/l10n/app_strings.dart';
import 'package:dry_eye_widget/models/break_stats_data.dart';
import 'package:dry_eye_widget/models/widget_settings.dart';
import 'package:dry_eye_widget/providers/settings_provider.dart';
import 'package:dry_eye_widget/services/dvrs_storage_service.dart';
import 'package:dry_eye_widget/services/storage_service.dart';
import 'package:dry_eye_widget/ui/app_theme.dart';
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
        BreakStatsData.dayKey(DateTime.now()): const BreakDayStat(
          reminders: 4,
          completed: 3,
        ),
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
    expect(find.text(ptStrings.daySummaryCtaDashboard), findsNothing);
    expect(
      find.byKey(const ValueKey('day-summary-primary-action')),
      findsOneWidget,
    );

    final statLabel = tester.widget<Text>(
      find.text(ptStrings.daySummaryTodayLabel),
    );
    final statHint = tester.widget<Text>(
      find.text(ptStrings.daySummaryTodayHint),
    );
    final disclaimer = tester.widget<Text>(
      find.text(ptStrings.daySummaryDisclaimer),
    );
    expect(
      statLabel.style?.fontSize,
      greaterThanOrEqualTo(AppTypography.supporting),
    );
    expect(
      statHint.style?.fontSize,
      greaterThanOrEqualTo(AppTypography.minimumReadable),
    );
    expect(
      disclaimer.style?.fontSize,
      greaterThanOrEqualTo(AppTypography.supporting),
    );
    expect(statLabel.style?.color?.a, greaterThanOrEqualTo(0.8));
    expect(statHint.style?.color?.a, greaterThanOrEqualTo(0.72));
    expect(disclaimer.style?.color?.a, greaterThanOrEqualTo(0.72));

    await tester.tap(find.byKey(const ValueKey('day-summary-dvrs-card')));
    await tester.pump();
    expect(openedDvrs, 1);

    await tester.ensureVisible(find.text(ptStrings.daySummaryCtaBreak));
    await tester.tap(find.text(ptStrings.daySummaryCtaBreak));
    await tester.pump();
    expect(started, 1);

    await tester.ensureVisible(find.text(ptStrings.daySummaryNudgeDo));
    await tester.tap(find.text(ptStrings.daySummaryNudgeDo));
    await tester.pump();
    expect(openedDvrs, 2);
  });

  testWidgets('falha ao adiar lembrete informa erro e libera nova tentativa', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    final dvrs = await DvrsStorageService.init();
    await storage.saveBreakStats(
      BreakStatsData({
        BreakStatsData.dayKey(DateTime.now()): const BreakDayStat(
          reminders: 4,
          completed: 3,
        ),
      }),
    );
    final settings = SettingsProvider(storage: storage);
    await settings.update(
      WidgetSettings.defaults().copyWith(onboardingComplete: true),
    );

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
                onStartBreak: () {},
                onDvrs: () {},
                onProgress: () {},
                onDashboard: () {},
                onSnoozeDvrsNudge: () async => throw StateError('falha'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text(ptStrings.daySummaryNudgeDismiss));
    await tester.tap(find.text(ptStrings.daySummaryNudgeDismiss));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(ptStrings.daySummaryNudgeError), findsOneWidget);
    final button = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text(ptStrings.daySummaryNudgeDismiss),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(button.onPressed, isNotNull);
  });
}
