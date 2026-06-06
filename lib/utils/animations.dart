import 'package:flutter/material.dart';

/// Funções e curvas de animação reutilizáveis.
class AppAnimations {
  AppAnimations._();

  /// Curva suave padrão para fades e transições.
  static const Curve smooth = Curves.easeInOut;

  /// Curva com pequeno "bounce" usada no scale do cronômetro.
  static const Curve bounce = Curves.elasticOut;

  /// Constrói um [TweenAnimationBuilder] de opacidade para fade-in.
  static Widget fadeIn({
    required Widget child,
    required Duration duration,
    double begin = 0.0,
    double end = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: begin, end: end),
      duration: duration,
      curve: smooth,
      builder: (context, value, child) =>
          Opacity(opacity: value.clamp(0.0, 1.0), child: child),
      child: child,
    );
  }
}
