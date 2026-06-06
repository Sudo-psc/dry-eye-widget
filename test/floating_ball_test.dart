import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dry_eye_widget/widgets/floating_ball.dart';

void main() {
  testWidgets('botão direito (secondary tap) dispara onSecondaryTap',
      (tester) async {
    var secondaryTaps = 0;
    var leftTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: FloatingBall(
              isActive: false,
              onTap: () => leftTaps++,
              onSecondaryTap: () => secondaryTaps++,
            ),
          ),
        ),
      ),
    );

    // Clique com o botão direito do mouse.
    await tester.tap(find.byType(FloatingBall), buttons: kSecondaryButton);
    await tester.pump();
    expect(secondaryTaps, 1, reason: 'botão direito deve abrir o menu');
    expect(leftTaps, 0);

    // Clique com o botão esquerdo continua funcionando.
    await tester.tap(find.byType(FloatingBall));
    await tester.pump();
    expect(leftTaps, 1);
    expect(secondaryTaps, 1);
  });
}
