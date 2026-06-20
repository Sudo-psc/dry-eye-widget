import 'package:flutter_test/flutter_test.dart';
import 'package:dry_eye_widget/services/idle_service.dart';
import 'package:dry_eye_widget/services/presence/presence_sensor.dart';
import 'package:dry_eye_widget/services/presence/input_idle_sensor.dart';

class _FakeIdleService implements IdleService {
  _FakeIdleService(this._idleSeconds);
  double _idleSeconds;

  @override
  Future<double> idleSeconds() async {
    return _idleSeconds;
  }
}

void main() {
  group('InputIdleSensor', () {
    test('idle time below activity window => present', () async {
      final fakeService = _FakeIdleService(1.5);
      final sensor = InputIdleSensor(fakeService, activityWindowSeconds: 2);
      expect(await sensor.sample(), Presence.present);
    });

    test('idle time equal to activity window => unknown', () async {
      final fakeService = _FakeIdleService(2.0);
      final sensor = InputIdleSensor(fakeService, activityWindowSeconds: 2);
      expect(await sensor.sample(), Presence.unknown);
    });

    test('idle time above activity window => unknown', () async {
      final fakeService = _FakeIdleService(5.0);
      final sensor = InputIdleSensor(fakeService, activityWindowSeconds: 2);
      expect(await sensor.sample(), Presence.unknown);
    });

    test('idle time zero => present', () async {
      final fakeService = _FakeIdleService(0.0);
      final sensor = InputIdleSensor(fakeService, activityWindowSeconds: 2);
      expect(await sensor.sample(), Presence.present);
    });
  });
}
