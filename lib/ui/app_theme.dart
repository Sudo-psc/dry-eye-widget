import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Raios de borda padronizados do design system.
class AppRadii {
  AppRadii._();
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double pill = 999;
}

/// Durações e curvas de micro-interação (hover, fade de painéis).
class AppMotion {
  AppMotion._();
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 320);
  static const Curve standard = Curves.easeOutCubic;
  static const double hoverScale = 1.06;
}

/// Cores semânticas (alinhadas às faixas de risco do DVRS).
/// A cor NUNCA é o único indicador — sempre acompanhada de texto/ícone.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.caution,
    required this.risk,
    required this.danger,
  });

  final Color success;
  final Color caution;
  final Color risk;
  final Color danger;

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? caution,
    Color? risk,
    Color? danger,
  }) => AppSemanticColors(
        success: success ?? this.success,
        caution: caution ?? this.caution,
        risk: risk ?? this.risk,
        danger: danger ?? this.danger,
      );

  @override
  AppSemanticColors lerp(AppSemanticColors? other, double t) {
    if (other == null) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      caution: Color.lerp(caution, other.caution, t)!,
      risk: Color.lerp(risk, other.risk, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

ButtonStyle _buttonStyle() => ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(64, 44)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
      ),
    );

/// Tema central do app: dark Material 3, seed azul, Inter local.
///
/// [visualDensity] pode ser sobrescrito em runtime (preferência de densidade).
ThemeData buildAppTheme({
  VisualDensity visualDensity = VisualDensity.standard,
}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.idleBall,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors.idleBall,
    onPrimary: Colors.white,
    surface: const Color(0xFF1A1F2A),
    onSurface: Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: Colors.transparent,
    visualDensity: visualDensity,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    filledButtonTheme: FilledButtonThemeData(style: _buttonStyle()),
    outlinedButtonTheme: OutlinedButtonThemeData(style: _buttonStyle()),
    textButtonTheme: TextButtonThemeData(style: _buttonStyle()),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 350),
      showDuration: const Duration(seconds: 3),
      decoration: BoxDecoration(
        color: const Color(0xE61A1F2A),
        borderRadius: BorderRadius.circular(AppRadii.xs),
        border: Border.all(color: Colors.white24),
      ),
      textStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.idleBall,
      circularTrackColor: Color(0x33FFFFFF),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(44, 44),
        foregroundColor: Colors.white.withValues(alpha: 0.92),
      ),
    ),
    extensions: const [
      AppSemanticColors(
        success: Color(0xFF50C878),
        caution: Color(0xFFFF8C00),
        risk: Color(0xFFFF6B35),
        danger: Color(0xFFFF4444),
      ),
    ],
  );
}
