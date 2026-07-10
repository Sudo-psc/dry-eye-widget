import 'package:dry_eye_widget/l10n/app_strings.dart';
import 'package:dry_eye_widget/models/app_state.dart';
import 'package:dry_eye_widget/widgets/glass_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('conclusão exibe insight proativo quando informado', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    const insight = 'Hoje você concluiu 3 de 4 pausas sugeridas. Cada ciclo conta.';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GlassOverlay(
            state: AppState.conclusao,
            strings: ptStrings,
            secondsRemaining: 0,
            phaseTotalSeconds: 20,
            currentStreak: 3,
            completionInsight: insight,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(ptStrings.doneTitle), findsOneWidget);
    expect(find.textContaining('3 dias'), findsOneWidget);
    expect(find.text(insight), findsOneWidget);
  });
}
