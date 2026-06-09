import 'package:shared_preferences/shared_preferences.dart';

import '../models/osdi_assessment.dart';
import '../models/widget_settings.dart';
import '../utils/constants.dart';

/// Camada de persistência sobre [SharedPreferences].
///
/// Guarda a posição da bolinha, o tempo decorrido (para retomar após
/// reiniciar) e o bloco de [WidgetSettings] serializado em JSON.
class StorageService {
  StorageService._(this._prefs);

  final SharedPreferences _prefs;

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService._(prefs);
  }

  // --- Posição da bolinha -------------------------------------------------

  double? get ballX => _prefs.getDouble(StorageKeys.ballX);
  double? get ballY => _prefs.getDouble(StorageKeys.ballY);

  Future<void> saveBallPosition(double x, double y) async {
    await _prefs.setDouble(StorageKeys.ballX, x);
    await _prefs.setDouble(StorageKeys.ballY, y);
  }

  // --- Tempo decorrido (retomada) ----------------------------------------

  int get elapsedSeconds => _prefs.getInt(StorageKeys.elapsedSeconds) ?? 0;

  Future<void> setElapsedSeconds(int value) =>
      _prefs.setInt(StorageKeys.elapsedSeconds, value);

  int get eyeDropsElapsed => _prefs.getInt(StorageKeys.eyeDropsElapsed) ?? 0;

  Future<void> setEyeDropsElapsed(int value) =>
      _prefs.setInt(StorageKeys.eyeDropsElapsed, value);

  // --- Configurações do widget -------------------------------------------

  WidgetSettings loadSettings() {
    final raw = _prefs.getString(StorageKeys.widgetSettings);
    if (raw == null) return WidgetSettings.defaults();
    return WidgetSettings.fromJson(raw);
  }

  Future<void> saveSettings(WidgetSettings settings) =>
      _prefs.setString(StorageKeys.widgetSettings, settings.toJson());

  // --- Histórico OSDI -----------------------------------------------------

  List<OsdiAssessment> loadOsdiHistory() =>
      OsdiAssessment.decodeHistory(_prefs.getString(StorageKeys.osdiHistory));

  Future<void> saveOsdiHistory(List<OsdiAssessment> history) async {
    final sorted = [...history]
      ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
    final trimmed = sorted.length <= OsdiAssessment.maxHistoryLength
        ? sorted
        : sorted.sublist(sorted.length - OsdiAssessment.maxHistoryLength);
    await _prefs.setString(
      StorageKeys.osdiHistory,
      OsdiAssessment.encodeHistory(trimmed),
    );
  }

  Future<void> addOsdiAssessment(OsdiAssessment assessment) async {
    final history = [...loadOsdiHistory(), assessment];
    await saveOsdiHistory(history);
  }
}
