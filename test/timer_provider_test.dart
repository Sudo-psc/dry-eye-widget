import 'package:dry_eye_widget/models/app_state.dart';
import 'package:dry_eye_widget/models/break_stats_data.dart';
import 'package:dry_eye_widget/models/environment_checklist.dart';
import 'package:dry_eye_widget/models/widget_settings.dart';
import 'package:dry_eye_widget/models/screen_time_data.dart';
import 'package:dry_eye_widget/providers/settings_provider.dart';
import 'package:dry_eye_widget/providers/timer_provider.dart';
import 'package:dry_eye_widget/services/audio_service.dart';
import 'package:dry_eye_widget/services/fullscreen_service.dart';
import 'package:dry_eye_widget/services/idle_service.dart';
import 'package:dry_eye_widget/services/notification_service.dart';
import 'package:dry_eye_widget/services/screen_time_service.dart';
import 'package:dry_eye_widget/services/presence/adaptive_threshold_model.dart';
import 'package:dry_eye_widget/services/presence/presence_controller.dart';
import 'package:dry_eye_widget/services/storage_service.dart';
import 'package:dry_eye_widget/utils/constants.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TimerProvider', () {
    test(
      'sincroniza som e notificações quando as configurações mudam',
      () async {
        final storage = _MemoryStorage(
          WidgetSettings.defaults().copyWith(
            soundEnabled: false,
            notificationsEnabled: false,
          ),
        );
        final settings = SettingsProvider(storage: storage);
        final audio = _FakeAudioService()
          ..enabled = settings.value.soundEnabled;
        final notifications = _FakeNotificationService()
          ..enabled = settings.value.notificationsEnabled;

        final timer = TimerProvider(
          settings: settings,
          storage: storage,
          audio: audio,
          notifications: notifications,
          presence: PresenceController(
            model: AdaptiveThresholdModel(),
            idleSource: _FakeIdleService().idleSeconds,
          ),
        );
        addTearDown(timer.dispose);

        expect(audio.enabled, isFalse);
        expect(notifications.enabled, isFalse);

        await settings.update(
          settings.value.copyWith(
            soundEnabled: true,
            notificationsEnabled: true,
          ),
        );

        expect(audio.enabled, isTrue);
        expect(notifications.enabled, isTrue);
      },
    );

    test(
      'em tela cheia com notificacoes desligadas, forca a notificacao de pausa',
      () {
        fakeAsync((async) {
          final storage = _MemoryStorage(
            WidgetSettings.defaults().copyWith(
              soundEnabled: false,
              notificationsEnabled: false,
              pauseOnInactivity: false,
            ),
          );
          final settings = SettingsProvider(storage: storage);
          final notifications = _FakeNotificationService()..enabled = false;
          final timer = TimerProvider(
            settings: settings,
            storage: storage,
            audio: _FakeAudioService(),
            notifications: notifications,
            presence: PresenceController(
              model: AdaptiveThresholdModel(),
              idleSource: _FakeIdleService().idleSeconds,
            ),
            fullscreen: _FakeFullscreen(true),
          );
          addTearDown(timer.dispose);
          timer.start();

          // Avança até o fim do ciclo: entra em ALERTA e dispara o aviso.
          async.elapse(Duration(seconds: timer.cycleSeconds + 1));
          async.flushMicrotasks();

          expect(notifications.forcedCount, greaterThan(0));
        });
      },
    );

    test(
      'sem tela cheia e notificacoes desligadas, nao notifica a pausa',
      () {
        fakeAsync((async) {
          final storage = _MemoryStorage(
            WidgetSettings.defaults().copyWith(
              soundEnabled: false,
              notificationsEnabled: false,
              pauseOnInactivity: false,
            ),
          );
          final settings = SettingsProvider(storage: storage);
          final notifications = _FakeNotificationService()..enabled = false;
          final timer = TimerProvider(
            settings: settings,
            storage: storage,
            audio: _FakeAudioService(),
            notifications: notifications,
            presence: PresenceController(
              model: AdaptiveThresholdModel(),
              idleSource: _FakeIdleService().idleSeconds,
            ),
            fullscreen: _FakeFullscreen(false),
          );
          addTearDown(timer.dispose);
          timer.start();

          async.elapse(Duration(seconds: timer.cycleSeconds + 1));
          async.flushMicrotasks();

          expect(notifications.showCount, 0);
        });
      },
    );

    test(
      'pausa o ciclo apos inatividade do sistema e retoma com a atividade',
      () {
        fakeAsync((async) {
          final storage = _MemoryStorage(
            WidgetSettings.defaults().copyWith(pauseOnInactivity: true),
          );
          final settings = SettingsProvider(storage: storage);
          final idle = _MutableIdleService(0);
          final timer = TimerProvider(
            settings: settings,
            storage: storage,
            audio: _FakeAudioService(),
            notifications: _FakeNotificationService(),
            presence: PresenceController(
              model: AdaptiveThresholdModel(),
              idleSource: idle.idleSeconds,
            ),
          );
          addTearDown(timer.dispose);
          timer.start();

          // Sistema ativo: o ciclo avança normalmente.
          async.elapse(const Duration(seconds: 4));
          expect(timer.cycleElapsed, greaterThan(0));
          expect(timer.inactivityAlert, isFalse);

          // Inatividade acima do limiar: a deteccao pausa o ciclo.
          idle.value = (AppDefaults.inactivitySeconds + 10).toDouble();
          async.elapse(const Duration(seconds: 8));
          expect(timer.inactivityAlert, isTrue);
          final pausedAt = timer.cycleElapsed;

          // Enquanto inativo, o ciclo nao avança.
          async.elapse(const Duration(seconds: 6));
          expect(timer.cycleElapsed, pausedAt);

          // Atividade retomada: o ciclo volta a avançar.
          idle.value = 0;
          async.elapse(const Duration(seconds: 8));
          expect(timer.inactivityAlert, isFalse);
          expect(timer.cycleElapsed, greaterThan(pausedAt));
        });
      },
    );

    test('com pauseOnInactivity desligado, a inatividade nao pausa', () {
      fakeAsync((async) {
        final storage = _MemoryStorage(
          WidgetSettings.defaults().copyWith(pauseOnInactivity: false),
        );
        final settings = SettingsProvider(storage: storage);
        final idle = _MutableIdleService(
          (AppDefaults.inactivitySeconds + 60).toDouble(),
        );
        final timer = TimerProvider(
          settings: settings,
          storage: storage,
          audio: _FakeAudioService(),
          notifications: _FakeNotificationService(),
          presence: PresenceController(
            model: AdaptiveThresholdModel(),
            idleSource: idle.idleSeconds,
          ),
        );
        addTearDown(timer.dispose);
        timer.start();

        async.elapse(const Duration(seconds: 10));
        expect(timer.inactivityAlert, isFalse);
        expect(timer.cycleElapsed, greaterThan(0));
      });
    });

    test('histerese: continua pausado entre os limiares, retoma so em <=5', () {
      fakeAsync((async) {
        final storage = _MemoryStorage(
          WidgetSettings.defaults().copyWith(pauseOnInactivity: true),
        );
        final settings = SettingsProvider(storage: storage);
        final idle = _MutableIdleService(0);
        final timer = TimerProvider(
          settings: settings,
          storage: storage,
          audio: _FakeAudioService(),
          notifications: _FakeNotificationService(),
          presence: PresenceController(
            model: AdaptiveThresholdModel(),
            idleSource: idle.idleSeconds,
          ),
        );
        addTearDown(timer.dispose);
        timer.start();

        // Acima do limiar de entrada: pausa.
        idle.value = (AppDefaults.inactivitySeconds + 5).toDouble();
        async.elapse(const Duration(seconds: 8));
        expect(timer.inactivityAlert, isTrue);

        // Entre o limiar de retomada e o de entrada: permanece pausado.
        idle.value = 40;
        async.elapse(const Duration(seconds: 8));
        expect(timer.inactivityAlert, isTrue);

        // No limiar de retomada (<=5): retoma.
        idle.value = AppDefaults.inactivityResumeSeconds.toDouble();
        async.elapse(const Duration(seconds: 8));
        expect(timer.inactivityAlert, isFalse);
      });
    });

    test(
      'coleta tempo de tela quando ativo e descarta a inatividade',
      () {
        fakeAsync((async) {
          final storage = _MemoryStorage(
            WidgetSettings.defaults().copyWith(
              pauseOnInactivity: true,
              screenTimeTracking: true,
            ),
          );
          final settings = SettingsProvider(storage: storage);
          final screenTime = ScreenTimeService(storage: storage);
          final idle = _MutableIdleService(0);
          final timer = TimerProvider(
            settings: settings,
            storage: storage,
            audio: _FakeAudioService(),
            notifications: _FakeNotificationService(),
            presence: PresenceController(
              model: AdaptiveThresholdModel(),
              idleSource: idle.idleSeconds,
            ),
            screenTime: screenTime,
          );
          addTearDown(timer.dispose);
          timer.start();

          // Ativo: o tempo de tela acumula.
          async.elapse(const Duration(seconds: 5));
          final active = screenTime.data.secondsForDay(DateTime.now());
          expect(active, greaterThan(0));

          // Inativo acima do limiar: a coleta praticamente para.
          idle.value = (AppDefaults.inactivitySeconds + 10).toDouble();
          async.elapse(const Duration(seconds: 10));
          final afterIdle = screenTime.data.secondsForDay(DateTime.now());
          expect(afterIdle, lessThan(active + 10));
        });
      },
    );

    test('com a coleta desligada, o tempo de tela nao acumula', () {
      fakeAsync((async) {
        final storage = _MemoryStorage(
          WidgetSettings.defaults().copyWith(screenTimeTracking: false),
        );
        final settings = SettingsProvider(storage: storage);
        final screenTime = ScreenTimeService(storage: storage);
        final timer = TimerProvider(
          settings: settings,
          storage: storage,
          audio: _FakeAudioService(),
          notifications: _FakeNotificationService(),
          presence: PresenceController(
            model: AdaptiveThresholdModel(),
            idleSource: _FakeIdleService().idleSeconds,
          ),
          screenTime: screenTime,
        );
        addTearDown(timer.dispose);
        timer.start();

        async.elapse(const Duration(seconds: 10));
        expect(screenTime.data.secondsForDay(DateTime.now()), 0);
      });
    });

    test('resumeFromInactivity limpa so a pausa por inatividade', () {
      fakeAsync((async) {
        final storage = _MemoryStorage(
          WidgetSettings.defaults().copyWith(pauseOnInactivity: true),
        );
        final settings = SettingsProvider(storage: storage);
        final idle = _MutableIdleService(
          (AppDefaults.inactivitySeconds + 30).toDouble(),
        );
        final timer = TimerProvider(
          settings: settings,
          storage: storage,
          audio: _FakeAudioService(),
          notifications: _FakeNotificationService(),
          presence: PresenceController(
            model: AdaptiveThresholdModel(),
            idleSource: idle.idleSeconds,
          ),
        );
        addTearDown(timer.dispose);
        timer.start();

        // Pausa manual e pausa por inatividade coexistem.
        timer.togglePause();
        async.elapse(const Duration(seconds: 8));
        expect(timer.inactivityAlert, isTrue);
        expect(timer.isPaused, isTrue);

        // Retomada manual da inatividade nao mexe na pausa manual.
        timer.resumeFromInactivity();
        expect(timer.inactivityAlert, isFalse);
        expect(timer.isPaused, isTrue);
      });
    });
  });
}

class _MemoryStorage implements StorageService {
  _MemoryStorage(this._settings);

  WidgetSettings _settings;
  int _elapsedSeconds = 0;
  int _eyeDropsElapsed = 0;
  double? _ballX;
  double? _ballY;

  String? _dockEdge;

  @override
  String? loadDockEdge() => _dockEdge;

  @override
  Future<void> saveDockEdge(String? edgeId) async {
    _dockEdge = edgeId;
  }

  @override
  double? get ballX => _ballX;

  @override
  double? get ballY => _ballY;

  @override
  int get elapsedSeconds => _elapsedSeconds;

  @override
  int get eyeDropsElapsed => _eyeDropsElapsed;

  @override
  WidgetSettings loadSettings() => _settings;

  @override
  Future<void> saveBallPosition(double x, double y) async {
    _ballX = x;
    _ballY = y;
  }

  @override
  Future<void> saveSettings(WidgetSettings settings) async {
    _settings = settings;
  }

  ScreenTimeData _screenTime = ScreenTimeData.empty();

  @override
  ScreenTimeData loadScreenTime() => _screenTime;

  @override
  Future<void> saveScreenTime(ScreenTimeData data) async {
    _screenTime = data;
  }

  BreakStatsData _breakStats = BreakStatsData.empty();

  @override
  BreakStatsData loadBreakStats() => _breakStats;

  @override
  Future<void> saveBreakStats(BreakStatsData data) async {
    _breakStats = data;
  }

  @override
  Future<void> recordBreakReminder([DateTime? now]) async {
    _breakStats = _breakStats.incremented(now ?? DateTime.now(), reminders: 1);
  }

  @override
  Future<void> recordBreakCompleted([DateTime? now]) async {
    _breakStats = _breakStats.incremented(now ?? DateTime.now(), completed: 1);
  }

  @override
  Future<void> clearBreakStats() async {
    _breakStats = BreakStatsData.empty();
  }

  EnvironmentChecklist? _environment;

  @override
  EnvironmentChecklist? loadEnvironmentChecklist() => _environment;

  @override
  Future<void> saveEnvironmentChecklist(EnvironmentChecklist checklist) async {
    _environment = checklist;
  }

  @override
  Future<void> clearEnvironmentChecklist() async {
    _environment = null;
  }

  @override
  Future<void> setElapsedSeconds(int value) async {
    _elapsedSeconds = value;
  }

  @override
  Future<void> setEyeDropsElapsed(int value) async {
    _eyeDropsElapsed = value;
  }
}

class _FakeAudioService implements AudioService {
  @override
  bool enabled = true;

  @override
  void dispose() {}

  @override
  Future<void> playAlert() async {}

  @override
  Future<void> playSuccess() async {}

  @override
  Future<void> playTick() async {}

  @override
  Future<void> playBlinkReminder({
    required BlinkReminderSound sound,
    required double volume,
  }) async {}
}

class _FakeNotificationService implements NotificationService {
  @override
  bool enabled = true;

  int showCount = 0;
  int forcedCount = 0;

  @override
  Future<void> init() async {}

  @override
  Future<void> notifyBreakDone(String title, String body) async {}

  @override
  Future<void> notifyBreakStart(String title, String body) async {}

  @override
  Future<void> show(String title, String body, {bool force = false}) async {
    showCount++;
    if (force) forcedCount++;
  }

  @override
  Future<void> showForced(String title, String body) =>
      show(title, body, force: true);
}

class _FakeFullscreen extends FullscreenService {
  _FakeFullscreen(this.value);
  bool value;

  @override
  Future<bool> isFrontmostFullscreen() async => value;
}

class _FakeIdleService implements IdleService {
  @override
  Future<double> idleSeconds() async => 0;
}

class _MutableIdleService implements IdleService {
  _MutableIdleService(this.value);

  double value;

  @override
  Future<double> idleSeconds() async => value;
}
