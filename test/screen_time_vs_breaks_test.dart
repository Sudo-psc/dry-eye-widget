import 'package:dry_eye_widget/models/break_stats_data.dart';
import 'package:dry_eye_widget/models/screen_time_data.dart';
import 'package:dry_eye_widget/models/widget_settings.dart';
import 'package:dry_eye_widget/providers/settings_provider.dart';
import 'package:dry_eye_widget/services/dvrs_storage_service.dart';
import 'package:dry_eye_widget/services/screen_time_service.dart';
import 'package:dry_eye_widget/services/storage_service.dart';
import 'package:dry_eye_widget/ui/app_theme.dart';
import 'package:dry_eye_widget/widgets/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('DashboardScreen renderiza grafico comparativo na aba de Tempo de Tela', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    final dvrs = await DvrsStorageService.init();
    final screenTime = ScreenTimeService(storage: storage);

    final todayKey = BreakStatsData.dayKey(DateTime.now());
    await storage.saveBreakStats(
      BreakStatsData({
        todayKey: const BreakDayStat(reminders: 10, completed: 8),
      }),
    );
    await storage.saveScreenTime(
      ScreenTimeData({
        todayKey: 7200,
      }),
    );
    for (var i = 0; i < 60; i++) {
      screenTime.tick();
    }
    await screenTime.flush();

    final settings = SettingsProvider(storage: storage);
    await settings.update(
      WidgetSettings.defaults().copyWith(
        onboardingComplete: true,
        screenTimeTracking: true,
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<StorageService>.value(value: storage),
          Provider<DvrsStorageService>.value(value: dvrs),
          ChangeNotifierProvider<ScreenTimeService>.value(value: screenTime),
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 1000,
              child: DashboardScreen(
                onClose: () {},
                initialTab: 1, // Tempo de tela
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Tempo de Tela vs. Adesão a Pausas (20-20-20)'), findsOneWidget);
    expect(find.text('Adesão 20-20-20 (%)'), findsOneWidget);
  });
}
