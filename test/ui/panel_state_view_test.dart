import 'package:dry_eye_widget/ui/app_theme.dart';
import 'package:dry_eye_widget/ui/panel_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('estado expõe título, mensagem, ação e semântica', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var actions = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: PanelStateView(
            icon: Icons.info_outline,
            title: 'Sem dados',
            message: 'Os dados aparecerão aqui.',
            actionLabel: 'Continuar',
            onAction: () => actions++,
          ),
        ),
      ),
    );

    expect(find.text('Sem dados'), findsOneWidget);
    expect(find.text('Os dados aparecerão aqui.'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Sem dados.*dados aparecerão aqui')),
      findsOneWidget,
    );

    await tester.tap(find.text('Continuar'));
    expect(actions, 1);
    semantics.dispose();
  });

  testWidgets('sucesso e erro compactos anunciam mudanças', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Column(
          children: [
            PanelStateView(
              compact: true,
              tone: PanelStateTone.success,
              icon: Icons.check_circle_outline,
              title: 'Concluído',
              message: 'Relatório salvo.',
            ),
            PanelStateView(
              compact: true,
              tone: PanelStateTone.error,
              icon: Icons.error_outline,
              title: 'Não foi possível concluir',
              message: 'Tente novamente.',
            ),
          ],
        ),
      ),
    );

    expect(find.text('Concluído'), findsOneWidget);
    expect(find.text('Não foi possível concluir'), findsOneWidget);
  });
}
