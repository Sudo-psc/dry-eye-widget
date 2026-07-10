import 'package:dry_eye_widget/l10n/feature_strings.dart';
import 'package:dry_eye_widget/providers/settings_provider.dart';
import 'package:dry_eye_widget/services/dvrs_storage_service.dart';
import 'package:dry_eye_widget/services/screen_time_service.dart';
import 'package:dry_eye_widget/services/storage_service.dart';
import 'package:dry_eye_widget/ui/app_theme.dart';
import 'package:dry_eye_widget/widgets/health/health_hub_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('hub restaura aba inicial e informa mudanças de contexto', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    final dvrs = await DvrsStorageService.init();
    final settings = SettingsProvider(storage: storage);
    final screenTime = ScreenTimeService(storage: storage);
    final changedTabs = <int>[];
    final f = FeatureStrings.of('pt');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<StorageService>.value(value: storage),
          Provider<DvrsStorageService>.value(value: dvrs),
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
          ChangeNotifierProvider<ScreenTimeService>.value(value: screenTime),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: SizedBox(
            width: 700,
            height: 790,
            child: HealthHubScreen(
              initialTab: 1,
              onTabChanged: changedTabs.add,
              onClose: () {},
              onStartBreak: () {},
              onSnoozeDvrsNudge: () async {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final topTabs = tester.widget<TabBar>(find.byType(TabBar).first);
    expect(topTabs.controller?.index, 1);

    expect(find.text(f.healthHubTabDvrs), findsOneWidget);
    expect(find.text(f.healthHubTabReports), findsOneWidget);

    await tester.tap(find.text(f.healthHubTabReports).first);
    await tester.pumpAndSettle();

    expect(topTabs.controller?.index, 3);
    expect(changedTabs, contains(3));
    expect(find.text(settings.strings.menuReports), findsWidgets);
  });

  testWidgets(
    'hub permanece utilizável em janela estreita com escala de 160%',
    (tester) async {
      tester.view.physicalSize = const Size(620, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      final dvrs = await DvrsStorageService.init();
      final settings = SettingsProvider(storage: storage);
      final screenTime = ScreenTimeService(storage: storage);
      final f = FeatureStrings.of('pt');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<StorageService>.value(value: storage),
            Provider<DvrsStorageService>.value(value: dvrs),
            ChangeNotifierProvider<SettingsProvider>.value(value: settings),
            ChangeNotifierProvider<ScreenTimeService>.value(value: screenTime),
          ],
          child: MaterialApp(
            theme: buildAppTheme(),
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
              child: SizedBox(
                width: 560,
                height: 790,
                child: HealthHubScreen(
                  onClose: () {},
                  onStartBreak: () {},
                  onSnoozeDvrsNudge: () async {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      await tester.tap(find.text(f.healthHubTabProgress));
      await tester.pumpAndSettle();
      expect(find.text(f.healthHubEvolutionHabits), findsOneWidget);
      expect(find.text(f.healthHubEvolutionIndicators), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text(f.healthHubEvolutionIndicators));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
