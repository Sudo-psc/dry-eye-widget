import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/app_state.dart';

/// Reprodução dos sons curtos do app.
///
/// Tenta tocar os assets em `assets/sounds/`. Se o arquivo não existir ou
/// o backend de áudio falhar, faz fallback para o som de alerta do sistema,
/// garantindo que o usuário sempre receba algum retorno sonoro.
class AudioService {
  AudioService() {
    // Modo low-latency é ideal para sons curtos e repetidos (tique-taque).
    _player.setReleaseMode(ReleaseMode.stop);
    _blinkPlayer.setReleaseMode(ReleaseMode.stop);
  }

  /// Player dos avisos do ciclo (alerta, tique-taque, sucesso).
  final AudioPlayer _player = AudioPlayer();

  /// Player dedicado ao lembrete de piscada. Mantê-lo separado evita que o
  /// `stop()`/`setVolume()` de um som interfira no outro — no macOS, reusar o
  /// mesmo player e passar o volume apenas inline no `play()` deixava o
  /// lembrete de piscada mudo.
  final AudioPlayer _blinkPlayer = AudioPlayer();

  /// Habilita os sons do ciclo 20-20-20 (alerta, tique-taque, sucesso). Não
  /// afeta o lembrete de piscada, que tem habilitação própria.
  bool enabled = true;

  Future<void> _playOn(
    AudioPlayer player,
    String asset, {
    double volume = 1.0,
    bool gated = true,
  }) async {
    if (gated && !enabled) return;
    try {
      final safeVolume = volume.clamp(0.0, 1.0).toDouble();
      await player.stop();
      // Aplica o volume explicitamente antes de tocar: no macOS o volume
      // passado apenas como argumento de `play()` nem sempre é respeitado.
      await player.setVolume(safeVolume);
      await player.play(AssetSource('sounds/$asset'), volume: safeVolume);
    } catch (e) {
      // Fallback: som de sistema. Não interrompe o fluxo do app.
      debugPrint('AudioService: falha ao tocar "$asset" ($e). Fallback.');
      SystemSound.play(SystemSoundType.alert).ignore();
    }
  }

  /// Som de alerta no início da pausa (estado ALERTA).
  Future<void> playAlert() => _playOn(_player, 'alert.wav');

  /// Tique-taque a cada segundo durante as fases.
  Future<void> playTick() => _playOn(_player, 'tick.wav');

  /// Som curto de conclusão de fase / sucesso final.
  Future<void> playSuccess() => _playOn(_player, 'success.wav');

  /// Tom suave do lembrete de piscada (player dedicado, com o volume aplicado
  /// explicitamente para garantir áudio no macOS).
  ///
  /// Tem habilitação própria (`blinkReminderSoundEnabled`), por isso **não**
  /// respeita o [enabled] geral — que silencia apenas os avisos do ciclo
  /// 20-20-20.
  Future<void> playBlinkReminder({
    required BlinkReminderSound sound,
    required double volume,
  }) => _playOn(_blinkPlayer, sound.assetName, volume: volume, gated: false);

  void dispose() {
    _player.dispose();
    _blinkPlayer.dispose();
  }
}
