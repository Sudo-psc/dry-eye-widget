import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:dry_eye_widget/services/presence/presence_sensor.dart';
import 'package:dry_eye_widget/services/presence/presence_controller.dart';
import 'package:dry_eye_widget/services/presence/adaptive_threshold_model.dart';
import 'package:dry_eye_widget/services/presence/presence_store.dart';

class _FakeCamera implements PresenceSensor {
  _FakeCamera(this.result);
  Presence result;
  int calls = 0;
  Future<Presence>? pending;
  @override
  Future<Presence> sample() async {
    calls++;
    if (pending != null) return pending!;
    return result;
  }
}

/// Fonte de ociosidade fixa para os testes.
Future<double> Function() _idle(double v) =>
    () async => v;

class _FakePresenceStore implements PresenceStore {
  _FakePresenceStore(this.state);

  Map<String, dynamic>? state;
  Object? loadError;
  Object? saveError;
  Object? clearError;
  Future<void>? pendingSave;
  Future<void>? pendingClear;
  int saveCalls = 0;
  int clearCalls = 0;

  @override
  Future<void> clear() async {
    clearCalls++;
    await pendingClear;
    if (clearError != null) throw clearError!;
    state = null;
  }

  @override
  Future<Map<String, dynamic>?> load() async {
    if (loadError != null) throw loadError!;
    return state;
  }

  @override
  Future<void> save(Map<String, dynamic> state) async {
    saveCalls++;
    final snapshot = jsonDecode(jsonEncode(state)) as Map<String, dynamic>;
    await pendingSave;
    if (saveError != null) throw saveError!;
    this.state = snapshot;
  }
}

void main() {
  final noon = DateTime(2026, 6, 8, 12, 0, 0);

  group('PresenceController (sem câmera)', () {
    test('idle abaixo do limiar => present', () async {
      final c = PresenceController(
        model: AdaptiveThresholdModel(),
        idleSource: _idle(0),
      );
      final d = await c.evaluate(idleSeconds: 30, now: noon);
      expect(d, Presence.present); // cold start = 120
    });

    test('idle acima do limiar => absent', () async {
      final c = PresenceController(
        model: AdaptiveThresholdModel(),
        idleSource: _idle(0),
      );
      final d = await c.evaluate(idleSeconds: 130, now: noon);
      expect(d, Presence.absent);
    });

    test('idleSeconds delega para a fonte injetada', () async {
      final c = PresenceController(
        model: AdaptiveThresholdModel(),
        idleSource: _idle(42),
      );
      expect(await c.idleSeconds(), 42);
    });

    test('onResume com gap aprendível alimenta o modelo', () async {
      final model = AdaptiveThresholdModel(minObservations: 1);
      final c = PresenceController(model: model, idleSource: _idle(0));
      c.onResume(previousIdleSeconds: 200, now: noon);
      expect(model.thresholdForHour(12), greaterThanOrEqualTo(60));
      expect(c.lastObservedGap, 200);
    });

    test('hydrate descarta aprendizado v1 contaminado', () async {
      final legacy = AdaptiveThresholdModel(minObservations: 1)
        ..observePresentGap(12, 600);
      final state = legacy.toMap()..['v'] = 1;
      final store = _FakePresenceStore(state);
      final model = AdaptiveThresholdModel(minObservations: 1);
      final c = PresenceController(
        model: model,
        idleSource: _idle(0),
        store: store,
      );

      await c.hydrate();

      expect(model.thresholdForHour(12), 120);
      expect(store.state, isNull);
    });

    test('hydrate preserva estado de versão futura em downgrade', () async {
      final state = AdaptiveThresholdModel().toMap()
        ..['v'] = AdaptiveThresholdModel.stateVersion + 1;
      final store = _FakePresenceStore(state);
      final c = PresenceController(
        model: AdaptiveThresholdModel(),
        idleSource: _idle(0),
        store: store,
        saveEveryN: 1,
      );

      await c.hydrate();
      c.onResume(previousIdleSeconds: 200, now: noon);
      await Future<void>.delayed(Duration.zero);

      expect(store.state, same(state));
      expect(store.saveCalls, 0);
    });
  });

  group('PresenceController (falhas e concorrência do armazenamento)', () {
    test(
      'hydrate com falha continua em memória e preserva estado salvo',
      () async {
        final state = AdaptiveThresholdModel().toMap();
        final store = _FakePresenceStore(state)
          ..loadError = StateError('storage unavailable');
        final c = PresenceController(
          model: AdaptiveThresholdModel(minObservations: 1),
          idleSource: _idle(0),
          store: store,
          saveEveryN: 1,
        );

        await c.hydrate();
        c.onResume(previousIdleSeconds: 200, now: noon);
        await Future<void>.delayed(Duration.zero);

        expect(c.thresholdAt(noon), 210);
        expect(store.state, same(state));
        expect(store.saveCalls, 0);

        // Uma exclusão explícita bem-sucedida permite reaprender e persistir.
        await c.reset();
        c.onResume(previousIdleSeconds: 300, now: noon);
        await Future<void>.delayed(Duration.zero);
        expect(store.saveCalls, 1);
      },
    );

    test(
      'falha ao remover estado antigo no hydrate não aborta nem sobrescreve',
      () async {
        final state = AdaptiveThresholdModel().toMap()..['v'] = 1;
        final store = _FakePresenceStore(state)
          ..clearError = StateError('delete unavailable');
        final c = PresenceController(
          model: AdaptiveThresholdModel(),
          idleSource: _idle(0),
          store: store,
          saveEveryN: 1,
        );

        await c.hydrate();
        c.onResume(previousIdleSeconds: 200, now: noon);
        await Future<void>.delayed(Duration.zero);

        expect(store.state, same(state));
        expect(store.saveCalls, 0);
      },
    );

    test(
      'reset com falha mantém aprendizado e propaga erro; fila se recupera',
      () async {
        final error = StateError('delete unavailable');
        final store = _FakePresenceStore(null)..clearError = error;
        final c = PresenceController(
          model: AdaptiveThresholdModel(minObservations: 1),
          idleSource: _idle(0),
          store: store,
        );
        c.onResume(previousIdleSeconds: 200, now: noon);

        await expectLater(c.reset(), throwsA(same(error)));

        expect(c.thresholdAt(noon), 210);
        expect(c.lastObservedGap, 200);

        store.clearError = null;
        await c.reset();
        expect(c.thresholdAt(noon), 120);
        expect(c.lastObservedGap, isNull);
      },
    );

    test(
      'falha no save automático é consumida e gravação seguinte funciona',
      () async {
        final store = _FakePresenceStore(null)
          ..saveError = StateError('write unavailable');
        final c = PresenceController(
          model: AdaptiveThresholdModel(),
          idleSource: _idle(0),
          store: store,
          saveEveryN: 1,
        );

        c.onResume(previousIdleSeconds: 200, now: noon);
        await Future<void>.delayed(Duration.zero);
        expect(store.saveCalls, 1);
        expect(store.state, isNull);

        store.saveError = null;
        c.onResume(previousIdleSeconds: 300, now: noon);
        await Future<void>.delayed(Duration.zero);
        expect(store.saveCalls, 2);
        expect(store.state!['counts'], [0, 0, 2, 0]);
      },
    );

    test(
      'reset aguarda save pendente e só apaga memória após clear concluir',
      () async {
        final save = Completer<void>();
        final clear = Completer<void>();
        final store = _FakePresenceStore(null)
          ..pendingSave = save.future
          ..pendingClear = clear.future;
        final c = PresenceController(
          model: AdaptiveThresholdModel(minObservations: 1),
          idleSource: _idle(0),
          store: store,
          saveEveryN: 1,
        );

        c.onResume(previousIdleSeconds: 200, now: noon);
        await Future<void>.delayed(Duration.zero);
        expect(store.saveCalls, 1);
        final reset = c.reset();
        c.onResume(previousIdleSeconds: 600, now: noon);
        await Future<void>.delayed(Duration.zero);
        expect(store.clearCalls, 0);
        expect(c.thresholdAt(noon), 210);

        save.complete();
        await Future<void>.delayed(Duration.zero);
        expect(store.clearCalls, 1);
        expect(c.thresholdAt(noon), 210);
        clear.complete();
        await reset;
        await Future<void>.delayed(Duration.zero);

        expect(store.state, isNull);
        expect(store.saveCalls, 1);
        expect(c.thresholdAt(noon), 120);
        expect(c.lastObservedGap, isNull);
      },
    );

    test('reset invalida gravação que ainda não começou', () async {
      final store = _FakePresenceStore(null);
      final c = PresenceController(
        model: AdaptiveThresholdModel(),
        idleSource: _idle(0),
        store: store,
        saveEveryN: 1,
      );

      c.onResume(previousIdleSeconds: 200, now: noon);
      await c.reset();

      expect(store.saveCalls, 0);
      expect(store.state, isNull);
    });

    test(
      'câmera iniciada antes do reset não restaura aprendizado apagado',
      () async {
        final result = Completer<Presence>();
        final camera = _FakeCamera(Presence.present)..pending = result.future;
        final store = _FakePresenceStore(null);
        final c = PresenceController(
          model: AdaptiveThresholdModel(minObservations: 1),
          idleSource: _idle(0),
          cameraSensor: camera,
          cameraEnabled: () => true,
          store: store,
          saveEveryN: 1,
        );

        final evaluation = c.evaluate(idleSeconds: 200, now: noon);
        await c.reset();
        result.complete(Presence.present);

        expect(await evaluation, Presence.present);
        expect(c.thresholdAt(noon), 120);
        expect(c.lastObservedGap, isNull);
        expect(store.saveCalls, 0);
      },
    );
  });

  group('PresenceController (com câmera)', () {
    test('rosto detectado no limiar => present e aprende o gap', () async {
      final cam = _FakeCamera(Presence.present);
      final model = AdaptiveThresholdModel(minObservations: 1);
      final c = PresenceController(
        model: model,
        idleSource: _idle(0),
        cameraSensor: cam,
        cameraEnabled: () => true,
      );
      final d = await c.evaluate(idleSeconds: 130, now: noon);
      expect(d, Presence.present);
      expect(cam.calls, 1);
    });

    test('sem rosto no limiar => absent', () async {
      final cam = _FakeCamera(Presence.absent);
      final c = PresenceController(
        model: AdaptiveThresholdModel(),
        idleSource: _idle(0),
        cameraSensor: cam,
        cameraEnabled: () => true,
      );
      final d = await c.evaluate(idleSeconds: 130, now: noon);
      expect(d, Presence.absent);
    });

    test('câmera desabilitada não é consultada', () async {
      final cam = _FakeCamera(Presence.present);
      final c = PresenceController(
        model: AdaptiveThresholdModel(),
        idleSource: _idle(0),
        cameraSensor: cam,
        cameraEnabled: () => false,
      );
      await c.evaluate(idleSeconds: 130, now: noon);
      expect(cam.calls, 0);
    });
  });
}
