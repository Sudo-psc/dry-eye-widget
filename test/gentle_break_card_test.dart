import 'package:dry_eye_widget/l10n/app_strings.dart';
import 'package:dry_eye_widget/models/app_state.dart';
import 'package:dry_eye_widget/widgets/blinking_eye.dart';
import 'package:dry_eye_widget/widgets/gentle_break_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('cartao suave mostra cronometro moderno sem olho piscando', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: SizedBox(
            width: 430,
            height: 164,
            child: GentleBreakCard(
              state: AppState.fase1,
              strings: ptStrings,
              secondsRemaining: 8,
              totalSeconds: 20,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(BlinkingEye), findsNothing);
    expect(find.text('20-20-20'), findsOneWidget);
    expect(find.text(ptStrings.phaseTitle), findsOneWidget);
    expect(find.text('00:08'), findsOneWidget);
  });
}
