import 'dart:async';

import 'package:flutter/foundation.dart';

import 'presence_sensor.dart';
import 'adaptive_threshold_model.dart';
import 'presence_store.dart';

/// Decide presença/ausência combinando o limiar adaptativo (input) com um
/// sensor de câmera opcional.
class PresenceController {
  PresenceController({
    required this.model,
    required this.idleSource,
    this.cameraSensor,
    this.store,
    this.saveEveryN = 5,
    bool Function()? cameraEnabled,
  }) : cameraEnabled = cameraEnabled ?? (() => false);

  final AdaptiveThresholdModel model;
  final PresenceSensor? cameraSensor;
  final bool Function() cameraEnabled;

  /// Fonte de ociosidade global do SO (segundos).
  final Future<double> Function() idleSource;

  /// Persistência opcional do estado agregado (cifrada). Quando ausente, o
  /// modelo vive só em memória (reaprende a cada sessão).
  final PresenceStore? store;

  /// Salva o estado a cada N observações novas, para limitar gravações.
  final int saveEveryN;
  int _obsSinceSave = 0;
  Future<void> _storageOperations = Future<void>.value();
  bool _canPersist = true;
  int _modelGeneration = 0;
  int _pendingResets = 0;

  /// Ociosidade global do SO (segundos). Delega à fonte injetada.
  Future<double> idleSeconds() => idleSource();

  int? _lastObservedGap;
  int? get lastObservedGap => _lastObservedGap;

  /// Limiar vigente para a hora (exposto para diagnóstico/integração).
  int thresholdAt(DateTime now) => model.thresholdForHour(now.hour);

  /// Avalia o estado atual dado o tempo ocioso do SO.
  Future<Presence> evaluate({
    required double idleSeconds,
    required DateTime now,
  }) async {
    final threshold = model.thresholdForHour(now.hour);
    if (idleSeconds < threshold) return Presence.present;

    // Cruzou o limiar: desempata pela câmera, se habilitada.
    final cam = cameraSensor;
    if (cameraEnabled() && cam != null) {
      final generation = _modelGeneration;
      final p = await cam.sample();
      if (p == Presence.present) {
        // Confirmação direta de presença parada: aprende este gap.
        if (generation == _modelGeneration && _pendingResets == 0) {
          model.observePresentGap(now.hour, idleSeconds);
          _lastObservedGap = idleSeconds.round();
          _persistSoon();
        }
        return Presence.present;
      }
    }
    return Presence.absent;
  }

  /// Registra uma retomada manual durante o período ocioso.
  ///
  /// Esse é um sinal explícito de que a pessoa continuava presente. A retomada
  /// normal do input após uma ausência real não deve chamar este método.
  void onResume({required double previousIdleSeconds, required DateTime now}) {
    if (_pendingResets > 0) return;
    model.observePresentGap(now.hour, previousIdleSeconds);
    _lastObservedGap = previousIdleSeconds.round();
    _persistSoon();
  }

  /// Carrega o estado persistido (se houver) para dentro do modelo.
  /// Se o estado estiver inacessível, continua em memória sem sobrescrevê-lo.
  Future<void> hydrate() {
    _canPersist = false;
    _modelGeneration++;
    return _enqueueStorage(() async {
      try {
        final saved = await store?.load();
        if (saved != null) {
          final savedVersion = (saved['v'] as num?)?.toInt() ?? 1;
          if (savedVersion > AdaptiveThresholdModel.stateVersion) return;
          if (savedVersion < AdaptiveThresholdModel.stateVersion) {
            await store?.clear();
            _resetModel();
          } else {
            model.loadFrom(saved);
          }
        }
        _canPersist = true;
      } catch (_) {
        debugPrint(
          'PresenceController: leitura segura indisponível; '
          'aprendizado mantido apenas em memória.',
        );
      }
    });
  }

  /// Apaga todo o aprendizado, em memória e no armazenamento.
  Future<void> reset() {
    _modelGeneration++;
    _pendingResets++;
    return _enqueueStorage(() async {
      try {
        await store?.clear();
        _resetModel();
        _canPersist = true;
      } finally {
        _pendingResets--;
      }
    });
  }

  void _resetModel() {
    model.reset();
    _lastObservedGap = null;
    _obsSinceSave = 0;
  }

  Future<void> _enqueueStorage(Future<void> Function() operation) {
    final result = _storageOperations.then((_) => operation());
    // A falha ainda chega ao chamador, mas não interrompe a fila seguinte.
    _storageOperations = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  /// Persiste o estado após acumular [saveEveryN] observações (fire-and-forget).
  void _persistSoon() {
    if (store == null || !_canPersist || _pendingResets > 0) return;
    if (++_obsSinceSave < saveEveryN) return;
    _obsSinceSave = 0;
    final generation = _modelGeneration;
    unawaited(
      _enqueueStorage(() async {
        if (!_canPersist || generation != _modelGeneration) return;
        try {
          await store!.save(model.toMap());
        } catch (_) {
          debugPrint('PresenceController: falha ao salvar aprendizado seguro.');
        }
      }),
    );
  }
}
