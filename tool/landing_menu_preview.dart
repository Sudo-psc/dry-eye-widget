import 'package:dry_eye_widget/l10n/app_strings.dart';
import 'package:dry_eye_widget/l10n/feature_strings.dart';
import 'package:dry_eye_widget/ui/app_theme.dart';
import 'package:dry_eye_widget/widgets/floating_ball.dart';
import 'package:dry_eye_widget/widgets/floating_menu.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  const options = WindowOptions(
    size: Size(420, 620),
    minimumSize: Size(420, 620),
    maximumSize: Size(420, 620),
    center: false,
    backgroundColor: Color(0xFF07121F),
    title: 'Dry Eye Widget — Landing Preview',
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: false,
  );

  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.setResizable(false);
    await windowManager.setPosition(const Offset(80, 80));
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const _LandingMenuPreview());
}

class _LandingMenuPreview extends StatelessWidget {
  const _LandingMenuPreview();

  @override
  Widget build(BuildContext context) {
    final feature = FeatureStrings.of('pt');
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.45, -0.65),
              radius: 1.1,
              colors: [Color(0xFF153B67), Color(0xFF07121F)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FloatingBall(
                  isActive: false,
                  size: 66,
                  showProgress: true,
                  progress: 0.68,
                  dynamicOrbEffect: true,
                  hoverReactiveBall: false,
                  orbIntensity: 0.9,
                ),
                const SizedBox(height: 22),
                FloatingMenu(
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
