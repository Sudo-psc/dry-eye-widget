import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:provider/provider.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'l10n/app_strings.dart';
import 'models/app_state.dart';
import 'models/osdi_assessment.dart';
import 'models/widget_settings.dart';
import 'providers/settings_provider.dart';
import 'providers/timer_provider.dart';
import 'services/audio_service.dart';
import 'services/idle_service.dart';
import 'services/notification_service.dart';
import 'services/screen_time_service.dart';
import 'services/presence/adaptive_threshold_model.dart';
import 'services/presence/camera_presence_sensor.dart';
import 'services/presence/presence_controller.dart';
import 'services/presence/secure_presence_store.dart';
import 'services/secure_storage_service.dart';
import 'services/vision_service.dart';
import 'services/startup_service.dart';
import 'services/storage_service.dart';
import 'services/tray_service.dart';
import 'services/update_service.dart';
import 'utils/constants.dart';
import 'widgets/about_panel.dart';
import 'widgets/eye_drops_reminder.dart';
import 'widgets/floating_ball.dart';
import 'widgets/floating_menu.dart';
import 'widgets/gentle_break_card.dart';
import 'widgets/glass_overlay.dart';
import 'widgets/guidance_dialog.dart';
import 'widgets/health_dashboard_dialog.dart';
import 'widgets/inactivity_pause_card.dart';
import 'widgets/osdi_dialog.dart';
import 'widgets/screen_time_dialog.dart';
import 'widgets/settings_dialog.dart';
import 'widgets/update_dialog.dart';

/// Tamanhos das janelas de configurações (a compacta e a do menu são dinâmicas).
const Size _settingsWindowSize = Size(460, 700);
const Size _osdiWindowSize = Size(700, 790);

/// Tamanho da janela compacta em função do diâmetro da bolinha.
Size _compactWindowSize(double ballSize) => Size(ballSize + 24, ballSize + 24);

/// Altura do painel de menu (cabeçalho + 12 itens + paddings do vidro), com
/// folga para variações de fonte entre plataformas.
const double _menuPanelHeight = 552;

/// Tamanho da janela do menu em função do diâmetro da bolinha-cabeçalho.
/// A altura acompanha a bolinha + o painel completo para que o último item
/// ("Sair") nunca seja cortado pela borda da janela (Windows e macOS).
Size _menuWindowSize(double ballSize) =>
    Size(300, ballSize + 24 + _menuPanelHeight + 8);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Window.initialize();
  await windowManager.ensureInitialized();

  final storage = await StorageService.init();
  final settings = SettingsProvider(storage: storage);
  final screenTime = ScreenTimeService(storage: storage);
  final audio = AudioService()..enabled = settings.value.soundEnabled;
  final notifications = NotificationService()
    ..enabled = settings.value.notificationsEnabled;
  await notifications.init();

  // Módulo de inatividade: ociosidade do SO + limiar adaptativo, com estado
  // agregado persistido cifrado em repouso (Keychain/DPAPI).
  final idle = IdleService();
  final presence = PresenceController(
    model: AdaptiveThresholdModel(),
    idleSource: idle.idleSeconds,
    store: SecurePresenceStore(
      const ChannelSecureStore(),
      storageKey: StorageKeys.presenceModel,
    ),
    // Câmera opcional: só consultada quando habilitada nas configurações
    // (disponível apenas no macOS por ora).
    cameraSensor: CameraPresenceSensor(const VisionService().hasFace),
    cameraEnabled: () => Platform.isMacOS && settings.value.cameraPresence,
  );
  await presence.hydrate();

  final startup = StartupService()..init();
  // Garante que o estado do sistema bata com a preferência salva.
  await startup.setEnabled(settings.value.launchAtLogin);

  final tray = TrayService();
  if (!settings.value.hideMenuBarItem) {
    await tray.init(
      widgetEnabled: !settings.value.hideFloatingWidget,
      strings: settings.strings,
    );
  }

  final initialSize = _compactWindowSize(settings.value.ballSize);
  final windowOptions = WindowOptions(
    size: initialSize,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    alwaysOnTop: true,
    windowButtonVisibility: false,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setAsFrameless();
    await windowManager.setBackgroundColor(Colors.transparent);
    await windowManager.setAlwaysOnTop(true);
    // Mantém o widget visível mesmo sobre apps em tela cheia: no macOS a
    // janela precisa de canJoinAllSpaces + fullScreenAuxiliary para entrar
    // nos Spaces de tela cheia de outros apps (nível .floating sozinho não
    // basta). No Windows o método não é suportado.
    if (Platform.isMacOS) {
      await windowManager.setVisibleOnAllWorkspaces(
        true,
        visibleOnFullScreen: true,
      );
    }
    await windowManager.setResizable(false);
    await windowManager.setSkipTaskbar(settings.value.hideDockIcon);
    // Transparência real do conteúdo: no macOS o `setEffect` sozinho deixa o
    // fundo opaco — `makeWindowFullyTransparent` adiciona a máscara vazia que
    // torna o FlutterView de fato transparente (sem blur/sombra).
    if (Platform.isMacOS) {
      Window.makeWindowFullyTransparent();
    } else {
      await Window.setEffect(effect: WindowEffect.transparent);
    }
    await _restoreBallPosition(storage, settings.value, initialSize);
    await windowManager.show();
  });

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        Provider<AudioService>.value(value: audio),
        Provider<StartupService>.value(value: startup),
        Provider<TrayService>.value(value: tray),
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ChangeNotifierProvider<ScreenTimeService>.value(value: screenTime),
        ChangeNotifierProvider<TimerProvider>(
          create: (_) => TimerProvider(
            settings: settings,
            storage: storage,
            audio: audio,
            notifications: notifications,
            presence: presence,
            screenTime: screenTime,
          )..start(),
        ),
      ],
      child: const DryEyeApp(),
    ),
  );
}

/// Posiciona a janela na última posição salva ou no canto padrão.
Future<void> _restoreBallPosition(
  StorageService storage,
  WidgetSettings settings,
  Size windowSize,
) async {
  final savedX = storage.ballX;
  final savedY = storage.ballY;
  if (savedX != null && savedY != null) {
    await windowManager.setPosition(Offset(savedX, savedY));
    return;
  }
  await windowManager.setPosition(
    await _cornerOffset(settings.defaultCorner, windowSize),
  );
}

/// Calcula o canto da tela primária para um dado tamanho de janela.
Future<Offset> _cornerOffset(BallCorner corner, Size windowSize) async {
  const margin = 24.0;
  try {
    final display = await screenRetriever.getPrimaryDisplay();
    final screen = display.visibleSize ?? display.size;
    final maxX = screen.width - windowSize.width - margin;
    final maxY = screen.height - windowSize.height - margin;
    switch (corner) {
      case BallCorner.topLeft:
        return const Offset(margin, margin);
      case BallCorner.topRight:
        return Offset(maxX, margin);
      case BallCorner.bottomLeft:
        return Offset(margin, maxY);
      case BallCorner.bottomRight:
        return Offset(maxX, maxY);
      case BallCorner.center:
        return Offset(maxX / 2, maxY / 2);
    }
  } catch (_) {
    return const Offset(100, 100);
  }
}

class DryEyeApp extends StatelessWidget {
  const DryEyeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.idleBall,
          brightness: Brightness.dark,
        ),
      ),
      home: const HomePage(),
    );
  }
}

enum _WindowLayout {
  ball,
  blinkReminder,
  menu,
  settings,
  osdi,
  breakOverlay,
  gentleBreak,
  inactivity,
}

/// Tamanho do cartão de pausa no modo suave (canto superior direito).
const Size _gentleWindowSize = Size(430, 164);

/// Tamanho do cartão de aviso de pausa por inatividade (canto superior direito).
const Size _inactivityWindowSize = Size(320, 120);

/// Tamanho da micronotificação de piscada em função do diâmetro da bolinha.
Size _blinkReminderWindowSize(double ballSize) => Size(
  math.max(ballSize + 156, 176.0).toDouble(),
  math.max(ballSize + 24, 52.0).toDouble(),
);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TrayListener {
  late final TimerProvider _timer;
  late final SettingsProvider _settings;
  late final AudioService _audio;
  late final TrayService _tray;

  bool _menuOpen = false;
  bool _settingsOpen = false;
  bool _aboutOpen = false;
  bool _guidanceOpen = false;
  bool _updateOpen = false;
  bool _osdiOpen = false;
  bool _screenTimeOpen = false;
  bool _healthDashboardOpen = false;
  bool _wasActive = false;
  bool _wasDrops = false;
  bool _wasInactive = false;
  bool _blinkReminderVisible = false;
  Timer? _blinkReminderTicker;
  Timer? _blinkReminderHideTimer;

  final UpdateService _updater = UpdateService();
  UpdateResult? _updateResult;
  List<OsdiAssessment> _osdiHistory = const [];

  /// Widget habilitado = bolinha visível. Quando desabilitado (pela opção
  /// nas configurações ou pelo item da barra de menu), a janela é escondida
  /// — mas o ciclo e o ícone da barra de menu continuam.
  bool _widgetEnabled = true;

  Offset _ballPosition = const Offset(100, 100);
  double _lastBallSize = AppDefaults.ballSize;
  bool _lastDockHidden = AppDefaults.hideDockIcon;
  bool _lastHideMenuBar = AppDefaults.hideMenuBarItem;
  bool _lastHideFloating = AppDefaults.hideFloatingWidget;
  String _lastLanguage = AppDefaults.languageCode;

  @override
  void initState() {
    super.initState();
    _timer = context.read<TimerProvider>();
    _settings = context.read<SettingsProvider>();
    _audio = context.read<AudioService>();
    _tray = context.read<TrayService>();
    _lastBallSize = _settings.value.ballSize;
    _lastDockHidden = _settings.value.hideDockIcon;
    _lastHideMenuBar = _settings.value.hideMenuBarItem;
    _lastHideFloating = _settings.value.hideFloatingWidget;
    _lastLanguage = _settings.value.languageCode;
    _widgetEnabled = !_settings.value.hideFloatingWidget;
    _timer.addListener(_onStateChanged);
    _settings.addListener(_onSettingsChanged);
    trayManager.addListener(this);
    _startBlinkReminderLoop();
    _cacheCurrentPosition();
    // Aplica o estado inicial de visibilidade da bolinha após o primeiro frame.
    if (!_widgetEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => windowManager.hide());
    }
  }

  Future<void> _cacheCurrentPosition() async {
    try {
      _ballPosition = await windowManager.getPosition();
    } catch (_) {
      /* ignora */
    }
  }

  @override
  void dispose() {
    _timer.removeListener(_onStateChanged);
    _settings.removeListener(_onSettingsChanged);
    trayManager.removeListener(this);
    _blinkReminderTicker?.cancel();
    _blinkReminderHideTimer?.cancel();
    super.dispose();
  }

  void _startBlinkReminderLoop() {
    _blinkReminderTicker?.cancel();
    _blinkReminderTicker = Timer.periodic(
      const Duration(milliseconds: AppDefaults.blinkReminderIntervalMs),
      (_) {
        if (_canTriggerBlinkReminder) {
          unawaited(_triggerBlinkReminder());
        } else if (_blinkReminderVisible) {
          _hideBlinkReminder(restoreLayout: true);
        }
      },
    );
  }

  bool get _canTriggerBlinkReminder =>
      mounted &&
      _isBlinkReminderContextFree &&
      (_canShowVisualBlinkReminder ||
          _settings.value.blinkReminderSoundEnabled);

  bool get _isBlinkReminderContextFree =>
      !_menuOpen &&
      !_settingsOpen &&
      !_aboutOpen &&
      !_guidanceOpen &&
      !_updateOpen &&
      !_osdiOpen &&
      !_screenTimeOpen &&
      !_timer.eyeDropsAlert &&
      !_timer.inactivityAlert &&
      !_timer.isPaused &&
      _timer.state == AppState.idle;

  bool get _canShowVisualBlinkReminder =>
      _settings.value.visualBlinkRemindersEnabled && _widgetEnabled;

  Future<void> _triggerBlinkReminder() async {
    if (!_canTriggerBlinkReminder) return;
    final settings = _settings.value;
    // O aviso sonoro de piscada tem habilitação própria, independente do
    // controle de som dos avisos 20-20-20 ([soundEnabled]).
    if (settings.blinkReminderSoundEnabled) {
      unawaited(
        _audio.playBlinkReminder(
          sound: settings.blinkReminderSound,
          volume: settings.blinkReminderVolume,
        ),
      );
    }

    if (_blinkReminderVisible || !_canShowVisualBlinkReminder) return;
    setState(() => _blinkReminderVisible = true);
    await _applyLayout(_WindowLayout.blinkReminder);
    _blinkReminderHideTimer?.cancel();
    _blinkReminderHideTimer = Timer(
      const Duration(milliseconds: AppDefaults.blinkReminderVisibleMs),
      () => _hideBlinkReminder(restoreLayout: true),
    );
  }

  void _hideBlinkReminder({required bool restoreLayout}) {
    _blinkReminderHideTimer?.cancel();
    _blinkReminderHideTimer = null;
    if (!_blinkReminderVisible) return;
    if (mounted) setState(() => _blinkReminderVisible = false);
    if (restoreLayout && _isCompactLayoutFree) {
      unawaited(_applyLayout(_WindowLayout.ball));
    }
  }

  bool get _isCompactLayoutFree =>
      _widgetEnabled &&
      !_menuOpen &&
      !_settingsOpen &&
      !_aboutOpen &&
      !_guidanceOpen &&
      !_updateOpen &&
      !_osdiOpen &&
      !_screenTimeOpen &&
      !_timer.eyeDropsAlert &&
      !_timer.inactivityAlert &&
      _timer.state == AppState.idle;

  void _onStateChanged() {
    // Mantém o ícone da barra de menu em sincronia com o progresso do ciclo.
    _tray.updateProgress(_timer.cycleProgress);
    final active = _timer.state.isActive;
    if (active && !_wasActive) {
      _enterBreakLayout();
    } else if (!active && _wasActive) {
      _exitBreakLayout();
    }
    _wasActive = active;

    // Aviso de colírio: expande a janela para o cartão centralizado.
    final drops = _timer.eyeDropsAlert;
    if (drops && !_wasDrops) {
      if (!_menuOpen &&
          !_settingsOpen &&
          !_aboutOpen &&
          !_guidanceOpen &&
          !_updateOpen &&
          !_osdiOpen &&
          !_screenTimeOpen) {
        () async {
          if (!_widgetEnabled) await windowManager.show();
          await _applyLayout(_WindowLayout.settings);
        }();
      }
    } else if (!drops && _wasDrops) {
      _restoreAfterPanel();
    }
    _wasDrops = drops;

    // Aviso de pausa por inatividade: expande para o cartão discreto no canto.
    // A pausa 20-20-20 e os painéis (colírio/menu/config) têm prioridade visual.
    final inactive = _timer.inactivityAlert;
    if (inactive && !_wasInactive) {
      if (!active &&
          !drops &&
          !_menuOpen &&
          !_settingsOpen &&
          !_aboutOpen &&
          !_guidanceOpen &&
          !_updateOpen &&
          !_osdiOpen &&
          !_screenTimeOpen) {
        () async {
          if (!_widgetEnabled) await windowManager.show();
          await _applyLayout(_WindowLayout.inactivity);
        }();
      }
    } else if (!inactive && _wasInactive) {
      _restoreAfterPanel();
    }
    _wasInactive = inactive;
  }

  // --- Item da barra de menu (TrayListener) ------------------------------

  @override
  void onTrayIconMouseDown() => trayManager.popUpContextMenu();

  @override
  void onTrayIconRightMouseDown() => trayManager.popUpContextMenu();

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case TrayService.keyToggle:
        _toggleWidget();
        break;
      case TrayService.keyBreak:
        _timer.startBreakNow();
        break;
      case TrayService.keySettings:
        _openSettingsFromTray();
        break;
      case TrayService.keyOsdi:
        _openOsdiFromTray();
        break;
      case TrayService.keyHealthDashboard:
        _openHealthDashboardFromTray();
        break;
      case TrayService.keyGithub:
        _openGithub();
        break;
      case TrayService.keyQuit:
        _quit();
        break;
    }
  }

  Future<void> _toggleWidget() => _setWidgetEnabled(!_widgetEnabled);

  Future<void> _setWidgetEnabled(bool enabled) async {
    _widgetEnabled = enabled;
    if (enabled) {
      await windowManager.show();
      await _applyLayout(_WindowLayout.ball);
    } else if (!_timer.state.isActive) {
      await windowManager.hide();
    }
    await _tray.updateMenu(
      widgetEnabled: _widgetEnabled,
      strings: _settings.strings,
    );
  }

  Future<void> _openSettingsFromTray() async {
    if (!_widgetEnabled) await windowManager.show();
    _openSettings();
  }

  Future<void> _openOsdiFromTray() async {
    if (!_widgetEnabled) await windowManager.show();
    _openOsdi();
  }

  Future<void> _openHealthDashboardFromTray() async {
    if (!_widgetEnabled) await windowManager.show();
    _openHealthDashboard();
  }

  Future<void> _openGithub() async {
    const url = 'https://github.com/Sudo-psc/dry-eye-widget';
    try {
      if (Platform.isMacOS) {
        await Process.run('open', [url]);
      } else if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', url]);
      } else {
        await Process.run('xdg-open', [url]);
      }
    } catch (e) {
      debugPrint('Não foi possível abrir o GitHub: $e');
    }
  }

  /// Reage a mudanças de configuração: se o tamanho da bolinha mudou e
  /// estamos em modo compacto, redimensiona a janela na hora.
  void _onSettingsChanged() {
    final newSize = _settings.value.ballSize;
    if (newSize != _lastBallSize) {
      _lastBallSize = newSize;
      _timer.clampElapsedToCycle();
      if (!_menuOpen && !_settingsOpen && !_timer.state.isActive) {
        _applyLayout(_WindowLayout.ball);
      }
    }
    final hideDock = _settings.value.hideDockIcon;
    if (hideDock != _lastDockHidden) {
      _lastDockHidden = hideDock;
      windowManager.setSkipTaskbar(hideDock);
    }
    final hideMenuBar = _settings.value.hideMenuBarItem;
    if (hideMenuBar != _lastHideMenuBar) {
      _lastHideMenuBar = hideMenuBar;
      _tray.setVisible(
        !hideMenuBar,
        widgetEnabled: _widgetEnabled,
        strings: _settings.strings,
      );
    }
    final hideFloating = _settings.value.hideFloatingWidget;
    if (hideFloating != _lastHideFloating) {
      _lastHideFloating = hideFloating;
      _setWidgetEnabled(!hideFloating);
    }
    final lang = _settings.value.languageCode;
    if (lang != _lastLanguage) {
      _lastLanguage = lang;
      _tray.updateMenu(
        widgetEnabled: _widgetEnabled,
        strings: _settings.strings,
      );
    }
    if (!_settings.value.visualBlinkRemindersEnabled && _blinkReminderVisible) {
      _hideBlinkReminder(restoreLayout: true);
    }
  }

  // --- Layout da janela ---------------------------------------------------

  Future<void> _enterBreakLayout() async {
    if (mounted) {
      setState(() {
        _menuOpen = false;
        _settingsOpen = false;
        _aboutOpen = false;
      });
    }
    // A pausa aparece mesmo se o widget estiver desabilitado (a janela pode
    // estar escondida); garantimos que ela volte a ser exibida.
    if (!_widgetEnabled) await windowManager.show();
    await _cacheCurrentPosition();
    await _applyLayout(
      _settings.value.usesFullScreenBreak
          ? _WindowLayout.breakOverlay
          : _WindowLayout.gentleBreak,
    );
  }

  Future<void> _exitBreakLayout() async {
    // Restaura o layout correto após a pausa 20-20-20 — incluindo o aviso de
    // inatividade, caso o ciclo tenha sido pausado por ociosidade nesse meio.
    _restoreAfterPanel();
  }

  Future<void> _applyLayout(_WindowLayout layout) async {
    if (layout != _WindowLayout.blinkReminder && _blinkReminderVisible) {
      _blinkReminderHideTimer?.cancel();
      _blinkReminderHideTimer = null;
      if (mounted) setState(() => _blinkReminderVisible = false);
    }
    try {
      switch (layout) {
        case _WindowLayout.ball:
          await windowManager.setSize(
            _compactWindowSize(_settings.value.ballSize),
          );
          await windowManager.setPosition(_ballPosition);
          break;
        case _WindowLayout.blinkReminder:
          final reminderSize = _blinkReminderWindowSize(
            _settings.value.ballSize,
          );
          await windowManager.setSize(reminderSize);
          await windowManager.setPosition(_ballPosition);
          await _nudgeIntoScreen(reminderSize);
          break;
        case _WindowLayout.menu:
          await _cacheCurrentPosition();
          final menuSize = _menuWindowSize(_settings.value.ballSize);
          await windowManager.setSize(menuSize);
          await windowManager.setPosition(_ballPosition);
          await _nudgeIntoScreen(menuSize);
          break;
        case _WindowLayout.settings:
          await windowManager.setSize(_settingsWindowSize);
          await windowManager.center();
          break;
        case _WindowLayout.osdi:
          await windowManager.setSize(_osdiWindowSize);
          await windowManager.center();
          break;
        case _WindowLayout.breakOverlay:
          final display = await screenRetriever.getPrimaryDisplay();
          final size = display.visibleSize ?? display.size;
          final pos = display.visiblePosition ?? Offset.zero;
          await windowManager.setBounds(pos & size);
          break;
        case _WindowLayout.gentleBreak:
          // Cartão pequeno no canto superior direito, sem cobrir a tela.
          final display = await screenRetriever.getPrimaryDisplay();
          final screen = display.visibleSize ?? display.size;
          final origin = display.visiblePosition ?? Offset.zero;
          await windowManager.setSize(_gentleWindowSize);
          await windowManager.setPosition(
            Offset(
              origin.dx + screen.width - _gentleWindowSize.width - 16,
              origin.dy + 16,
            ),
          );
          break;
        case _WindowLayout.inactivity:
          // Aviso compacto no canto superior direito, sem cobrir a tela.
          final display = await screenRetriever.getPrimaryDisplay();
          final screen = display.visibleSize ?? display.size;
          final origin = display.visiblePosition ?? Offset.zero;
          await windowManager.setSize(_inactivityWindowSize);
          await windowManager.setPosition(
            Offset(
              origin.dx + screen.width - _inactivityWindowSize.width - 16,
              origin.dy + 16,
            ),
          );
          break;
      }
      await windowManager.setAlwaysOnTop(true);
      // Reafirma a presença em Spaces de tela cheia após mudanças de layout
      // (redimensionar/reposicionar pode reordenar a janela).
      if (Platform.isMacOS) {
        await windowManager.setVisibleOnAllWorkspaces(
          true,
          visibleOnFullScreen: true,
        );
      }
    } catch (e) {
      debugPrint('Falha ao aplicar layout $layout: $e');
    }
  }

  Future<void> _nudgeIntoScreen(Size windowSize) async {
    try {
      final display = await screenRetriever.getPrimaryDisplay();
      final screen = display.visibleSize ?? display.size;
      final origin = display.visiblePosition ?? Offset.zero;
      var x = _ballPosition.dx;
      var y = _ballPosition.dy;
      x = x.clamp(origin.dx, origin.dx + screen.width - windowSize.width);
      y = y.clamp(origin.dy, origin.dy + screen.height - windowSize.height);
      await windowManager.setPosition(Offset(x, y));
    } catch (_) {
      /* ignora */
    }
  }

  // --- Interações da bolinha ---------------------------------------------

  void _onBallTap() {
    if (_timer.state != AppState.idle) return;
    setState(() => _menuOpen = !_menuOpen);
    _applyLayout(_menuOpen ? _WindowLayout.menu : _WindowLayout.ball);
  }

  /// Botão direito: abre o menu de opções (não alterna — sempre abre).
  void _onBallSecondaryTap() {
    if (_timer.state != AppState.idle || _menuOpen) return;
    setState(() => _menuOpen = true);
    _applyLayout(_WindowLayout.menu);
  }

  Future<void> _onBallDragStart() async {
    if (_timer.state != AppState.idle || _menuOpen) return;
    await windowManager.startDragging();
  }

  Future<void> _onBallDragEnd() async {
    try {
      final pos = await windowManager.getPosition();
      _ballPosition = pos;
      if (mounted) {
        await context.read<StorageService>().saveBallPosition(pos.dx, pos.dy);
      }
    } catch (_) {
      /* ignora */
    }
  }

  void _closeMenu() {
    if (!_menuOpen) return;
    setState(() => _menuOpen = false);
    _applyLayout(_WindowLayout.ball);
  }

  void _openSettings() {
    setState(() {
      _menuOpen = false;
      _settingsOpen = true;
      _aboutOpen = false;
      _guidanceOpen = false;
      _updateOpen = false;
      _osdiOpen = false;
      _screenTimeOpen = false;
      _healthDashboardOpen = false;
    });
    _applyLayout(_WindowLayout.settings);
  }

  void _openAbout() {
    setState(() {
      _menuOpen = false;
      _settingsOpen = false;
      _aboutOpen = true;
      _guidanceOpen = false;
      _updateOpen = false;
      _osdiOpen = false;
      _screenTimeOpen = false;
      _healthDashboardOpen = false;
    });
    _applyLayout(_WindowLayout.settings);
  }

  void _closeAbout() {
    setState(() => _aboutOpen = false);
    _restoreAfterPanel();
  }

  void _closeSettings() {
    setState(() => _settingsOpen = false);
    _restoreAfterPanel();
  }

  void _openGuidance() {
    setState(() {
      _menuOpen = false;
      _settingsOpen = false;
      _aboutOpen = false;
      _guidanceOpen = true;
      _updateOpen = false;
      _osdiOpen = false;
      _screenTimeOpen = false;
      _healthDashboardOpen = false;
    });
    _applyLayout(_WindowLayout.settings);
  }

  void _closeGuidance() {
    setState(() => _guidanceOpen = false);
    _restoreAfterPanel();
  }

  void _openOsdi() {
    final storage = context.read<StorageService>();
    setState(() {
      _menuOpen = false;
      _settingsOpen = false;
      _aboutOpen = false;
      _guidanceOpen = false;
      _updateOpen = false;
      _osdiOpen = true;
      _osdiHistory = storage.loadOsdiHistory();
      _screenTimeOpen = false;
      _healthDashboardOpen = false;
    });
    _applyLayout(_WindowLayout.osdi);
  }

  void _closeOsdi() {
    setState(() => _osdiOpen = false);
    _restoreAfterPanel();
  }

  void _openScreenTime() {
    setState(() {
      _menuOpen = false;
      _settingsOpen = false;
      _aboutOpen = false;
      _guidanceOpen = false;
      _updateOpen = false;
      _osdiOpen = false;
      _screenTimeOpen = true;
      _healthDashboardOpen = false;
    });
    _applyLayout(_WindowLayout.osdi);
  }

  void _closeScreenTime() {
    setState(() => _screenTimeOpen = false);
    _restoreAfterPanel();
  }

  void _openHealthDashboard() {
    setState(() {
      _menuOpen = false;
      _settingsOpen = false;
      _aboutOpen = false;
      _guidanceOpen = false;
      _updateOpen = false;
      _osdiOpen = false;
      _screenTimeOpen = false;
      _healthDashboardOpen = true;
    });
    _applyLayout(_WindowLayout.osdi);
  }

  void _closeHealthDashboard() {
    setState(() => _healthDashboardOpen = false);
    _restoreAfterPanel();
  }

  Future<void> _clearScreenTime() async {
    await context.read<ScreenTimeService>().clear();
  }

  void _saveOsdi(OsdiAssessment assessment) {
    unawaited(_persistOsdiAssessment(assessment));
  }

  Future<void> _persistOsdiAssessment(OsdiAssessment assessment) async {
    final storage = context.read<StorageService>();
    await storage.addOsdiAssessment(assessment);
    if (!mounted) return;
    setState(() => _osdiHistory = storage.loadOsdiHistory());
  }

  // --- Verificação de atualização ----------------------------------------

  Future<void> _openCheckUpdates() async {
    setState(() {
      _menuOpen = false;
      _settingsOpen = false;
      _aboutOpen = false;
      _guidanceOpen = false;
      _updateOpen = true;
      _osdiOpen = false;
      _screenTimeOpen = false;
      _healthDashboardOpen = false;
      _updateResult = null;
    });
    await _applyLayout(_WindowLayout.settings);
    final result = await _updater.check();
    if (mounted && _updateOpen) {
      setState(() => _updateResult = result);
    }
  }

  void _closeUpdate() {
    setState(() => _updateOpen = false);
    _restoreAfterPanel();
  }

  /// Volta ao layout compacto após fechar um painel, respeitando o estado de
  /// widget desabilitado e um eventual aviso de colírio ainda ativo.
  void _restoreAfterPanel() {
    if (_timer.eyeDropsAlert) {
      _applyLayout(_WindowLayout.settings);
      return;
    }
    if (_timer.inactivityAlert && !_timer.state.isActive) {
      _applyLayout(_WindowLayout.inactivity);
      return;
    }
    if (!_widgetEnabled && !_timer.state.isActive) {
      windowManager.hide();
    } else {
      _applyLayout(_WindowLayout.ball);
    }
  }

  Future<void> _quit() async => windowManager.close();

  // --- Build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<TimerProvider>();
    final provider = context.watch<SettingsProvider>();
    final settings = provider.value;
    final strings = provider.strings;

    Widget body;
    if (_osdiOpen) {
      body = Center(
        child: OsdiDialog(
          strings: strings,
          history: _osdiHistory,
          onSave: _saveOsdi,
          onClose: _closeOsdi,
        ),
      );
    } else if (_screenTimeOpen) {
      body = Center(
        child: Consumer<ScreenTimeService>(
          builder: (_, screenTime, _) => ScreenTimeDialog(
            strings: strings,
            data: screenTime.data,
            trackingEnabled: settings.screenTimeTracking,
            onClose: _closeScreenTime,
            onClear: _clearScreenTime,
          ),
        ),
      );
    } else if (_healthDashboardOpen) {
      body = Center(
        child: HealthDashboardDialog(
          strings: strings,
          onClose: _closeHealthDashboard,
        ),
      );
    } else if (_updateOpen) {
      body = UpdateDialog(
        strings: strings,
        result: _updateResult,
        onClose: _closeUpdate,
        onDownload: () {
          _updater.openReleasesPage();
          _closeUpdate();
        },
      );
    } else if (_settingsOpen) {
      body = _buildSettings();
    } else if (_aboutOpen) {
      body = Center(
        child: AboutPanel(strings: strings, onClose: _closeAbout),
      );
    } else if (_guidanceOpen) {
      body = Center(
        child: GuidanceDialog(strings: strings, onClose: _closeGuidance),
      );
    } else if (timer.eyeDropsAlert) {
      body = EyeDropsReminder(strings: strings, onDone: _timer.dismissEyeDrops);
    } else if (timer.state.isActive) {
      body = settings.usesFullScreenBreak
          ? _buildBreakOverlay(timer, settings, strings)
          : GentleBreakCard(
              state: timer.state,
              strings: strings,
              secondsRemaining: timer.phaseRemaining,
              totalSeconds: timer.phaseSeconds,
            );
    } else if (timer.inactivityAlert) {
      body = InactivityPauseCard(
        strings: strings,
        onResume: _timer.resumeFromInactivity,
      );
    } else {
      body = _buildCompact(timer, settings, strings);
    }

    return Scaffold(backgroundColor: Colors.transparent, body: body);
  }

  FloatingBall _ball({
    required bool isActive,
    required WidgetSettings s,
    bool interactive = true,
    double progress = 0.0,
    bool blinkReminderVisible = false,
    String blinkReminderText = '',
  }) {
    return FloatingBall(
      isActive: isActive,
      size: s.ballSize,
      idleColor: s.idleColorValue,
      alertColor: s.alertColorValue,
      idleOpacity: s.idleOpacity,
      blinkDuration: s.blinkDuration,
      showProgress: s.showProgressRing,
      progress: progress,
      dynamicOrbEffect: s.dynamicOrbEffect,
      hoverReactiveBall: s.hoverReactiveBall,
      orbIntensity: s.orbIntensity,
      blinkReminderVisible: blinkReminderVisible,
      blinkReminderText: blinkReminderText,
      onTap: interactive ? _onBallTap : null,
      onSecondaryTap: interactive ? _onBallSecondaryTap : null,
      onDragStart: interactive ? _onBallDragStart : null,
      onDragEnd: interactive ? _onBallDragEnd : null,
    );
  }

  Widget _buildCompact(
    TimerProvider timer,
    WidgetSettings settings,
    AppStrings strings,
  ) {
    if (!_menuOpen) {
      return Center(
        child: _ball(
          isActive: timer.state.isActive,
          s: settings,
          progress: timer.cycleProgress,
          blinkReminderVisible: _blinkReminderVisible,
          blinkReminderText: strings.blinkReminderText,
        ),
      );
    }
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _closeMenu,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ball(isActive: false, s: settings),
              const SizedBox(height: 8),
              FloatingMenu(
                strings: strings,
                isPaused: timer.isPaused,
                onStartNow: timer.startBreakNow,
                onReset: timer.reset,
                onTogglePause: timer.togglePause,
                onGuidance: _openGuidance,
                onOsdi: _openOsdi,
                onScreenTime: _openScreenTime,
                onHealthDashboard: _openHealthDashboard,
                onCheckUpdates: _openCheckUpdates,
                onGitHub: _openGithub,
                onAbout: _openAbout,
                onSettings: _openSettings,
                onQuit: _quit,
                onDismiss: _closeMenu,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBreakOverlay(
    TimerProvider timer,
    WidgetSettings settings,
    AppStrings strings,
  ) {
    return Stack(
      children: [
        if (settings.dimBackground)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: settings.dimOpacity),
            ),
          ),
        Positioned(
          top: 24,
          right: 24,
          child: _ball(isActive: true, s: settings, interactive: false),
        ),
        Positioned.fill(
          child: GlassOverlay(
            state: timer.state,
            strings: strings,
            secondsRemaining: timer.phaseRemaining,
            fillOpacity: settings.overlayOpacity,
            blur: settings.overlayBlur,
          ),
        ),
      ],
    );
  }

  Widget _buildSettings() {
    final settings = context.read<SettingsProvider>();
    final startup = context.read<StartupService>();
    final timer = context.read<TimerProvider>();
    return Center(
      child: SettingsDialog(
        initial: settings.value,
        onSave: (next) async {
          final loginChanged =
              next.launchAtLogin != settings.value.launchAtLogin;
          await settings.update(next);
          if (loginChanged) await startup.setEnabled(next.launchAtLogin);
        },
        onReset: () async {
          await startup.setEnabled(false);
          await settings.reset();
          _closeSettings();
        },
        onResetLearning: timer.resetInactivityLearning,
        onOpenScreenTime: () {
          setState(() => _settingsOpen = false);
          _openScreenTime();
        },
        onClose: _closeSettings,
      ),
    );
  }
}
