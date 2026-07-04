import 'package:dry_eye_widget/ui/breathing_circle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BreathingCircle monta e anima em loop sem lançar', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: BreathingCircle())),
    ));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
    // Desmonta sem vazar o controller.
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
