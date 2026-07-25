import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:provider/provider.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'app/window_layout.dart';
import 'l10n/app_strings.dart';
import 'l10n/feature_strings.dart';
import 'models/app_state.dart';
import 'models/break_stats_data.dart';
import 'models/widget_settings.dart';
import 'providers/settings_provider.dart';
import 'providers/timer_provider.dart';
import 'services/audio_service.dart';
import 'services/dock_icon_service.dart';
import 'services/dvrs_storage_service.dart';
import 'services/idle_service.dart';
import 'services/notification_service.dart';
import 'services/activity_monitor_service.dart';
import 'services/activity_stats_service.dart';
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
import 'ui/app_theme.dart';
import 'utils/constants.dart';
import 'utils/edge_snap.dart';
import 'utils/orb_motion.dart';
import 'widgets/about_panel.dart';
import 'widgets/dvrs/dvrs_screen.dart';
import 'widgets/eye_drops_reminder.dart';
import 'services/daily_insight.dart';
import 'widgets/floating_ball.dart';
import 'widgets/floating_menu.dart';
import 'widgets/gentle_break_card.dart';
import 'widgets/glass_overlay.dart';
import 'widgets/guidance_dialog.dart';
import 'widgets/health/health_hub_screen.dart';
import 'widgets/inactivity_pause_card.dart';
import 'widgets/onboarding/onboarding_flow.dart';
import 'widgets/privacy/my_data_panel.dart';
import 'widgets/report_dialog.dart';
import 'widgets/screen_time_dialog.dart';
import 'widgets/settings_dialog.dart';
import 'widgets/update_dialog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Window.initialize();
  await windowManager.ensureInitialized();

  final storage = await StorageService.init();
  final dvrsStorage = await DvrsStorageService.init();
  final settings = SettingsProvider(storage: storage);
  // Primeira execução: adota o idioma do SO antes de qualquer texto ser
  // montado (bandeja, notificações, janela).
  await settings.applySystemLanguageOnFirstRun();
  final screenTime = ScreenTimeService(storage: storage);
  final activityStats = ActivityStatsService(
    storage: storage,
    monitor: const ActivityMonitorService(),
  );
  if (settings.value.activityMonitorEnabled) {
    unawaited(activityStats.start());
  }
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

  final initialSize = WindowSizes.compact(settings.value.ballSize);
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

  // Só depois de a janela existir: no macOS a política de ativação aplicada
  // durante a subida do app é ignorada e o ícone fica no Dock.
  final dockIcon = const DockIconService();
  final dockSettled = await dockIcon.applyWithRetry(settings.value.hideDockIcon);
  if (dockSettled != null && dockSettled != settings.value.hideDockIcon) {
    // O sistema recusou a troca: a preferência passa a refletir a realidade em
    // vez de mostrar um estado que o Dock não tem.
    await settings.update(
      settings.value.copyWith(hideDockIcon: dockSettled),
    );
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        Provider<DvrsStorageService>.value(value: dvrsStorage),
        Provider<AudioService>.value(value: audio),
        Provider<NotificationService>.value(value: notifications),
        Provider<StartupService>.value(value: startup),
        Provider<TrayService>.value(value: tray),
        Provider<DockIconService>.value(value: dockIcon),
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ChangeNotifierProvider<ScreenTimeService>.value(value: screenTime),
        ChangeNotifierProvider<ActivityStatsService>.value(
          value: activityStats,
        ),
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
      theme: buildAppTheme(),
      // Aplica escala de UI e densidade (acessibilidade) a toda a árvore.
      // Lê do SettingsProvider e reage a mudanças em tempo real.
      builder: (context, child) {
        final settings = context.watch<SettingsProvider>().value;
        final media = MediaQuery.of(context);
        final themed = Theme.of(
          context,
        ).copyWith(visualDensity: settings.uiDensity.visualDensity);
        return Theme(
          data: themed,
          child: MediaQuery(
            data: media.copyWith(
              textScaler: TextScaler.linear(settings.uiScale),
            ),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: const HomePage(),
    );
  }
}

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
  late final DockIconService _dockIcon;
  late final NotificationService _notifications;

  bool _menuOpen = false;
  bool _settingsOpen = false;
  bool _aboutOpen = false;
  bool _guidanceOpen = false;
  bool _updateOpen = false;
  bool _dvrsOpen = false;
  bool _screenTimeOpen = false;
  bool _reportOpen = false;
  bool _healthHubOpen = false;
  bool _myDataOpen = false;
  bool _onboardingOpen = false;
  bool _returnToDvrsAfterReport = false;
  int _healthHubTab = 0;
  bool _wasActive = false;
  int _currentStreak = 0;
  String _completionInsight = '';
  bool _wasDrops = false;
  bool _wasInactive = false;
  bool _blinkReminderVisible = false;
  Timer? _blinkReminderTicker;
  Timer? _blinkReminderHideTimer;
  Timer? _blinkReminderQuietTimer;
  DateTime? _blinkRemindersQuietUntil;
  int _ballReleaseGeneration = 0;
  Future<void> _layoutQueue = Future<void>.value();
  final FocusNode _orbFocusNode = FocusNode(debugLabel: 'floating-orb-control');

  final UpdateService _updater = UpdateService();
  UpdateResult? _updateResult;

  /// Widget habilitado = bolinha visível. Quando desabilitado (pela opção
  /// nas configurações ou pelo item da barra de menu), a janela é escondida
  /// — mas o ciclo e o ícone da barra de menu continuam.
  bool _widgetEnabled = true;

  Offset _ballPosition = const Offset(100, 100);
  CompactWindowAnchor? _compactWindowAnchor;
  MenuWindowPlacement? _menuPlacement;

  /// A janela já terminou de crescer para o tamanho do menu. Enquanto for
  /// `false`, o menu não é pintado — ele apareceria cortado dentro da janela
  /// compacta. Vale apenas junto de [_menuOpen] e é rearmado a cada abertura.
  bool _menuReady = false;

  /// Borda em que a bolinha está encaixada (meia-lua); `null` = solta.
  BallDockEdge? _dockEdge;
  double _lastBallSize = AppDefaults.ballSize;
  bool _lastDockHidden = AppDefaults.hideDockIcon;
  bool _lastHideMenuBar = AppDefaults.hideMenuBarItem;
  bool _lastHideFloating = AppDefaults.hideFloatingWidget;
  bool _lastActivityMonitor = AppDefaults.activityMonitorEnabled;
  String _lastLanguage = AppDefaults.languageCode;
  BlinkReminderFrequency _lastBlinkFrequency = BlinkReminderFrequency.normal;

  @override
  void initState() {
    super.initState();
    _timer = context.read<TimerProvider>();
    _settings = context.read<SettingsProvider>();
    _dockEdge = ballDockEdgeFromId(
      context.read<StorageService>().loadDockEdge(),
    );
    _audio = context.read<AudioService>();
    _notifications = context.read<NotificationService>();
    _tray = context.read<TrayService>();
    _dockIcon = context.read<DockIconService>();
    _lastBallSize = _settings.value.ballSize;
    _lastDockHidden = _settings.value.hideDockIcon;
    _lastHideMenuBar = _settings.value.hideMenuBarItem;
    _lastHideFloating = _settings.value.hideFloatingWidget;
    _lastLanguage = _settings.value.languageCode;
    _lastBlinkFrequency = _settings.value.blinkReminderFrequency;
    _widgetEnabled = !_settings.value.hideFloatingWidget;

    // Inicializa a posicao com o valor salvo para evitar salto para (100, 100).
    final storage = context.read<StorageService>();
    final quietUntil = storage.loadBlinkRemindersQuietUntil();
    if (quietUntil != null && quietUntil.isAfter(DateTime.now())) {
      _blinkRemindersQuietUntil = quietUntil;
    } else if (quietUntil != null) {
      unawaited(storage.saveBlinkRemindersQuietUntil(null));
    }
    final savedX = storage.ballX;
    final savedY = storage.ballY;
    if (savedX != null && savedY != null) {
      _ballPosition = Offset(savedX, savedY);
    }

    _timer.addListener(_onStateChanged);
    _settings.addListener(_onSettingsChanged);
    trayManager.addListener(this);
    _startBlinkReminderLoop();
    // Com posição salva, o storage é a fonte de verdade (já aplicada no
    // bootstrap). Sem posição salva (primeira execução), captura o canto
    // inicial aplicado no bootstrap. Não sobrescrever a posição salva com
    // getPosition evita saltos no startup.
    if (savedX == null || savedY == null) {
      _cacheCurrentPosition();
    }
    if (_dockEdge != null && _widgetEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_applyLayout(WindowLayout.ball));
      });
    }
    // Aplica o estado inicial de visibilidade da bolinha após o primeiro frame.
    if (!_widgetEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => windowManager.hide());
    }
    // Primeira execução: exibe o onboarding de boas-vindas por cima de tudo.
    if (!_settings.value.onboardingComplete) {
      _onboardingOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await windowManager.show();
        await _applyLayout(WindowLayout.onboarding);
      });
    } else {
      // Após o onboarding: no máximo um nudge suave de reavaliação do DVRS/dia.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_maybeNotifyDvrsNudge());
      });
    }
  }

  /// Notificação local opt-in se o DVRS estiver vencido (1x por dia).
  Future<void> _maybeNotifyDvrsNudge() async {
    final settings = _settings.value;
    if (!settings.dvrsReminderEnabled || !settings.notificationsEnabled) {
      return;
    }
    final storage = context.read<StorageService>();
    final dvrs = context.read<DvrsStorageService>();
    final now = DateTime.now();
    final dayKey = BreakStatsData.dayKey(now);
    if (storage.loadDvrsNudgeNotifiedDay() == dayKey) return;

    final due = DailyInsightEngine.isDvrsNudgeDue(
      now: now,
      enabled: settings.dvrsReminderEnabled,
      lastDvrsAt: dvrs.getLatestDvrsResult()?.createdAt,
      snoozedUntil: storage.loadDvrsNudgeSnoozedUntil(),
      intervalDays: AppDefaults.dvrsReminderDays,
      totalCompletedBreaks: storage.loadBreakStats().totalCompleted,
    );
    if (!due) return;

    final s = _settings.strings;
    await _notifications.show(s.notifyDvrsNudgeTitle, s.notifyDvrsNudgeBody);
    await storage.saveDvrsNudgeNotifiedDay(dayKey);
  }

  Future<void> _snoozeDvrsNudge() async {
    final storage = context.read<StorageService>();
    await storage.saveDvrsNudgeSnoozedUntil(
      DailyInsightEngine.snoozeUntil(DateTime.now()),
    );
  }

  /// Conclui (ou pula) o onboarding: persiste a flag e abre o Resumo do dia
  /// para o usuário descobrir o hub de saúde logo na primeira execução.
  Future<void> _finishOnboarding(WidgetSettings draft) async {
    await _settings.update(draft.copyWith(onboardingComplete: true));
    if (!mounted) return;
    setState(() => _onboardingOpen = false);
    // Descoberta do hub: um toque a mais no dia 1 vale mais que o menu denso.
    _openDaySummary();
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
    _cancelBallRelease();
    _timer.removeListener(_onStateChanged);
    _settings.removeListener(_onSettingsChanged);
    trayManager.removeListener(this);
    _blinkReminderTicker?.cancel();
    _blinkReminderHideTimer?.cancel();
    _blinkReminderQuietTimer?.cancel();
    _orbFocusNode.dispose();
    // Libera os players de áudio (regra 20-20-20 + piscada). O TimerProvider,
    // disposto em seguida pelo provider, não toca som no teardown.
    _audio.dispose();
    super.dispose();
  }

  void _startBlinkReminderLoop() {
    _blinkReminderTicker?.cancel();
    if (_blinkRemindersAreQuiet) {
      _scheduleBlinkReminderQuietExpiry();
      return;
    }
    final intervalMs = _settings.value.blinkReminderFrequency.intervalMs;
    _blinkReminderTicker = Timer.periodic(Duration(milliseconds: intervalMs), (
      _,
    ) {
      if (_canTriggerBlinkReminder) {
        unawaited(_triggerBlinkReminder());
      } else if (_blinkReminderVisible) {
        _hideBlinkReminder(restoreLayout: true);
      }
    });
  }

  bool get _canTriggerBlinkReminder =>
      mounted &&
      !_blinkRemindersAreQuiet &&
      _isBlinkReminderContextFree &&
      (_canShowVisualBlinkReminder ||
          _settings.value.blinkReminderSoundEnabled);

  bool get _isBlinkReminderContextFree =>
      !_menuOpen &&
      !_settingsOpen &&
      !_aboutOpen &&
      !_guidanceOpen &&
      !_updateOpen &&
      !_dvrsOpen &&
      !_screenTimeOpen &&
      !_reportOpen &&
      !_healthHubOpen &&
      !_myDataOpen &&
      !_onboardingOpen &&
      !_timer.eyeDropsAlert &&
      !_timer.inactivityAlert &&
      !_timer.isPaused &&
      _timer.state == AppState.idle;

  bool get _canShowVisualBlinkReminder =>
      _settings.value.visualBlinkRemindersEnabled && _widgetEnabled;

  bool get _blinkRemindersAreQuiet {
    final until = _blinkRemindersQuietUntil;
    return until != null && DateTime.now().isBefore(until);
  }

  void _scheduleBlinkReminderQuietExpiry() {
    _blinkReminderQuietTimer?.cancel();
    final until = _blinkRemindersQuietUntil;
    if (until == null) return;
    final remaining = until.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      unawaited(_resumeBlinkReminders());
      return;
    }
    _blinkReminderQuietTimer = Timer(remaining, () {
      unawaited(_resumeBlinkReminders());
    });
  }

  Future<void> _quietBlinkReminders(Duration duration) async {
    if (duration <= Duration.zero) return;
    final until = DateTime.now().add(duration);
    _blinkReminderTicker?.cancel();
    _hideBlinkReminder(restoreLayout: true);
    if (mounted) {
      setState(() => _blinkRemindersQuietUntil = until);
    } else {
      _blinkRemindersQuietUntil = until;
    }
    await context.read<StorageService>().saveBlinkRemindersQuietUntil(until);
    _scheduleBlinkReminderQuietExpiry();
  }

  Future<void> _resumeBlinkReminders() async {
    _blinkReminderQuietTimer?.cancel();
    _blinkReminderQuietTimer = null;
    if (mounted) {
      setState(() => _blinkRemindersQuietUntil = null);
    } else {
      _blinkRemindersQuietUntil = null;
    }
    await context.read<StorageService>().saveBlinkRemindersQuietUntil(null);
    if (mounted) _startBlinkReminderLoop();
  }

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
    // A janela cresce ANTES de a pílula aparecer: revelada primeiro, ela seria
    // pintada dentro da janela compacta e apareceria cortada por alguns
    // quadros. Encaixada (meia-lua) não há pílula expandida — só o brilho na
    // bolinha —, então a janela permanece do tamanho compacto.
    if (_dockEdge == null) {
      await _applyLayout(WindowLayout.blinkReminder);
      if (!mounted || _blinkReminderVisible) return;
    }
    setState(() => _blinkReminderVisible = true);
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
      unawaited(_applyLayout(WindowLayout.ball));
    }
  }

  bool get _isCompactLayoutFree =>
      _widgetEnabled &&
      !_menuOpen &&
      !_settingsOpen &&
      !_aboutOpen &&
      !_guidanceOpen &&
      !_updateOpen &&
      !_dvrsOpen &&
      !_screenTimeOpen &&
      !_reportOpen &&
      !_healthHubOpen &&
      !_myDataOpen &&
      !_onboardingOpen &&
      !_timer.eyeDropsAlert &&
      !_timer.inactivityAlert &&
      _timer.state == AppState.idle;

  void _onStateChanged() {
    // Streak + insight na conclusão (só na transição, não a cada tick).
    if (_timer.state == AppState.conclusao && _wasActive) {
      final storage = context.read<StorageService>();
      final stats = storage.loadBreakStats();
      final now = DateTime.now();
      _currentStreak = stats.currentStreak(now);
      final lastDvrs = context.read<DvrsStorageService>().getLatestDvrsResult();
      final nudge = DailyInsightEngine.isDvrsNudgeDue(
        now: now,
        enabled: _settings.value.dvrsReminderEnabled,
        lastDvrsAt: lastDvrs?.createdAt,
        snoozedUntil: storage.loadDvrsNudgeSnoozedUntil(),
        intervalDays: AppDefaults.dvrsReminderDays,
        totalCompletedBreaks: stats.totalCompleted,
      );
      _completionInsight = DailyInsightEngine.buildInsight(
        strings: _settings.strings,
        stats: stats,
        now: now,
        lastDvrsAt: lastDvrs?.createdAt,
        dvrsNudgeDue: nudge,
      ).message;
    }
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
          !_dvrsOpen &&
          !_screenTimeOpen &&
          !_reportOpen &&
          !_healthHubOpen &&
          !_myDataOpen &&
          !_onboardingOpen) {
        () async {
          if (!_widgetEnabled) await windowManager.show();
          if (!mounted) return;
          await _applyLayout(WindowLayout.settings);
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
          !_dvrsOpen &&
          !_screenTimeOpen &&
          !_reportOpen &&
          !_healthHubOpen &&
          !_myDataOpen &&
          !_onboardingOpen) {
        () async {
          if (!_widgetEnabled) await windowManager.show();
          if (!mounted) return;
          await _applyLayout(WindowLayout.inactivity);
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
      case TrayService.keyDaySummary:
        _openDaySummaryFromTray();
        break;
      case TrayService.keyDvrs:
        _openDvrsFromTray();
        break;
      case TrayService.keyReports:
        _openReportFromTray();
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
      await _applyLayout(WindowLayout.ball);
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

  Future<void> _openDaySummaryFromTray() async {
    if (!_widgetEnabled) await windowManager.show();
    _openDaySummary();
  }

  Future<void> _openDvrsFromTray() async {
    if (!_widgetEnabled) await windowManager.show();
    _openDvrs();
  }

  Future<void> _openReportFromTray() async {
    if (!_widgetEnabled) await windowManager.show();
    _openReport();
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

  /// Aplica a preferência do ícone do Dock e confere o que o sistema aceitou.
  ///
  /// O AppKit pode recusar a troca de política de ativação. Sem conferir, a
  /// configuração ficaria dizendo o contrário do estado real e só tentaria de
  /// novo se o usuário mexesse no botão. Quando nem a segunda tentativa passa,
  /// a preferência volta para o estado que o sistema realmente tem.
  Future<void> _applyDockIcon(bool hidden) async {
    final settled = await _dockIcon.applyWithRetry(
      hidden,
      // Preferência mudou de novo no meio do caminho: o pedido novo é que vale.
      isStale: () => _settings.value.hideDockIcon != hidden,
    );
    if (settled == null || settled == hidden) return;
    if (!mounted || _settings.value.hideDockIcon != hidden) return;
    debugPrint('Dock: sistema recusou hideDockIcon=$hidden; mantendo $settled.');
    _lastDockHidden = settled;
    await _settings.update(_settings.value.copyWith(hideDockIcon: settled));
  }

  /// Reage a mudanças de configuração: se o tamanho da bolinha mudou e
  /// estamos em modo compacto, redimensiona a janela na hora.
  void _onSettingsChanged() {
    final newSize = _settings.value.ballSize;
    if (newSize != _lastBallSize) {
      _lastBallSize = newSize;
      _timer.clampElapsedToCycle();
      if (!_menuOpen && !_settingsOpen && !_timer.state.isActive) {
        _applyLayout(WindowLayout.ball);
      }
    }
    if (!_settings.value.edgeSnap && _dockEdge != null) {
      unawaited(_undock());
    }
    final hideDock = _settings.value.hideDockIcon;
    if (hideDock != _lastDockHidden) {
      _lastDockHidden = hideDock;
      unawaited(_applyDockIcon(hideDock));
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
    final blinkFreq = _settings.value.blinkReminderFrequency;
    if (blinkFreq != _lastBlinkFrequency) {
      _lastBlinkFrequency = blinkFreq;
      _startBlinkReminderLoop();
    }
    final activityOn = _settings.value.activityMonitorEnabled;
    if (activityOn != _lastActivityMonitor) {
      _lastActivityMonitor = activityOn;
      final svc = context.read<ActivityStatsService>();
      if (activityOn) {
        unawaited(svc.start());
      } else {
        unawaited(svc.stop());
      }
    }
  }

  // --- Layout da janela ---------------------------------------------------

  Future<void> _enterBreakLayout() async {
    if (mounted) {
      setState(() {
        _menuOpen = false;
        _settingsOpen = false;
        _aboutOpen = false;
        _reportOpen = false;
        _healthHubOpen = false;
        _myDataOpen = false;
      });
    }
    // A pausa aparece mesmo se o widget estiver desabilitado (a janela pode
    // estar escondida); garantimos que ela volte a ser exibida.
    if (!_widgetEnabled) await windowManager.show();
    // [_ballPosition] é a coordenada canônica compacta. Nunca captura aqui a
    // janela nativa atual: a pausa pode começar com Settings/DVRS/Hub aberto,
    // e gravar a posição centralizada faria a bolinha voltar no lugar errado.
    await _applyLayout(
      _settings.value.usesFullScreenBreak
          ? WindowLayout.breakOverlay
          : WindowLayout.gentleBreak,
    );
  }

  Future<void> _exitBreakLayout() async {
    // Restaura o layout correto após a pausa 20-20-20 — incluindo o aviso de
    // inatividade, caso o ciclo tenha sido pausado por ociosidade nesse meio.
    _restoreAfterPanel();
  }

  Future<void> _applyLayout(WindowLayout layout) {
    final next = _layoutQueue.then((_) => _performLayout(layout));
    _layoutQueue = next;
    return next;
  }

  Future<void> _performLayout(WindowLayout layout) async {
    _cancelBallRelease();
    if (layout != WindowLayout.ball && layout != WindowLayout.onboarding) {
      _compactWindowAnchor ??= CompactWindowAnchor(_ballPosition);
    }
    if (layout != WindowLayout.blinkReminder && _blinkReminderVisible) {
      _blinkReminderHideTimer?.cancel();
      _blinkReminderHideTimer = null;
      if (mounted) setState(() => _blinkReminderVisible = false);
    }
    try {
      switch (layout) {
        case WindowLayout.ball:
          final ballSize = WindowSizes.compact(_settings.value.ballSize);
          await windowManager.setSize(ballSize);
          final docked = await _dockedPositionForCurrentScreen(ballSize);
          final anchor = _compactWindowAnchor;
          final pos = docked ?? anchor?.position ?? _ballPosition;
          await windowManager.setPosition(pos);
          _ballPosition = docked ?? anchor?.position ?? _ballPosition;
          _compactWindowAnchor = null;
          break;
        case WindowLayout.blinkReminder:
          final reminderSize = WindowSizes.blinkReminder(
            _settings.value.ballSize,
          );
          await windowManager.setSize(reminderSize);
          await windowManager.setPosition(_ballPosition);
          await _nudgeIntoScreen(
            reminderSize,
            anchor: CompactWindowAnchor(_ballPosition),
          );
          break;
        case WindowLayout.menu:
          final anchor =
              _compactWindowAnchor ?? CompactWindowAnchor(_ballPosition);
          _compactWindowAnchor = anchor;
          final ballSize = _settings.value.ballSize;
          final compactSize = WindowSizes.compact(ballSize);
          final menuSize = WindowSizes.menu(_settings.value.ballSize);
          final screen = await _screenForWindow(anchor.position, compactSize);
          final placement = placeMenuWindow(
            anchor: anchor,
            compactSize: compactSize,
            ballSize: ballSize,
            menuSize: menuSize,
            screen: screen,
          );
          // A janela cresce primeiro; só então o menu é liberado para pintar.
          // Publicá-lo antes o espremia na janela compacta por alguns quadros.
          try {
            await windowManager.setSize(menuSize);
            await windowManager.setPosition(placement.windowPosition);
          } finally {
            if (mounted && _menuOpen) {
              setState(() {
                _menuPlacement = placement;
                _menuReady = true;
              });
            }
          }
          break;
        case WindowLayout.settings:
          await windowManager.setSize(WindowSizes.settings);
          await windowManager.center();
          break;
        case WindowLayout.dvrs:
        case WindowLayout.report:
        case WindowLayout.dashboard:
        case WindowLayout.progress:
        case WindowLayout.daySummary:
        case WindowLayout.healthHub:
        case WindowLayout.myData:
          await windowManager.setSize(WindowSizes.panel);
          await windowManager.center();
          break;
        case WindowLayout.onboarding:
          await windowManager.setSize(WindowSizes.onboarding);
          await windowManager.center();
          break;
        case WindowLayout.breakOverlay:
          final display = await screenRetriever.getPrimaryDisplay();
          final size = display.visibleSize ?? display.size;
          final pos = display.visiblePosition ?? Offset.zero;
          await windowManager.setBounds(pos & size);
          break;
        case WindowLayout.gentleBreak:
          // Cartão pequeno no canto superior direito, sem cobrir a tela.
          final display = await screenRetriever.getPrimaryDisplay();
          final screen = display.visibleSize ?? display.size;
          final origin = display.visiblePosition ?? Offset.zero;
          await windowManager.setSize(WindowSizes.gentleBreak);
          await windowManager.setPosition(
            Offset(
              origin.dx + screen.width - WindowSizes.gentleBreak.width - 16,
              origin.dy + 16,
            ),
          );
          break;
        case WindowLayout.inactivity:
          // Aviso compacto no canto superior direito, sem cobrir a tela.
          final display = await screenRetriever.getPrimaryDisplay();
          final screen = display.visibleSize ?? display.size;
          final origin = display.visiblePosition ?? Offset.zero;
          await windowManager.setSize(WindowSizes.inactivity);
          await windowManager.setPosition(
            Offset(
              origin.dx + screen.width - WindowSizes.inactivity.width - 16,
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

  Future<void> _nudgeIntoScreen(
    Size windowSize, {
    required CompactWindowAnchor anchor,
  }) async {
    try {
      final compactSize = WindowSizes.compact(_settings.value.ballSize);
      final screen = await _screenForWindow(anchor.position, compactSize);
      // Reposiciona apenas a janela transitória (lembrete/menu, que são
      // maiores) para caber na tela. NÃO grava em [_ballPosition]: a posição
      // canônica da bolinha só muda por arraste do usuário ou no startup —
      // caso contrário, o encaixe da janela maior empurraria a bolinha para
      // dentro a cada lembrete de piscada (a cada 7,5s), fazendo-a "andar".
      await windowManager.setPosition(anchor.fitWindow(windowSize, screen));
    } catch (_) {
      /* ignora */
    }
  }

  Future<Offset?> _dockedPositionForCurrentScreen(Size windowSize) async {
    final edge = _dockEdge;
    if (edge == null) return null;
    final screen = await _screenForWindow(_ballPosition, windowSize);
    return dockedWindowPosition(
      edge: edge,
      windowPos: _ballPosition,
      windowSize: windowSize,
      screen: screen,
    );
  }

  Future<Rect> _screenForWindow(Offset position, Size windowSize) async {
    try {
      final displays = await screenRetriever.getAllDisplays();
      final screens = displays
          .map(
            (display) =>
                (display.visiblePosition ?? Offset.zero) &
                (display.visibleSize ?? display.size),
          )
          .toList(growable: false);
      if (screens.isNotEmpty) {
        return closestScreenForWindow(
          windowPosition: position,
          windowSize: windowSize,
          screens: screens,
        );
      }
    } catch (e) {
      debugPrint('Falha ao selecionar monitor da janela: $e');
    }

    final primary = await screenRetriever.getPrimaryDisplay();
    return (primary.visiblePosition ?? Offset.zero) &
        (primary.visibleSize ?? primary.size);
  }

  // --- Interações da bolinha ---------------------------------------------

  void _onBallTap() {
    if (_timer.state != AppState.idle) return;
    // Encaixada na borda: o primeiro clique apenas solta a bolinha.
    if (_dockEdge != null) {
      unawaited(_undock());
      return;
    }
    final opening = !_menuOpen;
    if (opening) {
      _compactWindowAnchor ??= CompactWindowAnchor(_ballPosition);
    }
    setState(() {
      _menuOpen = opening;
      if (opening) {
        _menuPlacement = null;
        _menuReady = false;
      }
    });
    unawaited(_applyLayout(_menuOpen ? WindowLayout.menu : WindowLayout.ball));
  }

  /// Botão direito: atalho para o Resumo do dia (descoberta do hub de saúde).
  void _onBallSecondaryTap() {
    if (_timer.state != AppState.idle) return;
    if (_menuOpen) setState(() => _menuOpen = false);
    _openDaySummary();
  }

  Future<void> _onBallDragStart() async {
    if (_timer.state != AppState.idle || _menuOpen) return;
    _cancelBallRelease();
    if (_dockEdge != null) await _undock();
    await windowManager.startDragging();
  }

  void _cancelBallRelease() => _ballReleaseGeneration++;

  Future<void> _onBallDragEnd(Offset velocity) async {
    if (_timer.state != AppState.idle || _menuOpen) return;
    try {
      final reduceMotion =
          MediaQuery.maybeOf(context)?.disableAnimations == true;
      final storage = context.read<StorageService>();
      final start = await windowManager.getPosition();
      final winSize = await windowManager.getSize();
      final screen = await _screenForWindow(start, winSize);
      final plan = planOrbRelease(
        start: start,
        velocity: velocity,
        windowSize: winSize,
        screen: screen,
        edgeSnapEnabled: _settings.value.edgeSnap,
        dockThreshold: math.max(kDockThreshold, winSize.width * 0.72),
      );
      final generation = ++_ballReleaseGeneration;

      if (!reduceMotion && plan.velocity.distance >= 40) {
        final stopwatch = Stopwatch()..start();
        while (mounted && generation == _ballReleaseGeneration) {
          final t =
              stopwatch.elapsedMicroseconds /
              (plan.duration.inMicroseconds.toDouble());
          await windowManager.setPosition(orbReleasePosition(plan, t));
          if (t >= 1) break;
          await Future<void>.delayed(const Duration(milliseconds: 16));
        }
      }
      if (!mounted || generation != _ballReleaseGeneration) return;

      await windowManager.setPosition(plan.target);
      final edge = plan.dockEdge;
      if (edge != _dockEdge) {
        setState(() => _dockEdge = edge);
      }

      _ballPosition = plan.target;
      await storage.saveBallPosition(plan.target.dx, plan.target.dy);
      await storage.saveDockEdge(edge?.id);
    } catch (_) {
      /* ignora */
    }
  }

  /// Solta a bolinha da borda (clique na meia-lua) e afasta um pouco.
  Future<void> _undock() async {
    final edge = _dockEdge;
    if (edge == null) return;
    setState(() => _dockEdge = null);
    try {
      final pos = await windowManager.getPosition();
      final winSize = await windowManager.getSize();
      final screen = await _screenForWindow(pos, winSize);
      final x = edge == BallDockEdge.left
          ? screen.left + 18
          : screen.right - winSize.width - 18;
      final y = pos.dy.clamp(screen.top, screen.bottom - winSize.height);
      final next = Offset(x, y);
      await windowManager.setPosition(next);
      _ballPosition = next;
      if (mounted) {
        final storage = context.read<StorageService>();
        await storage.saveBallPosition(next.dx, next.dy);
        await storage.saveDockEdge(null);
      }
    } catch (_) {
      /* ignora */
    }
  }

  void _closeMenu() {
    if (!_menuOpen) return;
    setState(() {
      _menuOpen = false;
      _menuPlacement = null;
    });
    unawaited(_applyLayout(WindowLayout.ball));
  }

  void _openSettings() {
    setState(() {
      _menuOpen = false;
      _settingsOpen = true;
      _aboutOpen = false;
      _guidanceOpen = false;
      _updateOpen = false;
      _dvrsOpen = false;
      _screenTimeOpen = false;
      _reportOpen = false;
      _healthHubOpen = false;
      _myDataOpen = false;
    });
    _applyLayout(WindowLayout.settings);
  }

  void _openAbout() {
    setState(() {
      _menuOpen = false;
      _settingsOpen = false;
      _aboutOpen = true;
      _guidanceOpen = false;
      _updateOpen = false;
      _dvrsOpen = false;
      _screenTimeOpen = false;
      _reportOpen = false;
      _healthHubOpen = false;
      _myDataOpen = false;
    });
    _applyLayout(WindowLayout.settings);
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
      _dvrsOpen = false;
      _screenTimeOpen = false;
      _reportOpen = false;
      _healthHubOpen = false;
      _myDataOpen = false;
    });
    _applyLayout(WindowLayout.settings);
  }

  void _closeGuidance() {
    setState(() => _guidanceOpen = false);
    _restoreAfterPanel();
  }

  void _openDvrs() {
    setState(() {
      _menuOpen = false;
      _settingsOpen = false;
      _aboutOpen = false;
      _guidanceOpen = false;
      _updateOpen = false;
      _dvrsOpen = true;
      _screenTimeOpen = false;
      _reportOpen = false;
      _healthHubOpen = false;
      _myDataOpen = false;
      _returnToDvrsAfterReport = false;
    });
    _applyLayout(WindowLayout.dvrs);
  }

  void _closeDvrs() {
    setState(() => _dvrsOpen = false);
    _restoreAfterPanel();
  }

  void _openScreenTime() {
    setState(() {
      _menuOpen = false;
      _settingsOpen = false;
      _aboutOpen = false;
      _guidanceOpen = false;
      _updateOpen = false;
      _dvrsOpen = false;
      _screenTimeOpen = true;
      _reportOpen = false;
      _healthHubOpen = false;
      _myDataOpen = false;
    });
    _applyLayout(WindowLayout.dvrs);
  }

  void _closeScreenTime() {
    setState(() => _screenTimeOpen = false);
    _restoreAfterPanel();
  }

  /// Liga/desliga o monitoramento de atividade direto no diálogo de tempo de
  /// tela. Persiste a preferência; o start/stop do serviço é feito por
  /// [_onSettingsChanged].
  void _setActivityMonitor(bool enabled) {
    unawaited(
      _settings.update(
        _settings.value.copyWith(activityMonitorEnabled: enabled),
      ),
    );
  }

  void _openReport({bool returnToDvrs = false}) {
    setState(() {
      _menuOpen = false;
      _settingsOpen = false;
      _aboutOpen = false;
      _guidanceOpen = false;
      _updateOpen = false;
      _dvrsOpen = false;
      _screenTimeOpen = false;
      _reportOpen = true;
      _healthHubOpen = false;
      _myDataOpen = false;
      _returnToDvrsAfterReport = returnToDvrs;
    });
    _applyLayout(WindowLayout.report);
  }

  void _closeReport() {
    final returnToDvrs = _returnToDvrsAfterReport;
    setState(() {
      _reportOpen = false;
      _returnToDvrsAfterReport = false;
      if (returnToDvrs) {
        _dvrsOpen = true;
      }
    });
    if (returnToDvrs) {
      _applyLayout(WindowLayout.dvrs);
    } else {
      _restoreAfterPanel();
    }
  }

  void _closeAllPanelsFlags() {
    _menuOpen = false;
    _settingsOpen = false;
    _aboutOpen = false;
    _guidanceOpen = false;
    _updateOpen = false;
    _dvrsOpen = false;
    _screenTimeOpen = false;
    _reportOpen = false;
    _healthHubOpen = false;
    _myDataOpen = false;
  }

  void _openHealthHub() {
    setState(() {
      _closeAllPanelsFlags();
      _healthHubOpen = true;
      _healthHubTab = 0;
      _returnToDvrsAfterReport = false;
    });
    _applyLayout(WindowLayout.healthHub);
  }

  void _closeHealthHub() {
    setState(() {
      _healthHubOpen = false;
      _returnToDvrsAfterReport = false;
    });
    _restoreAfterPanel();
  }

  void _openMyData() {
    setState(() {
      _closeAllPanelsFlags();
      _myDataOpen = true;
    });
    _applyLayout(WindowLayout.myData);
  }

  void _closeMyData() {
    setState(() => _myDataOpen = false);
    _restoreAfterPanel();
  }

  /// Compat: resumo do dia / bandeja / onboarding abrem o hub unificado.
  void _openDaySummary() => _openHealthHub();

  Future<void> _clearScreenTime() async {
    await context.read<ScreenTimeService>().clear();
  }

  // --- Verificação de atualização ----------------------------------------

  Future<void> _openCheckUpdates() async {
    setState(() {
      _menuOpen = false;
      _settingsOpen = false;
      _aboutOpen = false;
      _guidanceOpen = false;
      _updateOpen = true;
      _dvrsOpen = false;
      _screenTimeOpen = false;
      _reportOpen = false;
      _healthHubOpen = false;
      _myDataOpen = false;
      _updateResult = null;
    });
    await _applyLayout(WindowLayout.settings);
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
      _applyLayout(WindowLayout.settings);
      return;
    }
    if (_timer.inactivityAlert && !_timer.state.isActive) {
      _applyLayout(WindowLayout.inactivity);
      return;
    }
    if (!_widgetEnabled && !_timer.state.isActive) {
      windowManager.hide();
    } else {
      _applyLayout(WindowLayout.ball);
    }
  }

  Future<void> _quit() async {
    final activityStats = context.read<ActivityStatsService>();
    final screenTime = context.read<ScreenTimeService>();
    try {
      await activityStats.stop();
      await screenTime.flush();
    } catch (e) {
      debugPrint('Falha ao persistir métricas antes de sair: $e');
    }
    await windowManager.close();
  }

  // --- Build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Painéis estáticos não devem reconstruir a cada tick de um segundo. O
    // TimerProvider fica observado apenas no ramo que realmente exibe estado,
    // contagem regressiva ou progresso do ciclo.
    final provider = context.watch<SettingsProvider>();
    final settings = provider.value;
    final strings = provider.strings;

    Widget body;
    if (_onboardingOpen) {
      body = Center(
        child: OnboardingFlow(
          strings: strings,
          initial: settings,
          onFinish: _finishOnboarding,
        ),
      );
    } else if (_dvrsOpen) {
      body = Center(
        child: DvrsScreen(
          onClose: _closeDvrs,
          onExportPdf: (_) async => _openReport(returnToDvrs: true),
        ),
      );
    } else if (_screenTimeOpen) {
      body = Center(
        child: Consumer2<ScreenTimeService, ActivityStatsService>(
          builder: (context, screenTime, activityStats, _) => ScreenTimeDialog(
            strings: strings,
            data: screenTime.data,
            trackingEnabled: settings.screenTimeTracking,
            activity: activityStats.data,
            activityEnabled: settings.activityMonitorEnabled,
            onToggleActivity: _setActivityMonitor,
            onClose: _closeScreenTime,
            onClear: _clearScreenTime,
          ),
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
    } else if (_reportOpen) {
      body = Center(child: ReportDialog(onClose: _closeReport));
    } else if (_healthHubOpen) {
      body = Center(
        child: HealthHubScreen(
          onClose: _closeHealthHub,
          initialTab: _healthHubTab,
          onTabChanged: (tab) => _healthHubTab = tab,
          onStartBreak: () {
            setState(() => _healthHubOpen = false);
            _timer.startBreakNow();
          },
          onSnoozeDvrsNudge: _snoozeDvrsNudge,
        ),
      );
    } else if (_myDataOpen) {
      body = Center(child: MyDataPanel(onClose: _closeMyData));
    } else if (_settingsOpen) {
      body = _buildSettings();
    } else if (_aboutOpen) {
      body = Center(
        child: AboutPanel(
          strings: strings,
          onClose: _closeAbout,
          onGitHub: _openGithub,
        ),
      );
    } else if (_guidanceOpen) {
      body = Center(
        child: GuidanceDialog(strings: strings, onClose: _closeGuidance),
      );
    } else {
      body = Consumer<TimerProvider>(
        builder: (context, liveTimer, _) =>
            _buildTimerSurface(liveTimer, settings, strings),
      );
    }

    return Scaffold(backgroundColor: Colors.transparent, body: body);
  }

  Widget _buildTimerSurface(
    TimerProvider timer,
    WidgetSettings settings,
    AppStrings strings,
  ) {
    if (timer.eyeDropsAlert) {
      return EyeDropsReminder(strings: strings, onDone: _timer.dismissEyeDrops);
    }
    if (timer.state.isActive) {
      return settings.usesFullScreenBreak
          ? _buildBreakOverlay(timer, settings, strings)
          : GentleBreakCard(
              state: timer.state,
              strings: strings,
              secondsRemaining: timer.phaseRemaining,
              totalSeconds: timer.phaseSeconds,
              completionInsight: _completionInsight,
            );
    }
    if (timer.inactivityAlert) {
      return InactivityPauseCard(
        strings: strings,
        onResume: _timer.resumeFromInactivity,
      );
    }
    return _buildCompact(timer, settings, strings);
  }

  FloatingBall _ball({
    required bool isActive,
    required WidgetSettings s,
    bool interactive = true,
    double progress = 0.0,
    bool blinkReminderVisible = false,
    String blinkReminderText = '',
    VoidCallback? onTap,
  }) {
    final draggable = interactive && !_menuOpen;
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
      dockEdge: interactive ? _dockEdge : null,
      semanticLabel: interactive
          ? AppStrings.of(_settings.value.languageCode).ballSemanticLabel
          : null,
      onTap: interactive ? (onTap ?? _onBallTap) : null,
      onSecondaryTap: interactive ? _onBallSecondaryTap : null,
      onDragStart: draggable ? _onBallDragStart : null,
      onDragEnd: draggable ? _onBallDragEnd : null,
    );
  }

  Widget _buildCompact(
    TimerProvider timer,
    WidgetSettings settings,
    AppStrings strings,
  ) {
    // Enquanto a janela não terminar de crescer, o menu não cabe: segue a
    // bolinha compacta em vez de pintar o painel cortado.
    if (!_menuOpen || !_menuReady) {
      final edge = timer.state.isActive ? null : _dockEdge;
      final ball = _ball(
        isActive: timer.state.isActive,
        s: settings,
        progress: timer.cycleProgress,
        blinkReminderVisible: _blinkReminderVisible,
        // Encaixada: sem pílula de texto (não cabe na borda) — só o brilho.
        blinkReminderText: edge == null ? strings.blinkReminderText : '',
      );
      return Center(child: ball);
    }
    final compactSize = WindowSizes.compact(settings.ballSize);
    final fallbackBallOffset = Offset(
      (compactSize.width - settings.ballSize) / 2,
      (compactSize.height - settings.ballSize) / 2,
    );
    final placement = _menuPlacement;
    final ballOffset = placement?.ballOffset ?? fallbackBallOffset;
    final panelTop = placement?.panelAbove == true
        ? ballOffset.dy - 8 - WindowSizes.menuPanelHeight
        : ballOffset.dy + settings.ballSize + 8;
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _closeMenu,
          ),
        ),
        Positioned(
          left: ballOffset.dx,
          top: ballOffset.dy,
          child: _ball(isActive: false, s: settings, onTap: _closeMenu),
        ),
        Positioned(
          left: 10,
          top: panelTop,
          child: FloatingMenu(
            strings: strings,
            healthHubLabel: FeatureStrings.of(
              settings.languageCode,
            ).menuHealthHub,
            myDataLabel: FeatureStrings.of(settings.languageCode).menuMyData,
            isPaused: timer.isPaused,
            onStartNow: timer.startBreakNow,
            onReset: timer.reset,
            onTogglePause: timer.togglePause,
            onExtendCycle: timer.stretchCycleOneHour,
            onGuidance: _openGuidance,
            onHealthHub: _openHealthHub,
            onMyData: _openMyData,
            onCheckUpdates: _openCheckUpdates,
            onAbout: _openAbout,
            onSettings: _openSettings,
            onQuit: _quit,
            blinkRemindersQuietUntil: _blinkRemindersQuietUntil,
            onQuietBlinkReminders: (duration) {
              if (duration == Duration.zero) {
                unawaited(_resumeBlinkReminders());
              } else {
                unawaited(_quietBlinkReminders(duration));
              }
            },
            onDismiss: _closeMenu,
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
            phaseTotalSeconds: timer.phaseSeconds,
            currentStreak: _currentStreak,
            completionInsight: _completionInsight,
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
