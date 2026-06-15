import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Detecta se o app em primeiro plano está em modo tela cheia (apenas macOS).
///
/// Usado para rotear os avisos de pausa para uma notificação do sistema quando
/// o overlay flutuante não consegue aparecer sobre apps em tela cheia.
class FullscreenService {
  static const MethodChannel _channel = MethodChannel('dry_eye_widget/display');

  /// `true` quando o app frontmost (que não seja este próprio widget) ocupa uma
  /// tela inteira. Em plataformas não-macOS retorna sempre `false`.
  Future<bool> isFrontmostFullscreen() async {
    if (!Platform.isMacOS) return false;
    try {
      final result = await _channel.invokeMethod<bool>('frontmostFullscreen');
      return result ?? false;
    } catch (e) {
      debugPrint('FullscreenService: falha ($e).');
      return false;
    }
  }
}
