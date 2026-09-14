import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:launch_at_startup/launch_at_startup.dart';

/// Login item no macOS, registro no Windows comum e StartupTask no MSIX.
/// O resultado reflete o estado real do SO, inclusive bloqueios do usuário.
class StartupService {
  StartupService({TargetPlatform? platform})
    : _platform = platform ?? defaultTargetPlatform;

  static const _windowsStore = MethodChannel('dry_eye_widget/windows_store');
  final TargetPlatform _platform;
  bool _ready = false;
  bool _packaged = false;
  Future<void>? _initialization;

  /// Inicia a configuração uma vez; operações aguardam sua conclusão.
  void init() {
    _initialization ??= _configure();
  }

  Future<void> _configure() async {
    if (kIsWeb ||
        !(_platform == TargetPlatform.macOS ||
            _platform == TargetPlatform.windows)) {
      return;
    }
    try {
      if (_platform == TargetPlatform.windows) {
        // Se a consulta falhar, não escrever no registro: a identidade do
        // pacote ainda é desconhecida e a integração comum seria incorreta.
        final packaged = await _windowsStore.invokeMethod<bool>('isPackaged');
        if (packaged == null) {
          throw StateError('Windows did not return its package identity');
        }
        _packaged = packaged;
      }
      if (!_packaged) {
        launchAtStartup.setup(
          appName: 'Dry Eye Widget',
          appPath: Platform.resolvedExecutable,
        );
      }
      _ready = true;
    } catch (e) {
      debugPrint('StartupService: setup falhou ($e).');
      _ready = false;
    }
  }

  Future<bool> isEnabled() async {
    await _initialization;
    if (!_ready) return false;
    try {
      if (_packaged) {
        return await _windowsStore.invokeMethod<bool>('getStartupEnabled') ??
            false;
      }
      return await launchAtStartup.isEnabled();
    } catch (e) {
      debugPrint('StartupService: isEnabled falhou ($e).');
      return false;
    }
  }

  /// Retorna o estado efetivo, que pode diferir do pedido por política do SO
  /// ou porque o usuário desabilitou o app no Gerenciador de Tarefas.
  Future<bool> setEnabled(bool enabled) async {
    await _initialization;
    if (!_ready) return false;
    try {
      if (_packaged) {
        return await _windowsStore.invokeMethod<bool>(
              'setStartupEnabled',
              enabled,
            ) ??
            false;
      }
      if (enabled) {
        await launchAtStartup.enable();
      } else {
        await launchAtStartup.disable();
      }
      return await launchAtStartup.isEnabled();
    } catch (e) {
      debugPrint('StartupService: setEnabled($enabled) falhou ($e).');
      return isEnabled();
    }
  }
}
