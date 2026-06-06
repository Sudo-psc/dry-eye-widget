import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Reprodução dos sons curtos do app.
///
/// Tenta tocar os assets em `assets/sounds/`. Se o arquivo não existir ou
/// o backend de áudio falhar, faz fallback para o som de alerta do sistema,
/// garantindo que o usuário sempre receba algum retorno sonoro.
class AudioService {
  AudioService() {
    // Modo low-latency é ideal para sons curtos e repetidos (tique-taque).
    _player.setReleaseMode(ReleaseMode.stop);
  }

  final AudioPlayer _player = AudioPlayer();

  bool enabled = true;

  Future<void> _play(String asset) async {
    if (!enabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/$asset'));
    } catch (e) {
      // Fallback: som de sistema. Não interrompe o fluxo do app.
      debugPrint('AudioService: falha ao tocar "$asset" ($e). Usando fallback.');
      try {
        await SystemSound.play(SystemSoundType.alert);
      } catch (_) {
        // Silencioso: áudio é opcional por design.
      }
    }
  }

  /// Som de alerta no início da pausa (estado ALERTA).
  Future<void> playAlert() => _play('alert.wav');

  /// Tique-taque a cada segundo durante as fases.
  Future<void> playTick() => _play('tick.wav');

  /// Som curto de conclusão de fase / sucesso final.
  Future<void> playSuccess() => _play('success.wav');

  void dispose() {
    _player.dispose();
  }
}
