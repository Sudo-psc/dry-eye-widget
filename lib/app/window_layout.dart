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

/// Constantes de tamanho das janelas do app.
class WindowSizes {
  WindowSizes._();

  static const Size settings = Size(460, 700);
  static const Size panel = Size(700, 790);
  static const Size onboarding = Size(480, 560);
  static const Size gentleBreak = Size(430, 164);
  static const Size inactivity = Size(320, 120);

  /// Altura do painel de menu (linha compacta de pausas + itens + cabeçalhos).
  static const double menuPanelHeight = 560;

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
