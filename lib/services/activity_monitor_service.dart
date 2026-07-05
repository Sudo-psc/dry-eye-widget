import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Amostra de atividade acumulada desde a última consulta ao canal nativo.
@immutable
class ActivitySample {
  const ActivitySample({
    this.clicks = 0,
    this.keys = 0,
    this.frontApp,
  });

  /// Cliques do mouse desde o último poll.
  final int clicks;

  /// Teclas pressionadas desde o último poll (apenas contagem).
  final int keys;

  /// App em primeiro plano no momento do poll (nome legível), se disponível.
  final String? frontApp;
}

/// Ponte com o monitor de atividade nativo (cliques, teclas e app em foco).
///
/// **Privacidade (LGPD):** conta apenas QUANTIDADES agregadas de cliques e
/// teclas — nunca quais teclas — e o nome do app em foco. Tudo local, opt-in.
/// No macOS a contagem de teclas exige permissão de Acessibilidade do sistema;
/// cliques e app em foco não exigem. Em plataformas sem suporte, degrada para
/// zeros (nenhum dado é coletado).
class ActivityMonitorService {
  const ActivityMonitorService();

  static const MethodChannel _channel =
      MethodChannel('dry_eye_widget/activity');

  /// Liga o monitor nativo (registra os observadores globais). Idempotente.
  Future<void> start() async {
    try {
      await _channel.invokeMethod<void>('start');
    } catch (e) {
      debugPrint('ActivityMonitor start indisponível ($e).');
    }
  }

  /// Desliga o monitor nativo (remove os observadores).
  Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stop');
    } catch (e) {
      debugPrint('ActivityMonitor stop indisponível ($e).');
    }
  }

  /// Consulta e ZERA os contadores nativos desde o último poll.
  /// Retorna `null` se indisponível (nenhum dado coletado).
  Future<ActivitySample?> poll() async {
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>('poll');
      if (res == null) return null;
      return ActivitySample(
        clicks: (res['clicks'] as num?)?.toInt() ?? 0,
        keys: (res['keys'] as num?)?.toInt() ?? 0,
        frontApp: (res['frontApp'] as String?)?.trim().isEmpty ?? true
            ? null
            : res['frontApp'] as String,
      );
    } catch (e) {
      debugPrint('ActivityMonitor poll indisponível ($e).');
      return null;
    }
  }

  /// `true` se a contagem de teclas está autorizada (permissão de
  /// Acessibilidade no macOS). Cliques/app não dependem disso.
  Future<bool> hasKeyPermission() async {
    try {
      return await _channel.invokeMethod<bool>('hasKeyPermission') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Abre as preferências do sistema para conceder a permissão (macOS).
  Future<void> openPermissionSettings() async {
    try {
      await _channel.invokeMethod<void>('openPermissionSettings');
    } catch (_) {
      /* ignora */
    }
  }
}
