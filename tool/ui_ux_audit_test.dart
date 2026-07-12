import 'package:dry_eye_widget/l10n/app_strings.dart';
import 'package:dry_eye_widget/l10n/feature_strings.dart';
import 'package:dry_eye_widget/models/break_stats_data.dart';
import 'package:dry_eye_widget/models/widget_settings.dart';
import 'package:dry_eye_widget/providers/settings_provider.dart';
import 'package:dry_eye_widget/services/dvrs_storage_service.dart';
import 'package:dry_eye_widget/services/storage_service.dart';
import 'package:dry_eye_widget/ui/app_theme.dart';
import 'package:dry_eye_widget/widgets/floating_menu.dart';
import 'package:dry_eye_widget/widgets/summary/day_summary_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _artifactRoot =
    '../projects/dry-eye-widget-app/artifacts/ui-ux-audit-2026-07-12';

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
  });

  testWidgets('captura menu principal e sistema', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 520));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_menuApp());
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const ValueKey('audit-menu')),
      matchesGoldenFile('$_artifactRoot/after/01-menu-principal.png'),
    );

    await tester.tap(find.text(ptStrings.menuGroupSystem));
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const ValueKey('audit-menu')),
      matchesGoldenFile('$_artifactRoot/after/02-menu-sistema.png'),
    );
  });

  testWidgets('captura resumo diário em largura compacta', (tester) async {
    await tester.binding.setSurfaceSize(const Size(520, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

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
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          home: RepaintBoundary(
            key: const ValueKey('audit-summary'),
            child: SizedBox(
              width: 520,
              height: 720,
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
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const ValueKey('audit-summary')),
      matchesGoldenFile('$_artifactRoot/after/03-resumo-diario.png'),
    );
  });
}

Widget _menuApp() {
  final feature = FeatureStrings.of('pt');
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    home: RepaintBoundary(
      key: const ValueKey('audit-menu'),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFF07121F)),
        child: Center(
          child: DefaultTextStyle.merge(
            style: const TextStyle(fontFamily: 'Inter'),
            child: FloatingMenu(
              strings: ptStrings,
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
}
