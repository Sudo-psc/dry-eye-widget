import 'package:dry_eye_widget/l10n/app_strings.dart';
import 'package:dry_eye_widget/widgets/floating_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('menu flutuante exibe e abre o questionário OSDI', (
    tester,
  ) async {
    var osdiOpened = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: FloatingMenu(
              strings: ptStrings,
              isPaused: false,
              onStartNow: () {},
              onReset: () {},
              onTogglePause: () {},
              onGuidance: () {},
              onOsdi: () => osdiOpened++,
              onCheckUpdates: () {},
              onGitHub: () {},
              onAbout: () {},
              onSettings: () {},
              onQuit: () {},
              onDismiss: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text(ptStrings.menuOsdi), findsOneWidget);

    await tester.tap(find.text(ptStrings.menuOsdi));
    await tester.pump();

    expect(osdiOpened, 1);
  });
}
