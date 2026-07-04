import 'package:dry_eye_widget/ui/progress_ring.dart';
import 'package:dry_eye_widget/ui/stat_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('StatTile mostra valor, rótulo e anel', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: StatTile(
          label: 'Adesão às pausas',
          value: '80%',
          ringValue: 0.8,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('80%'), findsOneWidget);
    expect(find.text('Adesão às pausas'), findsOneWidget);
    expect(find.byType(ProgressRing), findsOneWidget);
  });

  testWidgets('StatTile com ícone e footer', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: StatTile(
          label: 'Tela hoje',
          value: '2h 15min',
          icon: Icons.timer_outlined,
          footer: Text('rodapé'),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    expect(find.text('rodapé'), findsOneWidget);
  });
}
