import 'package:dry_eye_widget/l10n/app_strings.dart';
import 'package:dry_eye_widget/widgets/floating_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('menu flutuante exibe e abre o questionário DVRS', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    var dvrsOpened = 0;

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
              onDaySummary: () {},
              onDvrs: () => dvrsOpened++,
              onScreenTime: () {},
              onDashboard: () {},
              onProgress: () {},
              onReports: () {},
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

    expect(find.text(ptStrings.menuDaySummary), findsOneWidget);
    expect(find.text(ptStrings.menuDvrs), findsOneWidget);

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

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: FloatingMenu(
              strings: ptStrings,
              isPaused: false,
              onStartNow: () {},
              onReset: () {},
              onTogglePause: () {},
              onGuidance: () {},
              onDaySummary: () {},
              onDvrs: () {},
              onScreenTime: () {},
              onDashboard: () {},
              onProgress: () {},
              onReports: () {},
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

    // O último item precisa ser renderizado por inteiro.
    expect(find.text(ptStrings.menuQuit), findsOneWidget);

    // A altura intrínseca do painel (3 cabeçalhos de grupo + linha compacta de
    // pausas + 12 itens + 2 divisórias) deve caber na altura reservada para o
    // menu em main.dart (`_menuPanelHeight` = 704). Se um novo item estourar
    // esse limite, o último item ("Sair") voltaria a ser cortado pela borda da
    // janela — este teste é o guarda dessa regressão.
    final height = tester.getSize(find.byType(FloatingMenu)).height;
    expect(height, lessThanOrEqualTo(704));
  });
}
