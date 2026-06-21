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
              onScreenTime: () {},
              onReports: () {},
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

  testWidgets('painel do menu cabe na janela e mostra o item "Sair"', (
    tester,
  ) async {
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
              onOsdi: () {},
              onScreenTime: () {},
              onReports: () {},
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

    // O último item precisa ser renderizado por inteiro.
    expect(find.text(ptStrings.menuQuit), findsOneWidget);

    // A altura intrínseca do painel (cabeçalho + 12 itens) deve caber na
    // altura reservada para o menu em main.dart (`_menuPanelHeight` = 552).
    // Se um novo item estourar esse limite, o último item ("Sair") voltaria a
    // ser cortado pela borda da janela — este teste é o guarda dessa regressão.
    final height = tester.getSize(find.byType(FloatingMenu)).height;
    expect(height, lessThanOrEqualTo(552));
  });
}
