import 'presence_sensor.dart';

/// Sensor de presença opcional via webcam: um snapshot pontual no limiar +
/// detecção de rosto on-device. Só é consultado pelo [PresenceController]
/// quando a câmera está habilitada nas configurações.
///
/// Recebe a função de detecção injetada (`hasFace`) para permitir fakes nos
/// testes sem tocar a câmera. Rosto enquadrado → [Presence.present]; caso
/// contrário (ou erro) → [Presence.absent].
class CameraPresenceSensor implements PresenceSensor {
  CameraPresenceSensor(this._detectFace);

  final Future<bool> Function() _detectFace;

  @override
  Future<Presence> sample() async =>
      (await _detectFace()) ? Presence.present : Presence.absent;
}
