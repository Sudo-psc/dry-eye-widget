import 'package:dry_eye_widget/ui/glass_card.dart';
import 'package:dry_eye_widget/ui/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('GlassCard renderiza filho e responde a tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(children: [
          const GlassCard(child: Text('conteudo')),
          GlassCard(onTap: () => taps++, child: const Text('clicavel')),
          const SectionHeader('Título de seção'),
        ]),
      ),
    ));
    expect(find.text('conteudo'), findsOneWidget);
    expect(find.text('Título de seção'), findsOneWidget);
    await tester.tap(find.text('clicavel'));
    expect(taps, 1);
  });
}
