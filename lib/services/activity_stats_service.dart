// Campos privados injetados por construtor nomeado não podem virar
// initializing formals públicos (o nome do parâmetro seria privado).
// ignore_for_file: prefer_initializing_formals
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/activity_stats_data.dart';
import 'activity_monitor_service.dart';
import 'storage_service.dart';

/// Acumula estatísticas de atividade (cliques, teclas, tempo por app) por dia.
///
/// Opt-in: só coleta enquanto habilitado. A cada [pollIntervalSeconds] consulta
/// o monitor nativo, soma os contadores e atribui o intervalo ao app em foco.
/// Persiste periodicamente para amortizar I/O. Dados 100% locais.
class ActivityStatsService extends ChangeNotifier {
  ActivityStatsService({
    required StorageService storage,
    required ActivityMonitorService monitor,
    this.pollIntervalSeconds = 5,
  }) : _storage = storage,
       _monitor = monitor,
       _data = storage.loadActivityStats();

  final StorageService _storage;
  final ActivityMonitorService _monitor;

  /// Intervalo entre consultas ao monitor nativo (segundos).
  final int pollIntervalSeconds;

  ActivityStatsData _data;
  Timer? _timer;
  bool _running = false;
  bool _disposed = false;
  bool _polling = false;
  bool _clearing = false;
  int _lifecycleVersion = 0;
  int _historyVersion = 0;
  Future<void> _monitorQueue = Future<void>.value();
  int _sincePersist = 0;

  /// Grava em disco a cada N samples (amortiza I/O).
  static const int _persistEverySamples = 12; // ~1 min com poll de 5s

  ActivityStatsData get data => _data;
  bool get isRunning => _running;

  /// Liga a coleta: registra o monitor nativo e inicia o poll periódico.
  Future<void> start() async {
    if (_disposed || _running) return;
    _running = true;
    final version = ++_lifecycleVersion;
    await _withMonitor(() async {
      if (!_isCurrentSession(version)) return;
      await _monitor.start();
    });
    if (!_isCurrentSession(version)) return;
    _timer?.cancel();
    _timer = Timer.periodic(
      Duration(seconds: pollIntervalSeconds),
      (_) => _pollOnce(),
    );
  }

  /// Desliga a coleta e persiste o pendente.
  Future<void> stop() async {
    if (_disposed) return;
    final wasRunning = _running;
    _running = false;
    _lifecycleVersion++;
    _timer?.cancel();
    _timer = null;
    if (wasRunning) {
      await _withMonitor(_monitor.stop);
    } else {
      await _monitorQueue;
    }
    // Também persiste quando a coleta já estava parada: pode haver amostras
    // aplicadas desde o último flush ou dados aguardando o encerramento.
    await flush();
  }

  bool _isCurrentSession(int version) =>
      !_disposed && _running && version == _lifecycleVersion;

  /// Preserva a ordem de start/stop/poll mesmo quando o canal nativo demora.
  Future<T> _withMonitor<T>(Future<T> Function() operation) {
    final pending = _monitorQueue.then((_) => operation());
    // Uma falha não deve impedir a execução das próximas operações.
    _monitorQueue = pending.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return pending;
  }

  Future<void> _pollOnce() async {
    if (!_running || _disposed || _polling || _clearing) return;
    final session = _lifecycleVersion;
    final history = _historyVersion;
    _polling = true;
    try {
      final sample = await _withMonitor(() async {
        if (!_isCurrentSession(session) || history != _historyVersion) {
          return null;
        }
        return _monitor.poll();
      });
      if (sample == null ||
          !_isCurrentSession(session) ||
          history != _historyVersion) {
        return;
      }
      applySample(sample, DateTime.now());
      _sincePersist++;
      if (_sincePersist >= _persistEverySamples) {
        unawaited(flush());
      }
    } finally {
      _polling = false;
    }
  }

  /// Aplica uma [sample] ao dia de [moment]. Público para testes.
  void applySample(ActivitySample sample, DateTime moment) {
    if (_disposed) return;
    var next = _data.incremented(
      moment,
      clicks: sample.clicks,
      keys: sample.keys,
    );
    final app = sample.frontApp;
    if (app != null && app.isNotEmpty) {
      next = next.addAppSeconds(moment, app, pollIntervalSeconds);
    }
    _data = next;
    notifyListeners();
  }

  /// Grava o estado atual (com poda) em disco.
  Future<void> flush([DateTime? now]) async {
    if (_disposed) return;
    _sincePersist = 0;
    _data = _data.pruned(now ?? DateTime.now());
    await _storage.saveActivityStats(_data);
    if (!_disposed) notifyListeners();
  }

  /// Apaga todo o histórico de atividade.
  Future<void> clear() async {
    if (_disposed) return;
    final history = ++_historyVersion;
    _clearing = true;
    _data = ActivityStatsData.empty();
    _sincePersist = 0;
    try {
      await _storage.saveActivityStats(_data);
      // poll também zera os contadores nativos. Descarta o acumulado anterior
      // à limpeza antes de aceitar novas amostras do monitor ainda ligado.
      await _withMonitor(() async {
        if (_running && !_disposed) await _monitor.poll();
      });
    } finally {
      if (history == _historyVersion) _clearing = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    final wasRunning = _running;
    _running = false;
    _lifecycleVersion++;
    _timer?.cancel();
    _timer = null;
    super.dispose();
    if (wasRunning) {
      await _withMonitor(_monitor.stop);
    } else {
      await _monitorQueue;
    }
  }
}
