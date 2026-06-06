import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_state.dart';
import '../services/audio_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import 'settings_provider.dart';

/// Gerencia toda a temporização e a máquina de estados do app.
///
/// Usa [Timer.periodic] de 1 segundo, independente da UI, para que o ciclo
/// continue mesmo com a janela minimizada. As durações e flags de som vêm do
/// [SettingsProvider], lidas dinamicamente — então mudar uma configuração tem
/// efeito imediato no próximo tick.
class TimerProvider extends ChangeNotifier {
  TimerProvider({
    required SettingsProvider settings,
    required StorageService storage,
    required AudioService audio,
    required NotificationService notifications,
  })  : _settings = settings,
        _storage = storage,
        _audio = audio,
        _notifications = notifications {
    _cycleElapsed = storage.elapsedSeconds.clamp(0, cycleSeconds);
  }

  final SettingsProvider _settings;
  final StorageService _storage;
  final AudioService _audio;
  final NotificationService _notifications;

  Timer? _ticker;

  // --- Estado público -----------------------------------------------------

  AppState _state = AppState.idle;
  AppState get state => _state;

  int _cycleElapsed = 0;
  int get cycleElapsed => _cycleElapsed;

  int _phaseRemaining = 0;
  int get phaseRemaining => _phaseRemaining;

  bool _paused = false;
  bool get isPaused => _paused;

  // --- Configurações derivadas (lidas do SettingsProvider) ----------------

  int get cycleSeconds => _settings.value.cycleSeconds;
  int get phaseSeconds => _settings.value.phaseSeconds;
  bool get _soundOn => _settings.value.soundEnabled;
  bool get _notifyOn => _settings.value.notificationsEnabled;

  double get cycleProgress =>
      cycleSeconds == 0 ? 0 : (_cycleElapsed / cycleSeconds).clamp(0.0, 1.0);

  // --- Ciclo de vida ------------------------------------------------------

  void start() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    notifyListeners();
  }

  void _onTick() {
    switch (_state) {
      case AppState.idle:
        _tickIdle();
        break;
      case AppState.fase1:
        _tickPhase();
        break;
      case AppState.alerta:
      case AppState.conclusao:
        break;
    }
  }

  // --- IDLE ---------------------------------------------------------------

  void _tickIdle() {
    if (_paused) return;
    _cycleElapsed++;
    if (_cycleElapsed % 5 == 0) {
      _storage.setElapsedSeconds(_cycleElapsed);
    }
    if (_cycleElapsed >= cycleSeconds) {
      _enterAlerta();
    }
    notifyListeners();
  }

  // --- ALERTA -------------------------------------------------------------

  void _enterAlerta() {
    _state = AppState.alerta;
    _cycleElapsed = 0;
    _storage.setElapsedSeconds(0);
    if (_soundOn) _audio.playAlert();
    if (_notifyOn) _notifications.notifyBreakStart();
    notifyListeners();

    Timer(const Duration(milliseconds: 1500), () {
      if (_state == AppState.alerta) _enterPhase1();
    });
  }

  // --- FASE única ---------------------------------------------------------

  void _enterPhase1() {
    _state = AppState.fase1;
    _phaseRemaining = phaseSeconds;
    notifyListeners();
  }

  void _tickPhase() {
    _phaseRemaining--;
    if (_phaseRemaining > 0 && _soundOn) {
      _audio.playTick();
    }
    if (_phaseRemaining <= 0) {
      _enterConclusao();
    }
    notifyListeners();
  }

  // --- CONCLUSAO ----------------------------------------------------------

  void _enterConclusao() {
    _state = AppState.conclusao;
    if (_soundOn) _audio.playSuccess();
    if (_notifyOn) _notifications.notifyBreakDone();
    notifyListeners();

    Timer(AppDurations.completion, () {
      if (_state == AppState.conclusao) _returnToIdle();
    });
  }

  void _returnToIdle() {
    _state = AppState.idle;
    _cycleElapsed = 0;
    _phaseRemaining = 0;
    _storage.setElapsedSeconds(0);
    notifyListeners();
  }

  // --- Ações do menu ------------------------------------------------------

  void startBreakNow() {
    if (_state == AppState.idle) {
      _enterAlerta();
    }
  }

  void reset() {
    _state = AppState.idle;
    _cycleElapsed = 0;
    _phaseRemaining = 0;
    _paused = false;
    _storage.setElapsedSeconds(0);
    notifyListeners();
  }

  void togglePause() {
    _paused = !_paused;
    notifyListeners();
  }

  /// Reajusta o tempo decorrido caso o ciclo configurado tenha encolhido.
  void clampElapsedToCycle() {
    if (_cycleElapsed > cycleSeconds) {
      _cycleElapsed = cycleSeconds;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
