import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Raios de borda padronizados do design system.
class AppRadii {
  AppRadii._();
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
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
ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.idleBall,
    brightness: Brightness.dark,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: Colors.transparent,
    filledButtonTheme: FilledButtonThemeData(style: _buttonStyle()),
    outlinedButtonTheme: OutlinedButtonThemeData(style: _buttonStyle()),
    textButtonTheme: TextButtonThemeData(style: _buttonStyle()),
    extensions: const [
      AppSemanticColors(
        success: Colors.green,
        caution: Colors.orange,
        risk: Colors.deepOrange,
        danger: Colors.red,
      ),
    ],
  );
}
