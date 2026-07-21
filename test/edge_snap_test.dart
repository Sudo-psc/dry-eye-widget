import 'dart:math' as math;

import 'package:dry_eye_widget/app/window_layout.dart';
import 'package:dry_eye_widget/utils/edge_snap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _visibleHorizontalWidth({
  required BallDockEdge edge,
  required Offset position,
  required Size windowSize,
  required Rect screen,
}) {
  return edge == BallDockEdge.left
      ? position.dx + windowSize.width - screen.left
      : screen.right - position.dx;
}

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
      expect(pos.dx, closeTo(-4, 0.001));
      expect(pos.dy, 300);
    });

    test('encaixa parcialmente para fora da borda direita mantendo o y', () {
      final pos = dockedWindowPosition(
        edge: BallDockEdge.right,
        windowPos: const Offset(1300, 250),
        windowSize: win,
        screen: screen,
      );
      expect(pos.dx, closeTo(1396, 0.001));
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

    test('mínimo visível prevalece sobre fração menor', () {
      final pos = dockedWindowPosition(
        edge: BallDockEdge.left,
        windowPos: const Offset(10, 300),
        windowSize: win,
        screen: screen,
        visibleFraction: 0.5,
      );
      expect(pos.dx, -4);
    });

    test('fração maior que o mínimo é preservada', () {
      const largeWindow = Size(96, 96);
      final pos = dockedWindowPosition(
        edge: BallDockEdge.left,
        windowPos: const Offset(10, 300),
        windowSize: largeWindow,
        screen: screen,
        visibleFraction: 0.75,
      );
      expect(pos.dx, -24);
      expect(
        _visibleHorizontalWidth(
          edge: BallDockEdge.left,
          position: pos,
          windowSize: largeWindow,
          screen: screen,
        ),
        72,
      );
    });

    test('mínimo é configurável e limitado à largura da janela', () {
      final configured = dockedWindowPosition(
        edge: BallDockEdge.left,
        windowPos: const Offset(10, 300),
        windowSize: win,
        screen: screen,
        visibleFraction: 0.5,
        minimumVisibleWidth: 20,
      );
      expect(configured.dx, -24);

      const narrowWindow = Size(30, 30);
      for (final edge in BallDockEdge.values) {
        final pos = dockedWindowPosition(
          edge: edge,
          windowPos: const Offset(10, 300),
          windowSize: narrowWindow,
          screen: screen,
          minimumVisibleWidth: 100,
        );
        expect(
          _visibleHorizontalWidth(
            edge: edge,
            position: pos,
            windowSize: narrowWindow,
            screen: screen,
          ),
          narrowWindow.width,
        );
      }
    });

    test('matriz esquerda/direita cobre compactos das bolas 18, 32 e 96', () {
      for (final ballSize in const [18.0, 32.0, 96.0]) {
        final windowSize = WindowSizes.compact(ballSize);
        final expectedVisibleWidth = math
            .max(
              kDockMinimumVisibleWidth,
              windowSize.width * kDockVisibleFraction,
            )
            .clamp(0.0, windowSize.width)
            .toDouble();

        for (final edge in BallDockEdge.values) {
          final pos = dockedWindowPosition(
            edge: edge,
            windowPos: const Offset(400, 260),
            windowSize: windowSize,
            screen: screen,
          );
          expect(
            _visibleHorizontalWidth(
              edge: edge,
              position: pos,
              windowSize: windowSize,
              screen: screen,
            ),
            closeTo(expectedVisibleWidth, 0.001),
            reason: 'bola $ballSize, borda ${edge.id}',
          );
          expect(pos.dy, 260);
          expect(pos.dy, greaterThanOrEqualTo(screen.top));
          expect(pos.dy + windowSize.height, lessThanOrEqualTo(screen.bottom));
        }
      }
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

  // Cenários típicos de Windows (taskbar, DPI/monitor secundário).
  group('Windows-like display geometry', () {
    test(
      'taskbar inferior: área visível reduzida ainda encaixa na direita',
      () {
        // Work area 1920x1040 (taskbar ~40px) em (0,0).
        const work = Rect.fromLTWH(0, 0, 1920, 1040);
        const ball = Size(56, 56);
        final edge = dockEdgeFor(
          windowPos: const Offset(1920 - 56 - 12, 800),
          windowSize: ball,
          screen: work,
        );
        expect(edge, BallDockEdge.right);
        final pos = dockedWindowPosition(
          edge: BallDockEdge.right,
          windowPos: const Offset(1850, 800),
          windowSize: ball,
          screen: work,
        );
        expect(pos.dx, closeTo(1920 - kDockMinimumVisibleWidth, 0.01));
        expect(pos.dy, 800);
        // Não deve empurrar abaixo da work area.
        expect(pos.dy + ball.height, lessThanOrEqualTo(work.bottom));
      },
    );

    test('monitor com origem negativa preserva largura e Y visíveis', () {
      const work = Rect.fromLTWH(-1920, -120, 1920, 1080);
      final windowSize = WindowSizes.compact(18);

      for (final edge in BallDockEdge.values) {
        for (final requestedY in const [-500.0, 1500.0]) {
          final pos = dockedWindowPosition(
            edge: edge,
            windowPos: Offset(work.left + 8, requestedY),
            windowSize: windowSize,
            screen: work,
          );
          expect(
            _visibleHorizontalWidth(
              edge: edge,
              position: pos,
              windowSize: windowSize,
              screen: work,
            ),
            kDockMinimumVisibleWidth,
            reason: 'borda ${edge.id}, y solicitado $requestedY',
          );
          expect(pos.dy, greaterThanOrEqualTo(work.top));
          expect(pos.dy + windowSize.height, lessThanOrEqualTo(work.bottom));
        }
      }
    });

    test(
      'threshold com bola grande (scale Windows 150%) ainda detecta borda',
      () {
        // Bolinha 72px; threshold efetivo no main é max(56, width*0.72).
        const work = Rect.fromLTWH(0, 0, 2560, 1440);
        const ball = Size(72, 72);
        final threshold = math.max(kDockThreshold, ball.width * 0.72);
        expect(threshold, closeTo(56, 0.01)); // 72*0.72=51.84 < 56
        final edge = dockEdgeFor(
          windowPos: Offset(work.right - ball.width - 40, 200),
          windowSize: ball,
          screen: work,
          threshold: threshold,
        );
        expect(edge, BallDockEdge.right);
      },
    );

    test('bolinha 96px usa threshold ampliado (width*0.72)', () {
      const work = Rect.fromLTWH(0, 0, 1920, 1080);
      const ball = Size(96, 96);
      final threshold = math.max(kDockThreshold, ball.width * 0.72);
      expect(threshold, closeTo(69.12, 0.01));
      // 60px da borda: abaixo do threshold ampliado, acima do default 56.
      final edge = dockEdgeFor(
        windowPos: Offset(work.right - ball.width - 60, 300),
        windowSize: ball,
        screen: work,
        threshold: threshold,
      );
      expect(edge, BallDockEdge.right);
    });

    test('Y no limite inferior da taskbar é clampado ao encaixar', () {
      const work = Rect.fromLTWH(0, 0, 1920, 1040);
      const ball = Size(48, 48);
      final pos = dockedWindowPosition(
        edge: BallDockEdge.left,
        windowPos: const Offset(10, 2000),
        windowSize: ball,
        screen: work,
      );
      expect(pos.dy, work.bottom - ball.height);
    });
  });
}
