import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Layouts possíveis da janela principal do widget.
///
/// Extraído de `main.dart` para reduzir o shell monolítico e permitir testes
/// de tamanhos sem subir o HomePage completo.
enum WindowLayout {
  ball,
  blinkReminder,
  menu,
  settings,
  dvrs,
  report,
  dashboard,
  progress,
  daySummary,
  healthHub,
  myData,
  onboarding,
  breakOverlay,
  gentleBreak,
  inactivity,
}

/// Âncora imutável da janela compacta durante layouts transitórios.
///
/// Menu e lembrete precisam caber na tela e, por isso, podem usar uma posição
/// temporária diferente. A coordenada compacta permanece preservada para que
/// o widget volte exatamente ao ponto anterior ao fechar o painel.
@immutable
class CompactWindowAnchor {
  const CompactWindowAnchor(this.position);

  final Offset position;

  Offset fitWindow(Size windowSize, Rect screen) {
    final maxX = math.max(screen.left, screen.right - windowSize.width);
    final maxY = math.max(screen.top, screen.bottom - windowSize.height);
    return Offset(
      position.dx.clamp(screen.left, maxX).toDouble(),
      position.dy.clamp(screen.top, maxY).toDouble(),
    );
  }
}

/// Geometria da janela expandida que mantém a bolinha sobre sua origem visual.
///
/// A janela do menu pode precisar se deslocar para caber na tela. Nesse caso,
/// a bolinha muda de posição *dentro* da janela expandida, compensando o
/// deslocamento nativo em vez de saltar para o canto superior esquerdo.
@immutable
class MenuWindowPlacement {
  const MenuWindowPlacement({
    required this.windowPosition,
    required this.ballOffset,
    required this.panelAbove,
  });

  final Offset windowPosition;
  final Offset ballOffset;
  final bool panelAbove;
}

MenuWindowPlacement placeMenuWindow({
  required CompactWindowAnchor anchor,
  required Size compactSize,
  required double ballSize,
  required Size menuSize,
  required Rect screen,
  double padding = 8,
  double gap = 8,
}) {
  final windowPosition = anchor.fitWindow(menuSize, screen);
  final compactInset = Offset(
    (compactSize.width - ballSize) / 2,
    (compactSize.height - ballSize) / 2,
  );
  final originalBallPosition = anchor.position + compactInset;
  final rawOffset = originalBallPosition - windowPosition;
  final maxX = math.max(padding, menuSize.width - ballSize - padding);
  final maxY = math.max(padding, menuSize.height - ballSize - padding);
  final ballOffset = Offset(
    rawOffset.dx.clamp(padding, maxX).toDouble(),
    rawOffset.dy.clamp(padding, maxY).toDouble(),
  );

  final roomBelow =
      menuSize.height - (ballOffset.dy + ballSize + gap) - padding;
  final roomAbove = ballOffset.dy - gap - padding;
  final panelAbove =
      roomBelow < WindowSizes.menuPanelHeight &&
      roomAbove >= WindowSizes.menuPanelHeight;

  return MenuWindowPlacement(
    windowPosition: windowPosition,
    ballOffset: ballOffset,
    panelAbove: panelAbove,
  );
}

/// Seleciona a tela que contém o centro da janela ou, quando ela está em um
/// espaço entre monitores, a tela geometricamente mais próxima.
///
/// Usar sempre a tela primária faz widgets em monitores secundários saltarem
/// ao abrir menus, encaixar na borda ou terminar um arraste.
Rect closestScreenForWindow({
  required Offset windowPosition,
  required Size windowSize,
  required Iterable<Rect> screens,
}) {
  final validScreens = screens
      .where((screen) => screen.width > 0 && screen.height > 0)
      .toList(growable: false);
  if (validScreens.isEmpty) {
    throw ArgumentError.value(screens, 'screens', 'nenhuma tela válida');
  }

  final center =
      windowPosition + Offset(windowSize.width / 2, windowSize.height / 2);
  for (final screen in validScreens) {
    if (screen.contains(center)) return screen;
  }

  Rect best = validScreens.first;
  var bestDistance = double.infinity;
  for (final screen in validScreens) {
    final nearestX = center.dx.clamp(screen.left, screen.right).toDouble();
    final nearestY = center.dy.clamp(screen.top, screen.bottom).toDouble();
    final delta = center - Offset(nearestX, nearestY);
    final distance = delta.distanceSquared;
    if (distance < bestDistance) {
      bestDistance = distance;
      best = screen;
    }
  }
  return best;
}

/// Constantes de tamanho das janelas do app.
class WindowSizes {
  WindowSizes._();

  static const Size settings = Size(460, 700);
  static const Size panel = Size(700, 790);
  static const Size onboarding = Size(480, 560);
  static const Size gentleBreak = Size(430, 164);
  static const Size inactivity = Size(320, 120);

  /// Altura das páginas do painel rápido.
  ///
  /// A divulgação progressiva mantém ações diárias e Sistema em páginas de
  /// altura semelhante, evitando a antiga lista linear alta.
  static const double menuPanelHeight = 350;

  static Size compact(double ballSize) => Size(ballSize + 28, ballSize + 28);

  static Size menu(double ballSize) =>
      Size(300, ballSize + 24 + menuPanelHeight + 8);

  static Size blinkReminder(double ballSize) => Size(
    math.max(ballSize + 156, 176.0).toDouble(),
    math.max(ballSize + 24, 52.0).toDouble(),
  );

  /// Tamanho alvo para um [WindowLayout] (exceto ball/menu que dependem da bolinha).
  static Size? fixedSizeFor(WindowLayout layout) {
    switch (layout) {
      case WindowLayout.settings:
        return settings;
      case WindowLayout.onboarding:
        return onboarding;
      case WindowLayout.gentleBreak:
        return gentleBreak;
      case WindowLayout.inactivity:
        return inactivity;
      case WindowLayout.dvrs:
      case WindowLayout.report:
      case WindowLayout.dashboard:
      case WindowLayout.progress:
      case WindowLayout.daySummary:
      case WindowLayout.healthHub:
      case WindowLayout.myData:
        return panel;
      case WindowLayout.ball:
      case WindowLayout.blinkReminder:
      case WindowLayout.menu:
      case WindowLayout.breakOverlay:
        return null;
    }
  }
}
