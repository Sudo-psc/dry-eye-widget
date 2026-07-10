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
    expect(menu.height, greaterThan(500));
  });
}
