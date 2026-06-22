import 'dart:ui';

import 'package:flutter/material.dart';

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
    this.borderRadius = 20,
    this.blur = 24,
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
      ir + s, ig, ib, 0, 0,
      ir, ig + s, ib, 0, 0,
      ir, ig, ib + s, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final base = dark ? Colors.black : Colors.white;
    final topAlpha = fillOpacity ?? (dark ? 0.95 : 0.22);
    final bottomAlpha = topAlpha * (dark ? 0.94 : 0.55);

    // Blur + saturação compostos num único filtro de backdrop.
    final ImageFilter backdrop = saturation == 1.0
        ? ImageFilter.blur(sigmaX: blur, sigmaY: blur)
        : ImageFilter.compose(
            outer: ColorFilter.matrix(_saturationMatrix(saturation)),
            inner: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          );

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.42),
            blurRadius: 34,
            spreadRadius: -4,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 6,
            spreadRadius: -2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            BackdropFilter(
              filter: backdrop,
              child: Container(
                width: width,
                constraints: constraints,
                padding: padding,
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(base, Colors.white, dark ? 0.14 : 0.35)!
                          .withValues(alpha: topAlpha),
                      base.withValues(alpha: bottomAlpha),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: dark ? 0.28 : 0.22),
                    width: 1,
                  ),
                ),
                child: child,
              ),
            ),
            // Reflexo de luz no topo (faixa clara que esmaece para baixo).
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: dark ? 0.22 : 0.32),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Borda interna luminosa: realça o contorno do vidro sem somar
            // opacidade ao preenchimento (mantém a translucidez).
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: dark ? 0.10 : 0.16),
                      width: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
