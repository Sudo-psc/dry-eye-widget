import 'package:dry_eye_widget/ui/score_gauge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ScoreGauge mostra o score final e /100', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(child: ScoreGauge(score: 54, color: Colors.deepOrange)),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('54'), findsOneWidget);
    expect(find.text('/100'), findsOneWidget);
  });

  testWidgets('ScoreGauge aceita segmentos de faixa', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ScoreGauge(
          score: 90,
          color: Colors.red,
          segments: [
            Colors.green,
            Colors.orange,
            Colors.deepOrange,
            Colors.red,
            Colors.red,
          ],
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('90'), findsOneWidget);
  });
}
