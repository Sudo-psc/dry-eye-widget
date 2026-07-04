import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Exibe o cronômetro regressivo no formato MM:SS com um pequeno "bounce"
/// de escala a cada mudança de segundo.
class TimerDisplay extends StatelessWidget {
  const TimerDisplay({super.key, required this.secondsRemaining});

  final int secondsRemaining;

  String get _formatted {
    final m = (secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final s = (secondsRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    // A key muda a cada segundo, reiniciando o TweenAnimationBuilder e
    // produzindo o efeito de scale 1.0 -> 1.1 -> 1.0.
    return TweenAnimationBuilder<double>(
      key: ValueKey(secondsRemaining),
      tween: Tween(begin: 1.1, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Text(
        _formatted,
        style: const TextStyle(
          fontFamily: 'RobotoMono',
          fontSize: 34,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
