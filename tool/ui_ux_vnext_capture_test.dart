import 'dart:io';

import 'package:dry_eye_widget/l10n/app_strings.dart';
import 'package:dry_eye_widget/l10n/feature_strings.dart';
import 'package:dry_eye_widget/models/break_stats_data.dart';
import 'package:dry_eye_widget/models/widget_settings.dart';
import 'package:dry_eye_widget/providers/settings_provider.dart';
import 'package:dry_eye_widget/services/dvrs_storage_service.dart';
import 'package:dry_eye_widget/services/screen_time_service.dart';
import 'package:dry_eye_widget/services/storage_service.dart';
import 'package:dry_eye_widget/ui/app_theme.dart';
import 'package:dry_eye_widget/widgets/floating_menu.dart';
import 'package:dry_eye_widget/widgets/health/health_hub_screen.dart';
import 'package:dry_eye_widget/widgets/onboarding/onboarding_flow.dart';
import 'package:dry_eye_widget/widgets/settings_dialog.dart';
import 'package:dry_eye_widget/widgets/summary/day_summary_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _stage = String.fromEnvironment(
  'UI_UX_CAPTURE_STAGE',
  defaultValue: 'baseline',
);
const _artifactRoot =
    '../projects/dry-eye-widget-app/artifacts/ui-ux-vnext-2026-07-16';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await (FontLoader('Inter')
          ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Inter-SemiBold.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Inter-Bold.ttf')))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    Directory('$_artifactRoot/$_stage').createSync(recursive: true);
  });

  for (final languageCode in const ['pt', 'en']) {
    testWidgets('captura superfícies vNext em $languageCode', (tester) async {
      await _captureMenu(tester, languageCode);
      await _captureSummary(tester, languageCode);
      await _captureHub(tester, languageCode, tab: 0, name: 'hub-hoje');
      await _captureHub(tester, languageCode, tab: 1, name: 'hub-tendencias');
      await _captureHub(tester, languageCode, tab: 2, name: 'hub-dvrs');
      await _captureHub(tester, languageCode, tab: 3, name: 'hub-relatorios');
      await _captureSettings(tester, languageCode);
      await _captureOnboarding(tester, languageCode);
    });
  }
}

Future<void> _captureMenu(WidgetTester tester, String languageCode) async {
  await _setSurface(tester, const Size(360, 520));
  final strings = AppStrings.of(languageCode);
  final feature = FeatureStrings.of(languageCode);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: RepaintBoundary(
        key: const ValueKey('capture'),
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Color(0xFF07121F)),
          child: Center(
            child: FloatingMenu(
              strings: strings,
              healthHubLabel: feature.menuHealthHub,
              myDataLabel: feature.menuMyData,
              isPaused: false,
              onStartNow: () {},
              onReset: () {},
              onTogglePause: () {},
              onExtendCycle: () {},
              onGuidance: () {},
              onHealthHub: () {},
              onMyData: () {},
              onCheckUpdates: () {},
              onAbout: () {},
              onSettings: () {},
              onQuit: () {},
              onDismiss: () {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await _golden(tester, languageCode, 'menu');
}

Future<void> _captureSummary(WidgetTester tester, String languageCode) async {
  final state = await _state(languageCode);
  await _setSurface(tester, const Size(700, 790));
  await tester.pumpWidget(
    _providerApp(
      state,
      RepaintBoundary(
        key: const ValueKey('capture'),
        child: DaySummaryScreen(
          onClose: () {},
          onStartBreak: () {},
          onDvrs: () {},
          onProgress: () {},
          onDashboard: () {},
          onSnoozeDvrsNudge: () async {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await _golden(tester, languageCode, 'resumo');
}

Future<void> _captureHub(
  WidgetTester tester,
  String languageCode, {
  required int tab,
  required String name,
}) async {
  final state = await _state(languageCode);
  await _setSurface(tester, const Size(700, 790));
  await tester.pumpWidget(
    _providerApp(
      state,
      RepaintBoundary(
        key: const ValueKey('capture'),
        child: HealthHubScreen(
          key: ValueKey('hub-$languageCode-$tab'),
          initialTab: tab,
          onClose: () {},
          onStartBreak: () {},
          onSnoozeDvrsNudge: () async {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final primaryTabs = tester.widget<TabBar>(find.byType(TabBar).first);
  expect(primaryTabs.controller?.index, tab);
  await _golden(tester, languageCode, name);
}

Future<void> _captureSettings(WidgetTester tester, String languageCode) async {
  await _setSurface(tester, const Size(460, 700));
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: Scaffold(
        backgroundColor: const Color(0xFF07121F),
        body: RepaintBoundary(
          key: const ValueKey('capture'),
          child: Center(
            child: SettingsDialog(
              initial: WidgetSettings.defaults().copyWith(
                languageCode: languageCode,
              ),
              onSave: (_) {},
              onClose: () {},
              onReset: () {},
              onResetLearning: () {},
              onOpenScreenTime: () {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await _golden(tester, languageCode, 'configuracoes');
}

Future<void> _captureOnboarding(
  WidgetTester tester,
  String languageCode,
) async {
  await _setSurface(tester, const Size(480, 560));
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: RepaintBoundary(
        key: const ValueKey('capture'),
        child: OnboardingFlow(
          strings: AppStrings.of(languageCode),
          onFinish: (_) async {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await _golden(tester, languageCode, 'onboarding');
}

Future<_CaptureState> _state(String languageCode) async {
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({});
  final storage = await StorageService.init();
  final dvrs = await DvrsStorageService.init();
  await storage.saveBreakStats(
    BreakStatsData({
      BreakStatsData.dayKey(DateTime.now()): const BreakDayStat(
        reminders: 5,
        completed: 3,
      ),
    }),
  );
  final settings = SettingsProvider(storage: storage);
  await settings.update(
    WidgetSettings.defaults().copyWith(
      languageCode: languageCode,
      onboardingComplete: true,
    ),
  );
  return _CaptureState(
    storage: storage,
    dvrs: dvrs,
    settings: settings,
    screenTime: ScreenTimeService(storage: storage),
  );
}

Widget _providerApp(_CaptureState state, Widget child) => MultiProvider(
  providers: [
    Provider<StorageService>.value(value: state.storage),
    Provider<DvrsStorageService>.value(value: state.dvrs),
    ChangeNotifierProvider<SettingsProvider>.value(value: state.settings),
    ChangeNotifierProvider<ScreenTimeService>.value(value: state.screenTime),
  ],
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    home: child,
  ),
);

Future<void> _setSurface(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  await tester.pump();
}

Future<void> _golden(
  WidgetTester tester,
  String languageCode,
  String name,
) async {
  await expectLater(
    find.byKey(const ValueKey('capture')),
    matchesGoldenFile('$_artifactRoot/$_stage/$languageCode-$name.png'),
  );
}

class _CaptureState {
  const _CaptureState({
    required this.storage,
    required this.dvrs,
    required this.settings,
    required this.screenTime,
  });

  final StorageService storage;
  final DvrsStorageService dvrs;
  final SettingsProvider settings;
  final ScreenTimeService screenTime;
}
