import 'package:flutter/material.dart';

import 'design_tokens.dart';

export 'design_tokens.dart';

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
  minimumSize: const WidgetStatePropertyAll(
    Size(64, AppComponentSize.minimumTarget),
  ),
  shape: WidgetStatePropertyAll(
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
  ),
  textStyle: const WidgetStatePropertyAll(
    TextStyle(fontSize: AppTypography.supporting, fontWeight: FontWeight.w600),
  ),
);

/// Tema central do app: dark Material 3, seed azul, Inter local.
///
/// [visualDensity] pode ser sobrescrito em runtime (preferência de densidade).
ThemeData buildAppTheme({
  VisualDensity visualDensity = VisualDensity.standard,
  bool highContrast = false,
}) {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColorTokens.accent,
        brightness: Brightness.dark,
      ).copyWith(
        primary: AppColorTokens.accent,
        onPrimary: AppColorTokens.onAccent,
        surface: highContrast
            ? AppColorTokens.canvas
            : AppColorTokens.surfaceRaised,
        onSurface: AppColorTokens.textPrimary,
        error: AppColorTokens.danger,
        onError: AppColorTokens.canvas,
        outline: highContrast ? AppColorTokens.focus : AppColorTokens.border,
        outlineVariant: AppColorTokens.borderSubtle,
      );
  const textTheme = TextTheme(
    bodySmall: TextStyle(
      fontSize: AppTypography.supporting,
      color: AppColorTokens.textSecondary,
    ),
    bodyMedium: TextStyle(
      fontSize: AppTypography.body,
      color: AppColorTokens.textPrimary,
    ),
    titleMedium: TextStyle(
      fontSize: AppTypography.title,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: AppColorTokens.textPrimary,
    ),
    headlineSmall: TextStyle(
      fontSize: AppTypography.headline,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.35,
      color: AppColorTokens.textPrimary,
    ),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    fontFamily: AppTypography.family,
    textTheme: textTheme,
    scaffoldBackgroundColor: AppColorTokens.transparent,
    visualDensity: visualDensity,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    filledButtonTheme: FilledButtonThemeData(style: _buttonStyle()),
    outlinedButtonTheme: OutlinedButtonThemeData(style: _buttonStyle()),
    textButtonTheme: TextButtonThemeData(style: _buttonStyle()),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 350),
      showDuration: const Duration(seconds: 3),
      decoration: BoxDecoration(
        color: AppColorTokens.surfaceOverlay,
        borderRadius: BorderRadius.circular(AppRadii.xs),
        border: Border.all(color: AppColorTokens.border),
      ),
      textStyle: const TextStyle(
        fontFamily: AppTypography.family,
        fontSize: AppTypography.supporting,
        fontWeight: FontWeight.w500,
        color: AppColorTokens.textPrimary,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.x3,
        vertical: AppSpace.x2,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColorTokens.accent,
      circularTrackColor: AppColorTokens.progressTrack,
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size.square(AppComponentSize.minimumTarget),
        foregroundColor: AppColorTokens.textPrimary,
      ),
    ),
    extensions: const [
      AppSemanticColors(
        success: AppColorTokens.success,
        caution: AppColorTokens.warning,
        risk: AppColorTokens.danger,
        danger: AppColorTokens.danger,
      ),
    ],
  );
}
