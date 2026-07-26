import 'dart:ui';

import 'package:flutter/material.dart';

import '../ui/design_tokens.dart';

/// Painel com efeito "liquid glass": desfoque + saturação do fundo,
/// preenchimento em gradiente translúcido, brilho superior (reflexo),
/// realce de borda e sombra de profundidade.
///
/// Usado de forma consistente em todo o app (menu, configurações, orientações,
/// cartão de pausa e overlay) para dar a identidade de vidro líquido.
class LiquidGlass extends StatelessWidget {
  const LiquidGlass({
    super.key,
    required this.child,
    this.borderRadius = AppRadii.lg,
    this.blur = AppDepth.blur,
    this.saturation = 1.0,
    this.padding,
    this.width,
    this.constraints,
    this.dark = true,
    this.fillOpacity,
  });

  final Widget child;
  final double borderRadius;
  final double blur;

  /// Saturação aplicada ao que está atrás do vidro. `1.0` mantém as cores
  /// originais; valores acima (ex.: `1.5`) dão a vibrância de "liquid glass"
  /// da Apple, fazendo o fundo translúcido parecer vidro de verdade.
  final double saturation;

  final EdgeInsetsGeometry? padding;
  final double? width;
  final BoxConstraints? constraints;

  /// Painel escuro (menu/configurações) ou claro (overlay de pausa).
  final bool dark;

  /// Override opcional da opacidade do preenchimento.
  final double? fillOpacity;

  /// Matriz de saturação (preserva luminância perceptual ITU-R BT.709).
  static List<double> _saturationMatrix(double s) {
    const lumR = 0.2126, lumG = 0.7152, lumB = 0.0722;
    final ir = (1 - s) * lumR;
    final ig = (1 - s) * lumG;
    final ib = (1 - s) * lumB;
    return <double>[
      ir + s,
      ig,
      ib,
      0,
      0,
      ir,
      ig + s,
      ib,
      0,
      0,
      ir,
      ig,
      ib + s,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final highContrast = MediaQuery.maybeOf(context)?.highContrast == true;
    final base = dark
        ? AppColorTokens.surfaceOverlay
        : AppColorTokens.surfaceRaised;
    final requestedOpacity =
        fillOpacity ?? (dark ? AppDepth.darkOpacity : AppDepth.lightOpacity);
    final opacity = highContrast
        ? 1.0
        : requestedOpacity
              .clamp(AppDepth.minimumReadableOpacity, 1.0)
              .toDouble();

    // Blur + saturação compostos num único filtro de backdrop.
    final effectiveBlur = highContrast ? 0.0 : blur;
    final ImageFilter backdrop = saturation == 1.0 || highContrast
        ? ImageFilter.blur(sigmaX: effectiveBlur, sigmaY: effectiveBlur)
        : ImageFilter.compose(
            outer: ColorFilter.matrix(_saturationMatrix(saturation)),
            inner: ImageFilter.blur(
              sigmaX: effectiveBlur,
              sigmaY: effectiveBlur,
            ),
          );

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: highContrast ? const [] : AppDepth.floating,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: backdrop,
          child: Container(
            width: width,
            constraints: constraints,
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: radius,
              color: base.withValues(alpha: opacity),
              border: Border.all(
                color: highContrast
                    ? AppColorTokens.focus
                    : AppColorTokens.border,
                width: highContrast ? 2 : 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
