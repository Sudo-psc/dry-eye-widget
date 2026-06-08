import 'package:dry_eye_widget/models/widget_settings.dart';
import 'package:dry_eye_widget/providers/settings_provider.dart';
import 'package:dry_eye_widget/providers/timer_provider.dart';
import 'package:dry_eye_widget/services/audio_service.dart';
import 'package:dry_eye_widget/services/idle_service.dart';
import 'package:dry_eye_widget/services/notification_service.dart';
import 'package:dry_eye_widget/services/storage_service.dart';
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
          idle: _FakeIdleService(),
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
