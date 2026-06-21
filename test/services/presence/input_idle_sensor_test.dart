import 'package:flutter_test/flutter_test.dart';
import 'package:dry_eye_widget/services/idle_service.dart';
import 'package:dry_eye_widget/services/presence/input_idle_sensor.dart';
import 'package:dry_eye_widget/services/presence/presence_sensor.dart';

class FakeIdleService implements IdleService {
  double idleTime = 0.0;

  @override
  Future<double> idleSeconds() async {
    return idleTime;
  }
}

void main() {
  group('InputIdleSensor', () {
    late FakeIdleService fakeIdleService;
    late InputIdleSensor sensor;

    setUp(() {
      fakeIdleService = FakeIdleService();
      sensor = InputIdleSensor(fakeIdleService, activityWindowSeconds: 2);
    });

    test('sample returns present when idle time is less than activity window', () async {
      fakeIdleService.idleTime = 1.0;
      final result = await sensor.sample();
      expect(result, Presence.present);
    });

    test('sample returns unknown when idle time is equal to activity window', () async {
      fakeIdleService.idleTime = 2.0;
      final result = await sensor.sample();
      expect(result, Presence.unknown);
    });

    test('sample returns unknown when idle time is greater than activity window', () async {
      fakeIdleService.idleTime = 3.5;
      final result = await sensor.sample();
      expect(result, Presence.unknown);
    });

    test('sample returns present for exactly 0.0 idle time', () async {
      fakeIdleService.idleTime = 0.0;
      final result = await sensor.sample();
      expect(result, Presence.present);
    });

    test('respects custom activityWindowSeconds', () async {
      final customSensor = InputIdleSensor(fakeIdleService, activityWindowSeconds: 5);
      fakeIdleService.idleTime = 4.0;
      expect(await customSensor.sample(), Presence.present);

      fakeIdleService.idleTime = 5.0;
      expect(await customSensor.sample(), Presence.unknown);
    });
  });
}
