import 'package:flutter/material.dart';

/// Encaixe da bolinha nas bordas laterais da tela ("meia-lua" discreta).
///
/// Lógica PURA (sem I/O): decide se uma posição de janela deve encaixar em
/// uma borda e calcula a posição encaixada. Testável isoladamente.

/// Borda em que a bolinha está encaixada.
enum BallDockEdge { left, right }

/// Id estável para persistência.
extension BallDockEdgeId on BallDockEdge {
  String get id => this == BallDockEdge.left ? 'left' : 'right';
}

/// Parse reverso do [BallDockEdgeId.id]; `null` se desconhecido.
BallDockEdge? ballDockEdgeFromId(String? id) {
  switch (id) {
    case 'left':
      return BallDockEdge.left;
    case 'right':
      return BallDockEdge.right;
    default:
      return null;
  }
}

/// Distância máxima (px) da borda para o encaixe acontecer ao soltar o arrasto.
const double kDockThreshold = 56;

/// Fração da janela compacta que permanece visível quando encaixada.
const double kDockVisibleFraction = 0.62;

/// Decide a borda de encaixe para a janela em [windowPos] dentro de [screen],
/// ou `null` se estiver longe das bordas laterais.
BallDockEdge? dockEdgeFor({
  required Offset windowPos,
  required Size windowSize,
  required Rect screen,
  double threshold = kDockThreshold,
}) {
  final leftGap = windowPos.dx - screen.left;
  final rightGap = screen.right - (windowPos.dx + windowSize.width);
  if (leftGap <= threshold && leftGap <= rightGap) return BallDockEdge.left;
  if (rightGap <= threshold) return BallDockEdge.right;
  return null;
}

/// Posição da janela colada na [edge], preservando o Y (clampado à tela).
Offset dockedWindowPosition({
  required BallDockEdge edge,
  required Offset windowPos,
  required Size windowSize,
  required Rect screen,
  double visibleFraction = kDockVisibleFraction,
}) {
  final visible = visibleFraction.clamp(0.35, 1.0).toDouble();
  final x = edge == BallDockEdge.left
      ? screen.left - windowSize.width * (1 - visible)
      : screen.right - windowSize.width * visible;
  final y = windowPos.dy.clamp(screen.top, screen.bottom - windowSize.height);
  return Offset(x, y);
}
