import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_state.dart';
import '../services/audio_service.dart';
import '../services/notification_service.dart';
import '../services/presence/presence_controller.dart';
import '../services/presence/presence_sensor.dart';
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
    required PresenceController presence,
  }) : this._(settings, storage, audio, notifications, presence);

  TimerProvider._(
    this._settings,
    this._storage,
    this._audio,
    this._notifications,
    this._presence,
  ) {
    _cycleElapsed = _storage.elapsedSeconds.clamp(0, cycleSeconds);
    _eyeDropsElapsed = _storage.eyeDropsElapsed;
    _syncServiceToggles();
    _settings.addListener(_syncServiceToggles);
  }

  final SettingsProvider _settings;
  final StorageService _storage;
  final AudioService _audio;
  final NotificationService _notifications;
  final PresenceController _presence;

  Timer? _ticker;
  Timer? _alertTimer;
  Timer? _completionTimer;
  bool _disposed = false;

  // --- Estado público -----------------------------------------------------

  AppState _state = AppState.idle;
  AppState get state => _state;

  int _cycleElapsed = 0;
  int get cycleElapsed => _cycleElapsed;

  int _phaseRemaining = 0;
  int get phaseRemaining => _phaseRemaining;

  bool _paused = false;
  bool get isPaused => _paused;

  // Timer oculto do lembrete de colírio.
  int _eyeDropsElapsed = 0;
  bool _eyeDropsPending = false;
  bool _eyeDropsAlert = false;
  bool get eyeDropsAlert => _eyeDropsAlert;

  // Pausa por inatividade.
  bool _inactivityPaused = false;
  bool _inactivityAlert = false;
  bool get inactivityAlert => _inactivityAlert;
  bool _idleBusy = false;
  double _lastIdleSeconds = 0;

  /// Após uma retomada manual (botão do cartão), evita re-pausar
  /// imediatamente enquanto o usuário ainda estiver ocioso.
  bool _suppressRepauseUntilActive = false;

  // --- Configurações derivadas (lidas do SettingsProvider) ----------------

  int get cycleSeconds => _settings.value.cycleSeconds;
  int get phaseSeconds => _settings.value.phaseSeconds;
  bool get _soundOn => _settings.value.soundEnabled;
  bool get _notifyOn => _settings.value.notificationsEnabled;

  double get cycleProgress =>
      cycleSeconds == 0 ? 0 : (_cycleElapsed / cycleSeconds).clamp(0.0, 1.0);

  // --- Ciclo de vida ------------------------------------------------------

  void _syncServiceToggles() {
    _audio.enabled = _soundOn;
    _notifications.enabled = _notifyOn;
  }

  void start() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    notifyListeners();
  }

  void _onTick() {
    _tickEyeDrops();
    _checkPresence();
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
    if (_paused || _inactivityPaused) return;
    _cycleElapsed++;
    if (_cycleElapsed % 5 == 0) {
      _storage.setElapsedSeconds(_cycleElapsed);
    }
    if (_cycleElapsed >= cycleSeconds) {
      _enterAlerta();
    }
    notifyListeners();
  }

  // --- Pausa por inatividade do sistema -----------------------------------

  /// Consulta o [PresenceController] a cada tick e pausa/retoma o ciclo.
  /// O limiar de entrada é **adaptativo** (aprendido por faixa horária); a
  /// retomada usa a histerese de [AppDefaults.inactivityResumeSeconds]. A
  /// leitura nativa é assíncrona e protegida contra sobreposição ([_idleBusy]).
  void _checkPresence() {
    if (!_settings.value.pauseOnInactivity) {
      if (_inactivityPaused || _inactivityAlert) _clearInactivityPause();
      return;
    }
    if (_idleBusy) return;
    _idleBusy = true;
    () async {
      try {
        final now = DateTime.now();
        final idle = await _presence.idleSeconds();
        if (_disposed) return;

        // Atividade real de volta encerra a supressão pós-retomada-manual.
        if (idle <= AppDefaults.inactivityResumeSeconds) {
          _suppressRepauseUntilActive = false;
        }

        final decision = await _presence.evaluate(idleSeconds: idle, now: now);
        if (_disposed) return;

        if (decision == Presence.absent &&
            !_inactivityPaused &&
            !_suppressRepauseUntilActive) {
          _inactivityPaused = true;
          _inactivityAlert = true;
          // Ao entrar em pausa, preserva o progresso acumulado (RF-12).
          _storage.setElapsedSeconds(_cycleElapsed);
          notifyListeners();
        } else if (_inactivityPaused &&
            idle <= AppDefaults.inactivityResumeSeconds) {
          // Input retomado: o gap anterior era presença parada -> aprende.
          _presence.onResume(previousIdleSeconds: _lastIdleSeconds, now: now);
          _clearInactivityPause();
        }
        _lastIdleSeconds = idle;
      } finally {
        _idleBusy = false;
      }
    }();
  }

  /// Retomada manual da pausa por inatividade (botão "Retomar" no cartão).
  ///
  /// Limpa apenas a pausa automática por inatividade; **não** interfere na
  /// pausa manual (`_paused`) feita pelo menu. Suprime a re-pausa até haver
  /// atividade real, para o botão não ser anulado no tick seguinte.
  void resumeFromInactivity() {
    if (_inactivityPaused || _inactivityAlert) {
      _suppressRepauseUntilActive = true;
      _clearInactivityPause();
    }
  }

  /// Apaga o aprendizado de inatividade (modelo + estado persistido cifrado).
  Future<void> resetInactivityLearning() => _presence.reset();

  void _clearInactivityPause() {
    _inactivityPaused = false;
    _inactivityAlert = false;
    notifyListeners();
  }

  // --- ALERTA -------------------------------------------------------------

  void _enterAlerta() {
    _state = AppState.alerta;
    _cycleElapsed = 0;
    _storage.setElapsedSeconds(0);
    if (_soundOn) _audio.playAlert();
    if (_notifyOn) {
      final s = _settings.strings;
      _notifications.notifyBreakStart(s.notifyBreakTitle, s.notifyBreakBody);
    }
    notifyListeners();

    _alertTimer?.cancel();
    _alertTimer = Timer(const Duration(milliseconds: 1500), () {
      if (_disposed) return;
      _alertTimer = null;
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
    if (_notifyOn) {
      final s = _settings.strings;
      _notifications.notifyBreakDone(s.notifyDoneTitle, s.notifyDoneBody);
    }
    notifyListeners();

    _completionTimer?.cancel();
    _completionTimer = Timer(AppDurations.completion, () {
      if (_disposed) return;
      _completionTimer = null;
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

  // --- Lembrete de colírio (timer oculto) --------------------------------

  void _tickEyeDrops() {
    final s = _settings.value;
    if (!s.eyeDropsEnabled) return;
    _eyeDropsElapsed++;
    if (_eyeDropsElapsed % 60 == 0) {
      _storage.setEyeDropsElapsed(_eyeDropsElapsed);
    }
    final interval = s.eyeDropsIntervalHours * 3600;
    if (_eyeDropsElapsed >= interval) {
      _eyeDropsElapsed = 0;
      _storage.setEyeDropsElapsed(0);
      _eyeDropsPending = true;
      if (_notifyOn) {
        final str = _settings.strings;
        _notifications.show(str.eyeDropsNotifyTitle, str.eyeDropsNotifyBody);
      }
    }
    // Exibe o aviso na tela apenas quando ocioso (não atrapalha uma pausa).
    if (_eyeDropsPending && _state == AppState.idle && !_eyeDropsAlert) {
      _eyeDropsPending = false;
      _eyeDropsAlert = true;
      notifyListeners();
    }
  }

  /// Fecha o aviso de colírio (após o usuário confirmar).
  void dismissEyeDrops() {
    if (_eyeDropsAlert) {
      _eyeDropsAlert = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _settings.removeListener(_syncServiceToggles);
    _ticker?.cancel();
    _alertTimer?.cancel();
    _completionTimer?.cancel();
    super.dispose();
  }
}
