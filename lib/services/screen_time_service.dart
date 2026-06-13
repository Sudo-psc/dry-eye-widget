import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/screen_time_data.dart';
import 'storage_service.dart';

/// Acumula o tempo de uso ativo de tela por dia e o persiste localmente.
///
/// O [TimerProvider] chama [tick] uma vez por segundo apenas quando há
/// atividade real (sem inatividade do sistema). Para evitar escrita em disco a
/// cada segundo, o estado é mantido em memória e gravado periodicamente
/// ([_flushEverySeconds]) e ao [flush] explícito (ex.: encerramento).
class ScreenTimeService extends ChangeNotifier {
  ScreenTimeService({required StorageService storage})
    : _storage = storage,
      _data = storage.loadScreenTime();

  final StorageService _storage;
  ScreenTimeData _data;

  /// Snapshot imutável atual do histórico de tempo de tela.
  ScreenTimeData get data => _data;

  /// Segundos acumulados desde a última gravação em disco.
  int _pending = 0;

  /// Intervalo de gravação (em ticks/segundos) para amortizar a I/O.
  static const int _flushEverySeconds = 60;

  /// Registra um segundo de uso ativo no dia atual.
  void tick([DateTime? now]) {
    final moment = now ?? DateTime.now();
    _data = _data.addSeconds(moment, 1);
    _pending++;
    if (_pending >= _flushEverySeconds) {
      unawaited(flush(moment));
    }
  }

  /// Grava o estado pendente em disco (com poda do histórico antigo) e
  /// notifica ouvintes para atualizar a janela de visualização.
  Future<void> flush([DateTime? now]) async {
    if (_pending == 0) return;
    _pending = 0;
    _data = _data.pruned(now ?? DateTime.now());
    await _storage.saveScreenTime(_data);
    notifyListeners();
  }

  /// Apaga todo o histórico de tempo de tela.
  Future<void> clear() async {
    _data = ScreenTimeData.empty();
    _pending = 0;
    await _storage.saveScreenTime(_data);
    notifyListeners();
  }
}
