import 'package:flutter/material.dart';

/// Tokens cromáticos do tema calmo.
///
/// Flutter recebe sRGB, por isso cada constante registra a origem em OKLCH.
/// A luminância baixa reduz competição visual; o azul é o único acento de
/// ação. Verde, âmbar e coral ficam restritos a estados semânticos.
class AppColorTokens {
  AppColorTokens._();

  /// oklch(17.3% 0.026 248.8)
  static const canvas = Color(0xFF07111B);

  /// oklch(20.9% 0.032 249.6)
  static const surface = Color(0xFF0C1926);

  /// oklch(25.0% 0.038 248.2)
  static const surfaceRaised = Color(0xFF122333);

  /// oklch(27.7% 0.042 247.1)
  static const surfaceOverlay = Color(0xFF162A3C);

  /// oklch(97.4% 0.006 239.8), contraste 17.64:1 sobre canvas.
  static const textPrimary = Color(0xFFF3F7FA);

  /// oklch(87.6% 0.021 243.4), contraste 13.10:1 sobre canvas.
  static const textSecondary = Color(0xFFCBD8E3);

  /// oklch(74.7% 0.033 243.8), contraste 8.50:1 sobre canvas.
  static const textMuted = Color(0xFF9CB0C1);

  /// oklch(76.6% 0.123 252.7), único acento funcional.
  static const accent = Color(0xFF78B7FF);
  static const onAccent = canvas;

  /// Estados semânticos, nunca usados como acentos decorativos.
  static const success = Color(0xFF84C7A1); // oklch(77.4% 0.088 158.7)
  static const warning = Color(0xFFD9B36C); // oklch(78.5% 0.100 82.1)
  static const danger = Color(0xFFDF8E8B); // oklch(72.9% 0.099 22.1)

  /// oklch(90.2% 0.050 249.3)
  static const focus = Color(0xFFC6E2FF);

  /// oklch(42.0% 0.054 246.4)
  static const border = Color(0xFF345069);
  static const borderSubtle = Color(0x66345069);
  static const progressTrack = Color(0x40345069);
  static const scrim = Color(0x9907111B);
  static const transparent = Color(0x00000000);
}

/// Escala espacial 4/8 pt. Componentes usam apenas estes incrementos.
class AppSpace {
  AppSpace._();

  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x8 = 32;
  static const double x10 = 40;
}

/// Raios refletem função: controles, cartões, painéis e cápsulas.
class AppRadii {
  AppRadii._();

  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double pill = 999;
}

/// Escala tipográfica modular 1.25, com base de 12 px.
class AppTypography {
  AppTypography._();

  static const String family = 'Inter';
  static const String timerFamily = 'RobotoMono';
  static const double minimumReadable = 12;
  static const double supporting = 12;
  static const double body = 15;
  static const double title = 18.75;
  static const double headline = 23.44;
  static const double display = 29.30;
  static const double timer = 36.62;

  static const TextStyle timerStyle = TextStyle(
    fontFamily: timerFamily,
    fontSize: timer,
    fontWeight: FontWeight.w700,
    color: AppColorTokens.textPrimary,
    letterSpacing: -0.6,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

/// Motion curto e funcional; reduzir movimento zera todas as transições.
class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 220);
  static const Duration normal = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 400);
  static const Curve standard = Cubic(0.2, 0.8, 0.2, 1);
  static const double hoverScale = 1.03;

  static Duration resolve(BuildContext context, Duration duration) =>
      MediaQuery.maybeOf(context)?.disableAnimations == true
      ? Duration.zero
      : duration;
}

/// Profundidade é reservada a janelas realmente flutuantes.
class AppDepth {
  AppDepth._();

  static const double blur = 18;
  static const double darkOpacity = 0.92;
  static const double lightOpacity = 0.88;
  static const double minimumReadableOpacity = 0.88;
  static const List<BoxShadow> floating = [
    BoxShadow(
      color: Color(0x66000000),
      blurRadius: 28,
      spreadRadius: -8,
      offset: Offset(0, 12),
    ),
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 4,
      spreadRadius: -1,
      offset: Offset(0, 2),
    ),
  ];
}

class AppComponentSize {
  AppComponentSize._();

  static const double minimumTarget = 44;
  static const double floatingMenuWidth = 280;
  static const double gentleBreakWidth = 404;
  static const double countdownDial = 96;
  static const double countdownInnerWidth = 76;
  static const double countdownInnerHeight = 58;
  static const double stateBadge = 72;
  static const double progressStroke = 5;
  static const double compactActionHeight = 60;
  static const double icon = 20;
  static const double iconLarge = 28;
  static const double panelBadge = 36;
  static const double overlayMinWidth = 240;
  static const double overlayMaxWidth = 400;
  static const double overlayProgress = 118;
}
