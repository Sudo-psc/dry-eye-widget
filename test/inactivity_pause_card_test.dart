import 'package:dry_eye_widget/l10n/app_strings.dart';
import 'package:dry_eye_widget/widgets/inactivity_pause_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Restringe à janela real do aviso (320x120): um overflow do botão/textos
  // lançaria excecao e falharia o teste.
  Widget host(VoidCallback onResume) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              height: 120,
              child:
                  InactivityPauseCard(strings: ptStrings, onResume: onResume),
            ),
          ),
        ),
      );

  testWidgets('renderiza titulo, corpo e botao de retomada', (tester) async {
    await tester.pumpWidget(host(() {}));

    expect(find.text(ptStrings.inactivityTitle), findsOneWidget);
    expect(find.text(ptStrings.inactivityBody), findsOneWidget);
    expect(find.text(ptStrings.inactivityContinue), findsOneWidget);
  });

  testWidgets('tocar em Retomar dispara onResume', (tester) async {
    var resumed = 0;
    await tester.pumpWidget(host(() => resumed++));

    await tester.tap(find.text(ptStrings.inactivityContinue));
    await tester.pump();

    expect(resumed, 1);
  });
}
