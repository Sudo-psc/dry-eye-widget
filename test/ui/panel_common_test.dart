import 'package:dry_eye_widget/models/app_state.dart';
import 'package:dry_eye_widget/ui/app_theme.dart';
import 'package:dry_eye_widget/widgets/common/empty_state.dart';
import 'package:dry_eye_widget/widgets/common/panel_entrance.dart';
import 'package:dry_eye_widget/widgets/common/panel_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PanelHeader mostra título e reage ao leading', (tester) async {
    var closed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: PanelHeader(
            title: 'Resumo do dia',
            onLeading: () => closed = true,
            leadingTooltip: 'Fechar',
            trailingIcon: Icons.wb_sunny_outlined,
          ),
        ),
      ),
    );

    expect(find.text('Resumo do dia'), findsOneWidget);
    expect(find.byIcon(Icons.wb_sunny_outlined), findsOneWidget);
    await tester.tap(find.byTooltip('Fechar'));
    expect(closed, isTrue);
  });

  testWidgets('EmptyState renderiza título, mensagem e ação', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: EmptyState(
            icon: Icons.insights_outlined,
            title: 'Sem dados ainda',
            message: 'Conclua sua primeira pausa.',
            actionLabel: 'Iniciar',
            onAction: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Sem dados ainda'), findsOneWidget);
    expect(find.text('Conclua sua primeira pausa.'), findsOneWidget);
    await tester.tap(find.text('Iniciar'));
    expect(tapped, isTrue);
  });

  testWidgets('PanelEntrance exibe o filho após a animação', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(
          body: PanelEntrance(
            child: Text('painel'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('painel'), findsOneWidget);
  });

  test('UiDensity mapeia VisualDensity e spacingScale', () {
    expect(UiDensity.comfortable.visualDensity, VisualDensity.standard);
    expect(UiDensity.compact.visualDensity, VisualDensity.compact);
    expect(UiDensity.comfortable.spacingScale, 1.0);
    expect(UiDensity.compact.spacingScale, 0.85);
    expect(uiDensityFromId(null), UiDensity.comfortable);
    expect(uiDensityFromId('compact'), UiDensity.compact);
  });

  test('buildAppTheme aceita visualDensity custom', () {
    final theme = buildAppTheme(visualDensity: VisualDensity.compact);
    expect(theme.visualDensity, VisualDensity.compact);
  });
}
