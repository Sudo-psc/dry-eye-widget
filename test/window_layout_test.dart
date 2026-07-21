import 'package:dry_eye_widget/app/window_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tamanhos fixos do hub e meus dados usam painel amplo', () {
    expect(WindowSizes.fixedSizeFor(WindowLayout.healthHub), WindowSizes.panel);
    expect(WindowSizes.fixedSizeFor(WindowLayout.myData), WindowSizes.panel);
    expect(WindowSizes.fixedSizeFor(WindowLayout.ball), isNull);
  });

  test('menu e compacta escalam com o diâmetro da bolinha', () {
    final compact = WindowSizes.compact(32);
    expect(compact, const Size(60, 60));
    final menu = WindowSizes.menu(32);
    expect(menu.width, 300);
    expect(menu.height, greaterThan(350));
    expect(menu.height, lessThan(450));
  });

  test('menu pode ser ajustado sem alterar a âncora compacta', () {
    const original = Offset(1380, 120);
    const anchor = CompactWindowAnchor(original);
    const screen = Rect.fromLTWH(0, 0, 1512, 982);

    final transient = anchor.fitWindow(const Size(300, 414), screen);

    expect(transient, const Offset(1212, 120));
    expect(anchor.position, original);
  });

  test('menu compensado mantém a bolinha sobre a origem visual', () {
    const anchor = CompactWindowAnchor(Offset(1443, 80));
    const compactSize = Size(51, 51);
    const ballSize = 23.0;
    const menuSize = Size(300, 405);
    const screen = Rect.fromLTWH(0, 0, 1512, 982);

    final placement = placeMenuWindow(
      anchor: anchor,
      compactSize: compactSize,
      ballSize: ballSize,
      menuSize: menuSize,
      screen: screen,
    );

    const compactInset = Offset(14, 14);
    expect(
      placement.windowPosition + placement.ballOffset,
      anchor.position + compactInset,
    );
    expect(placement.ballOffset.dx, greaterThan(200));
    expect(placement.panelAbove, isFalse);
  });

  test('menu coloca o painel acima quando a origem está próxima da base', () {
    const anchor = CompactWindowAnchor(Offset(120, 920));
    const compactSize = Size(60, 60);
    const ballSize = 32.0;
    const menuSize = Size(300, 414);
    const screen = Rect.fromLTWH(0, 0, 1512, 982);

    final placement = placeMenuWindow(
      anchor: anchor,
      compactSize: compactSize,
      ballSize: ballSize,
      menuSize: menuSize,
      screen: screen,
    );

    expect(
      placement.windowPosition + placement.ballOffset,
      anchor.position + const Offset(14, 14),
    );
    expect(placement.panelAbove, isTrue);
  });

  test('janela maior que a tela é fixada na origem visível', () {
    const anchor = CompactWindowAnchor(Offset(400, 300));
    const screen = Rect.fromLTWH(80, 40, 200, 160);

    expect(anchor.fitWindow(const Size(300, 240), screen), screen.topLeft);
  });

  test('seleciona o monitor secundário que contém a janela', () {
    const primary = Rect.fromLTWH(0, 0, 1512, 982);
    const secondary = Rect.fromLTWH(-1920, -120, 1920, 1080);

    final selected = closestScreenForWindow(
      windowPosition: const Offset(-900, 240),
      windowSize: const Size(60, 60),
      screens: const [primary, secondary],
    );

    expect(selected, secondary);
  });

  test(
    'seleciona a tela mais próxima quando a janela está entre monitores',
    () {
      const left = Rect.fromLTWH(-1400, 0, 1200, 900);
      const right = Rect.fromLTWH(200, 0, 1200, 900);

      final selected = closestScreenForWindow(
        windowPosition: const Offset(100, 300),
        windowSize: const Size(40, 40),
        screens: const [left, right],
      );

      expect(selected, right);
    },
  );

  test('rejeita lista de monitores sem área utilizável', () {
    expect(
      () => closestScreenForWindow(
        windowPosition: Offset.zero,
        windowSize: const Size(40, 40),
        screens: const [Rect.zero],
      ),
      throwsArgumentError,
    );
  });
}
