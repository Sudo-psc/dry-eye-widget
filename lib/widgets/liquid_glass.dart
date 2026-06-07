import 'dart:ui';

import 'package:flutter/material.dart';

/// Painel com efeito "liquid glass": desfoque de fundo, preenchimento em
/// gradiente translúcido, brilho superior (reflexo) e borda luminosa.
///
/// Usado de forma consistente em todo o app (menu, configurações, orientações,
/// cartão de pausa e overlay) para dar a identidade de vidro líquido.
class LiquidGlass extends StatelessWidget {
  const LiquidGlass({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.blur = 24,
    this.padding,
    this.width,
    this.constraints,
    this.dark = true,
    this.fillOpacity,
  });

  final Widget child;
  final double borderRadius;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final BoxConstraints? constraints;

  /// Painel escuro (menu/configurações) ou claro (overlay de pausa).
  final bool dark;

  /// Override opcional da opacidade do preenchimento.
  final double? fillOpacity;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final base = dark ? const Color(0xFF26262C) : Colors.white;
    final topAlpha = fillOpacity ?? (dark ? 0.80 : 0.22);
    final bottomAlpha = topAlpha * (dark ? 0.94 : 0.55);

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.38),
            blurRadius: 28,
            spreadRadius: -2,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
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
                      Color.lerp(base, Colors.white, dark ? 0.12 : 0.35)!
                          .withValues(alpha: topAlpha),
                      base.withValues(alpha: bottomAlpha),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
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
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: dark ? 0.16 : 0.30),
                        Colors.white.withValues(alpha: 0.0),
                      ],
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
