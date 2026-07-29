import 'package:flutter_test/flutter_test.dart';
import 'package:dry_eye_widget/services/presence/presence_sensor.dart';
import 'package:dry_eye_widget/services/presence/presence_controller.dart';
import 'package:dry_eye_widget/services/presence/adaptive_threshold_model.dart';
import 'package:dry_eye_widget/services/presence/presence_store.dart';

class _FakeCamera implements PresenceSensor {
  _FakeCamera(this.result);
  Presence result;
  int calls = 0;
  @override
  Future<Presence> sample() async {
    calls++;
    return result;
  }
}

/// Fonte de ociosidade fixa para os testes.
Future<double> Function() _idle(double v) =>
    () async => v;

class _FakePresenceStore implements PresenceStore {
  _FakePresenceStore(this.state);

  Map<String, dynamic>? state;

  @override
  Future<void> clear() async => state = null;

  @override
  Future<Map<String, dynamic>?> load() async => state;

  @override
  Future<void> save(Map<String, dynamic> state) async => this.state = state;
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
      );

      await c.hydrate();

      expect(store.state, same(state));
    });
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
