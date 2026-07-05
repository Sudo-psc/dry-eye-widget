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
  })  : _storage = storage,
        _monitor = monitor,
        _data = storage.loadActivityStats();

  final StorageService _storage;
  final ActivityMonitorService _monitor;

  /// Intervalo entre consultas ao monitor nativo (segundos).
  final int pollIntervalSeconds;

  ActivityStatsData _data;
  Timer? _timer;
  bool _running = false;
  int _sincePersist = 0;

  /// Grava em disco a cada N samples (amortiza I/O).
  static const int _persistEverySamples = 12; // ~1 min com poll de 5s

  ActivityStatsData get data => _data;
  bool get isRunning => _running;

  /// Liga a coleta: registra o monitor nativo e inicia o poll periódico.
  Future<void> start() async {
    if (_running) return;
    _running = true;
    await _monitor.start();
    _timer = Timer.periodic(
      Duration(seconds: pollIntervalSeconds),
      (_) => _pollOnce(),
    );
  }

  /// Desliga a coleta e persiste o pendente.
  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    _timer?.cancel();
    _timer = null;
    await _monitor.stop();
    await flush();
  }

  Future<void> _pollOnce() async {
    final sample = await _monitor.poll();
    if (sample == null) return;
    applySample(sample, DateTime.now());
    _sincePersist++;
    if (_sincePersist >= _persistEverySamples) {
      unawaited(flush());
    }
  }

  /// Aplica uma [sample] ao dia de [moment]. Público para testes.
  void applySample(ActivitySample sample, DateTime moment) {
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
    _sincePersist = 0;
    _data = _data.pruned(now ?? DateTime.now());
    await _storage.saveActivityStats(_data);
    notifyListeners();
  }

  /// Apaga todo o histórico de atividade.
  Future<void> clear() async {
    _data = ActivityStatsData.empty();
    _sincePersist = 0;
    await _storage.saveActivityStats(_data);
    notifyListeners();
  }

  @override
  Future<void> dispose() async {
    _timer?.cancel();
    _timer = null;
    if (_running) {
      _running = false;
      await _monitor.stop();
    }
    super.dispose();
  }
}
