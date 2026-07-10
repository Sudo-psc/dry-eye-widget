import 'package:dry_eye_widget/l10n/app_strings.dart';
import 'package:dry_eye_widget/l10n/feature_strings.dart';
import 'package:dry_eye_widget/widgets/floating_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('painel principal prioriza pausas e hub de saúde', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    var hubOpened = 0;
    final f = FeatureStrings.of('pt');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: FloatingMenu(
              strings: ptStrings,
              healthHubLabel: f.menuHealthHub,
              myDataLabel: f.menuMyData,
              isPaused: false,
              onStartNow: () {},
              onReset: () {},
              onTogglePause: () {},
              onExtendCycle: () {},
              onGuidance: () {},
              onHealthHub: () => hubOpened++,
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
    );

    expect(find.text(f.menuHealthHub), findsOneWidget);
    expect(find.text(ptStrings.menuGuidance), findsOneWidget);
    expect(find.text(ptStrings.menuGroupSystem), findsOneWidget);
    expect(find.text(ptStrings.menuDvrs), findsNothing);
    expect(find.text(ptStrings.menuReports), findsNothing);
    expect(find.text(f.menuMyData), findsNothing);

    await tester.tap(find.text(f.menuHealthHub));
    await tester.pump();

    expect(hubOpened, 1);
  });

  testWidgets('ações de sistema aparecem em uma segunda página', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final f = FeatureStrings.of('pt');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: FloatingMenu(
              strings: ptStrings,
              healthHubLabel: f.menuHealthHub,
              myDataLabel: f.menuMyData,
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
    );

    expect(find.text(ptStrings.menuQuit), findsNothing);

    await tester.tap(find.text(ptStrings.menuGroupSystem));
    await tester.pumpAndSettle();

    expect(find.text(f.menuMyData), findsOneWidget);
    expect(find.text(ptStrings.menuCheckUpdates), findsOneWidget);
    expect(find.text(ptStrings.menuSettings), findsOneWidget);
    expect(find.text(ptStrings.menuAbout), findsOneWidget);
    expect(find.text(ptStrings.menuQuit), findsOneWidget);
    expect(find.text(f.menuHealthHub), findsNothing);

    await tester.tap(find.text(ptStrings.back));
    await tester.pumpAndSettle();

    expect(find.text(f.menuHealthHub), findsOneWidget);
    expect(find.text(ptStrings.menuQuit), findsNothing);
  });
}
