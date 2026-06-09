import 'package:dry_eye_widget/models/widget_settings.dart';
import 'package:dry_eye_widget/providers/settings_provider.dart';
import 'package:dry_eye_widget/providers/timer_provider.dart';
import 'package:dry_eye_widget/services/audio_service.dart';
import 'package:dry_eye_widget/services/idle_service.dart';
import 'package:dry_eye_widget/services/notification_service.dart';
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
}

class _FakeNotificationService implements NotificationService {
  @override
  bool enabled = true;

  @override
  Future<void> init() async {}

  @override
  Future<void> notifyBreakDone(String title, String body) async {}

  @override
  Future<void> notifyBreakStart(String title, String body) async {}

  @override
  Future<void> show(String title, String body) async {}
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
