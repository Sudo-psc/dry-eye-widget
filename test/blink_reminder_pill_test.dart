import 'package:dry_eye_widget/widgets/floating_ball.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A pílula do lembrete de piscada é maior que a janela compacta da bolinha.
  // Enquanto a janela cresce, o widget chega a ser pintado dentro do espaço
  // antigo — e antes disso estourava o layout, listrando a tela.
  Widget pill({required double available}) => MaterialApp(
    home: Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SizedBox(
          width: available,
          height: available,
          child: const FloatingBall(
            isActive: false,
            size: 22,
            dynamicOrbEffect: false,
            showProgress: true,
            blinkReminderVisible: true,
            blinkReminderText: 'Pisque devagar',
          ),
        ),
      ),
    ),
  );

  testWidgets('pílula não estoura o layout na janela ainda compacta', (
    tester,
  ) async {
    await tester.pumpWidget(pill(available: 50));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('pílula continua inteira quando a janela já cresceu', (
    tester,
  ) async {
    await tester.pumpWidget(pill(available: 200));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Pisque devagar'), findsOneWidget);
  });
}
