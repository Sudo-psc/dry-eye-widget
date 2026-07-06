import 'package:dry_eye_widget/utils/edge_snap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Tela 1440x900 começando em (0,0); janela da bolinha 48x48.
  const screen = Rect.fromLTWH(0, 0, 1440, 900);
  const win = Size(48, 48);

  group('dockEdgeFor', () {
    test('perto da borda esquerda => left', () {
      expect(
        dockEdgeFor(
          windowPos: const Offset(10, 300),
          windowSize: win,
          screen: screen,
        ),
        BallDockEdge.left,
      );
    });

    test('encostado na borda direita => right', () {
      expect(
        dockEdgeFor(
          windowPos: const Offset(1440 - 48 - 8, 500),
          windowSize: win,
          screen: screen,
        ),
        BallDockEdge.right,
      );
    });

    test('longe das bordas => null', () {
      expect(
        dockEdgeFor(
          windowPos: const Offset(600, 300),
          windowSize: win,
          screen: screen,
        ),
        isNull,
      );
    });

    test('threshold custom respeitado', () {
      expect(
        dockEdgeFor(
          windowPos: const Offset(40, 300),
          windowSize: win,
          screen: screen,
          threshold: 60,
        ),
        BallDockEdge.left,
      );
    });
  });

  group('dockedWindowPosition', () {
    test('encaixa parcialmente para fora da borda esquerda mantendo o y', () {
      final pos = dockedWindowPosition(
        edge: BallDockEdge.left,
        windowPos: const Offset(10, 300),
        windowSize: win,
        screen: screen,
      );
      expect(pos.dx, closeTo(-18.24, 0.001));
      expect(pos.dy, 300);
    });

    test('encaixa parcialmente para fora da borda direita mantendo o y', () {
      final pos = dockedWindowPosition(
        edge: BallDockEdge.right,
        windowPos: const Offset(1300, 250),
        windowSize: win,
        screen: screen,
      );
      expect(pos.dx, closeTo(1410.24, 0.001));
      expect(pos.dy, 250);
    });

    test('clampa o y dentro da tela', () {
      final pos = dockedWindowPosition(
        edge: BallDockEdge.left,
        windowPos: const Offset(10, -50),
        windowSize: win,
        screen: screen,
      );
      expect(pos.dy, 0);
    });

    test('respeita fracao visivel customizada', () {
      final pos = dockedWindowPosition(
        edge: BallDockEdge.left,
        windowPos: const Offset(10, 300),
        windowSize: win,
        screen: screen,
        visibleFraction: 0.5,
      );
      expect(pos.dx, -24);
    });
  });

  group('BallDockEdge ids', () {
    test('round-trip id/fromId', () {
      for (final e in BallDockEdge.values) {
        expect(ballDockEdgeFromId(e.id), e);
      }
      expect(ballDockEdgeFromId('nope'), isNull);
      expect(ballDockEdgeFromId(null), isNull);
    });
  });
}
