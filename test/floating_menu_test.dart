import 'package:dry_eye_widget/l10n/app_strings.dart';
import 'package:dry_eye_widget/l10n/feature_strings.dart';
import 'package:dry_eye_widget/widgets/floating_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('menu flutuante exibe hub de saúde e abre o questionário DVRS', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    var dvrsOpened = 0;
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
              onHealthHub: () {},
              onDvrs: () => dvrsOpened++,
              onReports: () {},
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
    expect(find.text(ptStrings.menuDvrs), findsOneWidget);
    expect(find.text(f.menuMyData), findsOneWidget);

    await tester.tap(find.text(ptStrings.menuDvrs));
    await tester.pump();

    expect(dvrsOpened, 1);
  });

  testWidgets('painel do menu cabe na janela e mostra o item "Sair"', (
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
              onDvrs: () {},
              onReports: () {},
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

    expect(find.text(ptStrings.menuQuit), findsOneWidget);
  });
}
