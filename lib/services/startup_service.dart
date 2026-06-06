import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:launch_at_startup/launch_at_startup.dart';

/// Controla se o app inicia automaticamente com o sistema (login item).
///
/// No macOS usa `SMAppService`; no Windows, uma entrada no registro de
/// inicialização. Todas as chamadas são tolerantes a falha — em ambiente de
/// teste ou sem suporte, viram no-op em vez de derrubar o app.
class StartupService {
  bool _ready = false;

  /// Configura o pacote com o nome e o caminho do executável atual.
  /// Deve ser chamado uma vez no boot, após o binding inicializar.
  void init() {
    if (kIsWeb) return;
    if (!(Platform.isMacOS || Platform.isWindows)) return;
    try {
      launchAtStartup.setup(
        appName: 'Dry Eye Widget',
        appPath: Platform.resolvedExecutable,
      );
      _ready = true;
    } catch (e) {
      debugPrint('StartupService: setup falhou ($e).');
      _ready = false;
    }
  }

  Future<bool> isEnabled() async {
    if (!_ready) return false;
    try {
      return await launchAtStartup.isEnabled();
    } catch (e) {
      debugPrint('StartupService: isEnabled falhou ($e).');
      return false;
    }
  }

  /// Habilita ou desabilita a inicialização automática.
  Future<void> setEnabled(bool enabled) async {
    if (!_ready) return;
    try {
      if (enabled) {
        await launchAtStartup.enable();
      } else {
        await launchAtStartup.disable();
      }
    } catch (e) {
      debugPrint('StartupService: setEnabled($enabled) falhou ($e).');
    }
  }
}
