import 'dart:io';

import 'package:dry_eye_widget/l10n/app_strings.dart';
import 'package:dry_eye_widget/models/app_state.dart';
import 'package:dry_eye_widget/ui/app_theme.dart';
import 'package:dry_eye_widget/widgets/floating_ball.dart';
import 'package:dry_eye_widget/widgets/gentle_break_card.dart';
import 'package:dry_eye_widget/widgets/glass_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _artifactRoot =
    '../projects/dry-eye-widget-app/artifacts/calm-redesign-2026-07-25';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    debugPaintBaselinesEnabled = false;
    debugPaintSizeEnabled = false;
    await (FontLoader('Inter')
          ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Inter-SemiBold.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Inter-Bold.ttf')))
        .load();
    await (FontLoader('RobotoMono')
          ..addFont(rootBundle.load('assets/fonts/RobotoMono-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/RobotoMono-Bold.ttf')))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    Directory(_artifactRoot).createSync(recursive: true);
  });

  testWidgets('captura os estados calmos do ciclo', (tester) async {
    await _captureOverlay(tester, AppState.alerta, 20, 'alerta');
    await _captureOverlay(tester, AppState.fase1, 14, 'contando');
    await _captureOverlay(tester, AppState.conclusao, 0, 'concluida');
    await _captureGentle(tester);
    await _captureOrb(tester);
  });
}

Future<void> _captureOverlay(
  WidgetTester tester,
  AppState state,
  int seconds,
  String name,
) async {
  await _resetSurface(tester, const Size(520, 620));
  await tester.pumpWidget(
    _captureApp(
      GlassOverlay(
        state: state,
        strings: ptStrings,
        secondsRemaining: seconds,
        phaseTotalSeconds: 20,
        currentStreak: state == AppState.conclusao ? 3 : 0,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await _golden(tester, name);
}

Future<void> _captureGentle(WidgetTester tester) async {
  await _resetSurface(tester, const Size(460, 188));
  await tester.pumpWidget(
    _captureApp(
      const GentleBreakCard(
        state: AppState.fase1,
        strings: ptStrings,
        secondsRemaining: 14,
        totalSeconds: 20,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await _golden(tester, 'pausa-suave');
}

Future<void> _captureOrb(WidgetTester tester) async {
  await _resetSurface(tester, const Size(180, 180));
  await tester.pumpWidget(
    _captureApp(
      const Center(
        child: FloatingBall(
          isActive: false,
          size: 64,
          showProgress: true,
          progress: 0.7,
          dynamicOrbEffect: true,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await _golden(tester, 'orb-progresso');
}

Widget _captureApp(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: buildAppTheme(),
  home: RepaintBoundary(
    key: const ValueKey('capture'),
    child: ColoredBox(color: AppColorTokens.canvas, child: child),
  ),
);

Future<void> _resetSurface(WidgetTester tester, Size size) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  await tester.pump();
}

Future<void> _golden(WidgetTester tester, String name) async {
  await expectLater(
    find.byKey(const ValueKey('capture')),
    matchesGoldenFile('$_artifactRoot/$name.png'),
  );
}
