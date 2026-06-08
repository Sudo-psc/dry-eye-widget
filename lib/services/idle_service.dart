import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Lê o tempo ocioso do sistema (segundos desde a última entrada do usuário —
/// movimento de mouse, cliques ou teclas — em todo o sistema), via canal
/// nativo. Funciona mesmo quando o app não está em foco.
class IdleService {
  static const MethodChannel _channel = MethodChannel('dry_eye_widget/idle');

  /// Segundos desde a última atividade. Retorna 0 se indisponível.
  Future<double> idleSeconds() async {
    try {
      final value = await _channel.invokeMethod<double>('idleSeconds');
      return value ?? 0;
    } catch (e) {
      debugPrint('IdleService: indisponível ($e).');
      return 0;
    }
  }
}
