import 'package:shared_preferences/shared_preferences.dart';

import '../models/break_stats_data.dart';
import '../models/environment_checklist.dart';
import '../models/osdi_assessment.dart';
import '../models/screen_time_data.dart';
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

  // --- Tempo de tela ------------------------------------------------------

  ScreenTimeData loadScreenTime() =>
      ScreenTimeData.fromJson(_prefs.getString(StorageKeys.screenTime));

  Future<void> saveScreenTime(ScreenTimeData data) =>
      _prefs.setString(StorageKeys.screenTime, data.toJson());

  // --- Estatísticas de pausas visuais ------------------------------------

  BreakStatsData loadBreakStats() =>
      BreakStatsData.fromJson(_prefs.getString(StorageKeys.breakStats));

  Future<void> saveBreakStats(BreakStatsData data) =>
      _prefs.setString(StorageKeys.breakStats, data.toJson());

  /// Registra a emissão de um aviso de pausa para o dia [now].
  Future<void> recordBreakReminder([DateTime? now]) async {
    final moment = now ?? DateTime.now();
    final updated = loadBreakStats().incremented(moment, reminders: 1);
    await saveBreakStats(updated.pruned(moment));
  }

  /// Registra a conclusão de uma pausa para o dia [now].
  Future<void> recordBreakCompleted([DateTime? now]) async {
    final moment = now ?? DateTime.now();
    final updated = loadBreakStats().incremented(moment, completed: 1);
    await saveBreakStats(updated.pruned(moment));
  }

  /// Apaga todo o histórico de pausas (usado pelo "limpar dados").
  Future<void> clearBreakStats() => _prefs.remove(StorageKeys.breakStats);

  // --- Checklist ambiental ------------------------------------------------

  EnvironmentChecklist? loadEnvironmentChecklist() =>
      EnvironmentChecklist.fromJson(
        _prefs.getString(StorageKeys.environmentChecklist),
      );

  Future<void> saveEnvironmentChecklist(EnvironmentChecklist checklist) =>
      _prefs.setString(
        StorageKeys.environmentChecklist,
        checklist.toJson(),
      );

  Future<void> clearEnvironmentChecklist() =>
      _prefs.remove(StorageKeys.environmentChecklist);
}
