import 'package:flutter/material.dart';

import '../ui/design_tokens.dart';

/// Cronômetro regressivo estável, com algarismos tabulares.
///
/// O valor não pulsa a cada segundo: a mudança numérica já comunica progresso
/// e evita movimento contínuo numa interface voltada à fadiga ocular.
class TimerDisplay extends StatelessWidget {
  const TimerDisplay({super.key, required this.secondsRemaining});

  final int secondsRemaining;

  String get _formatted {
    final m = (secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final s = (secondsRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) => Text(
    _formatted,
    key: ValueKey(secondsRemaining),
    style: AppTypography.timerStyle,
  );
}
