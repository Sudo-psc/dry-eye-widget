import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

/// Mostra ou esconde o app na barra de aplicativos do sistema.
///
/// No macOS isso é a política de ativação (`.regular` × `.accessory`), tratada
/// por canal nativo: o `window_manager` troca a política cedo demais na subida
/// do app e o AppKit ignora a mudança, deixando o ícone no Dock mesmo com a
/// opção ligada. No Windows o equivalente é sumir da barra de tarefas, onde o
/// `setSkipTaskbar` do próprio `window_manager` resolve.
class DockIconService {
  const DockIconService([this.channel = _defaultChannel]);

  static const MethodChannel _defaultChannel = MethodChannel(
    'dry_eye_widget/dock',
  );

  final MethodChannel channel;

  /// Aplica [hidden] ao ícone do app. Devolve `true` quando o sistema confirma.
  Future<bool> setHidden(bool hidden) async {
    if (Platform.isMacOS) {
      try {
        final applied = await channel.invokeMethod<bool>(
          'setDockIconVisible',
          {'visible': !hidden},
        );
        return applied ?? false;
      } catch (e) {
        debugPrint('DockIconService: canal indisponível ($e).');
        return false;
      }
    }

    try {
      await windowManager.setSkipTaskbar(hidden);
      return true;
    } catch (e) {
      debugPrint('DockIconService: setSkipTaskbar falhou ($e).');
      return false;
    }
  }

  /// Aplica [hidden] e confere o resultado, tentando de novo uma vez.
  ///
  /// O AppKit recusa a troca de política em alguns instantes (app subindo, app
  /// em transição de ativação), então uma segunda tentativa depois de
  /// [retryDelay] costuma pegar. Devolve o estado com que o sistema ficou:
  /// [hidden] em caso de sucesso, o estado real quando a troca foi recusada, ou
  /// `null` quando nem dá para consultar — inclusive quando [isStale] indica
  /// que a preferência mudou de novo e este pedido deixou de valer.
  Future<bool?> applyWithRetry(
    bool hidden, {
    Duration retryDelay = const Duration(milliseconds: 400),
    bool Function()? isStale,
  }) async {
    if (await setHidden(hidden)) return hidden;
    if (isStale?.call() ?? false) return null;
    await Future<void>.delayed(retryDelay);
    if (isStale?.call() ?? false) return null;
    if (await setHidden(hidden)) return hidden;
    if (isStale?.call() ?? false) return null;
    return isHidden();
  }

  /// Estado atual segundo o sistema; `null` quando não dá para consultar.
  Future<bool?> isHidden() async {
    if (!Platform.isMacOS) return null;
    try {
      final visible = await channel.invokeMethod<bool>('isDockIconVisible');
      return visible == null ? null : !visible;
    } catch (e) {
      debugPrint('DockIconService: consulta indisponível ($e).');
      return null;
    }
  }
}
