import 'package:flutter_test/flutter_test.dart';
import 'package:dry_eye_widget/providers/settings_provider.dart';
import 'package:dry_eye_widget/models/widget_settings.dart';
import 'package:dry_eye_widget/services/storage_service.dart';
import 'package:dry_eye_widget/models/osdi_assessment.dart';
import 'package:dry_eye_widget/models/screen_time_data.dart';

void main() {
  group('SettingsProvider', () {
    test('update() normalizes settings, notifies listeners, and persists', () async {
      final storage = _MemoryStorage(WidgetSettings.defaults());
      final provider = SettingsProvider(storage: storage);

      int notifyCount = 0;
      provider.addListener(() {
        notifyCount++;
      });

      // An unnormalized setting, e.g. cycleMinutes = -5 (should clamp to 1)
      final unnormalized = WidgetSettings.defaults().copyWith(cycleMinutes: -5, phaseSeconds: 999);

      await provider.update(unnormalized);

      // Normalization should clamp cycleMinutes to 1 and phaseSeconds to 120
      expect(provider.value.cycleMinutes, 1);
      expect(provider.value.phaseSeconds, 120);

      // Should notify listeners
      expect(notifyCount, 1);

      // Should persist the normalized settings
      final savedSettings = storage.loadSettings();
      expect(savedSettings.cycleMinutes, 1);
      expect(savedSettings.phaseSeconds, 120);
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
  List<OsdiAssessment> loadOsdiHistory() => const [];

  @override
  Future<void> saveOsdiHistory(List<OsdiAssessment> history) async {}

  @override
  Future<void> addOsdiAssessment(OsdiAssessment assessment) async {}

  ScreenTimeData _screenTime = ScreenTimeData.empty();

  @override
  ScreenTimeData loadScreenTime() => _screenTime;

  @override
  Future<void> saveScreenTime(ScreenTimeData data) async {
    _screenTime = data;
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
