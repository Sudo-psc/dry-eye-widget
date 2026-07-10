import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';

import '../l10n/app_strings.dart';
import '../utils/eye_icon.dart';

/// Gerencia o ícone na barra de menu (macOS) / bandeja do sistema (Windows).
///
/// Mostra um olho cuja barra inferior se preenche conforme o progresso até a
/// próxima pausa, e oferece um menu para desabilitar/reabilitar o widget,
/// iniciar a pausa, abrir as configurações ou sair.
///
/// As chaves dos itens de menu são tratadas por quem implementa o
/// [TrayListener] (no caso, a HomePage).
class TrayService {
  static const String keyToggle = 'toggle_widget';
  static const String keyBreak = 'start_break';
  static const String keySettings = 'open_settings';
  static const String keyDaySummary = 'open_day_summary';
  static const String keyDvrs = 'open_dvrs';
  static const String keyGithub = 'open_github';
  static const String keyReports = 'open_reports';
  static const String keyQuit = 'quit';

  /// Quantidade de passos do progresso. Mantido próximo da largura útil da
  /// barra (em px) para que cada passo represente ~1 px de mudança real.
  static const int _steps = 30;

  bool _ready = false;
  int _lastStep = -1;
  bool _busy = false;
  String? _lastIconPath;

  // No macOS usamos um ícone "template" preto que o sistema adapta ao tema
  // da barra de menu; nas demais plataformas, branco.
  Color get _color => Platform.isMacOS ? Colors.black : Colors.white;
  bool get _isTemplate => Platform.isMacOS;

  AppStrings _strings = ptStrings;

  Future<void> init({
    required bool widgetEnabled,
    required AppStrings strings,
  }) async {
    if (!(Platform.isMacOS || Platform.isWindows)) return;
    _strings = strings;
    // O ícone é o que importa para o serviço estar "pronto". Marcamos como
    // pronto assim que ele é exibido — tooltip e menu são best-effort e não
    // podem bloquear as futuras atualizações de progresso.
    _ready = await _renderAndSet(0, force: true);
    try {
      await trayManager.setToolTip('Dry Eye Widget');
    } catch (e) {
      debugPrint('TrayService: setToolTip falhou ($e).');
    }
    await updateMenu(widgetEnabled: widgetEnabled, strings: strings);
  }

  /// Atualiza a barra de progresso do ícone (com throttle por passo).
  Future<void> updateProgress(double progress) async {
    if (!_ready) return;
    final step = (progress.clamp(0.0, 1.0) * _steps).round();
    if (step == _lastStep) return;
    await _renderAndSet(progress);
  }

  Future<bool> _renderAndSet(double progress, {bool force = false}) async {
    final step = (progress.clamp(0.0, 1.0) * _steps).round();
    if (!force && step == _lastStep) return true;
    if (_busy) return false; // evita gerações concorrentes a cada tick
    _busy = true;
    try {
      final path = await EyeIcon.render(progress: progress, color: _color);
      await trayManager.setIcon(path, isTemplate: _isTemplate);
      // Remove o PNG anterior para não acumular arquivos temporários.
      final previous = _lastIconPath;
      if (previous != null && previous != path) {
        try {
          await File(previous).delete();
        } catch (_) {
          /* ignora */
        }
      }
      _lastIconPath = path;
      _lastStep = step;
      return true;
    } catch (e) {
      debugPrint('TrayService: render/setIcon falhou ($e).');
      return false;
    } finally {
      _busy = false;
    }
  }

  /// (Re)constrói o menu de contexto com o rótulo correto de habilitar/
  /// desabilitar o widget.
  Future<void> updateMenu({
    required bool widgetEnabled,
    required AppStrings strings,
  }) async {
    if (!(Platform.isMacOS || Platform.isWindows)) return;
    _strings = strings;
    try {
      await trayManager.setContextMenu(
        Menu(
          items: [
            MenuItem(
              key: keyToggle,
              label: widgetEnabled ? strings.trayDisable : strings.trayEnable,
            ),
            MenuItem(key: keyBreak, label: strings.menuStartBreak),
            MenuItem.separator(),
            MenuItem(key: keyDaySummary, label: strings.menuDaySummary),
            MenuItem(key: keyDvrs, label: strings.menuDvrs),
            MenuItem(key: keyReports, label: strings.menuReports),
            MenuItem(key: keySettings, label: strings.menuSettings),
            MenuItem(key: keyGithub, label: strings.menuGitHub),
            MenuItem(key: keyQuit, label: strings.menuQuit),
          ],
        ),
      );
    } catch (e) {
      debugPrint('TrayService: updateMenu falhou ($e).');
    }
  }

  /// Mostra ou oculta o item da barra de menu em tempo de execução.
  Future<void> setVisible(
    bool visible, {
    required bool widgetEnabled,
    AppStrings? strings,
  }) async {
    if (!(Platform.isMacOS || Platform.isWindows)) return;
    if (visible) {
      if (_ready) return;
      _lastStep = -1;
      _lastIconPath = null;
      await init(widgetEnabled: widgetEnabled, strings: strings ?? _strings);
    } else {
      await dispose();
      _ready = false;
    }
  }

  Future<void> dispose() async {
    try {
      await trayManager.destroy();
    } catch (_) {
      /* ignora */
    }
  }
}
