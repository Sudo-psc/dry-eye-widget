import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Detecção de presença por rosto on-device, via canal nativo.
///
/// No macOS usa o framework Vision: captura **um único frame**, roda a
/// detecção e descarta a imagem na hora — nada é gravado em disco nem enviado
/// pela rede. Indisponível/negado/erro → `false` (degradação segura).
class VisionService {
  const VisionService();

  static const MethodChannel _channel = MethodChannel('dry_eye_widget/vision');

  /// Captura 1 frame e retorna se há um rosto enquadrado.
  Future<bool> hasFace() async {
    try {
      return await _channel.invokeMethod<bool>('hasFace') ?? false;
    } catch (e) {
      debugPrint('VisionService indisponível ($e).');
      return false;
    }
  }
}
