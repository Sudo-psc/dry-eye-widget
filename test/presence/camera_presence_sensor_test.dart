import 'package:flutter_test/flutter_test.dart';
import 'package:dry_eye_widget/services/presence/presence_sensor.dart';
import 'package:dry_eye_widget/services/presence/camera_presence_sensor.dart';

void main() {
  group('CameraPresenceSensor', () {
    test('rosto detectado => present', () async {
      final sensor = CameraPresenceSensor(() async => true);
      expect(await sensor.sample(), Presence.present);
    });

    test('sem rosto => absent', () async {
      final sensor = CameraPresenceSensor(() async => false);
      expect(await sensor.sample(), Presence.absent);
    });
  });
}
