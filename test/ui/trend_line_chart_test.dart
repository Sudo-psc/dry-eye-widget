import 'package:dry_eye_widget/ui/trend_line_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renderiza com 0, 1 e N pontos sem lançar', (tester) async {
    for (final points in [
      const <(DateTime, double)>[],
      [(DateTime(2026, 7, 1), 42.0)],
      [
        (DateTime(2026, 6, 1), 20.0),
        (DateTime(2026, 6, 8), 55.0),
        (DateTime(2026, 6, 15), 40.0),
      ],
    ]) {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TrendLineChart(points: points, minY: 0, maxY: 100),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('modo sparkline (sem grid/labels) renderiza', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TrendLineChart(
          points: [
            (DateTime(2026, 7, 1), 3600.0),
            (DateTime(2026, 7, 2), 7200.0),
          ],
          showGrid: false,
          dateLabels: false,
          height: 56,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
