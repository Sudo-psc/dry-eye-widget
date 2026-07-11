import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Os estados da máquina de estados do aplicativo.
///
/// O fluxo é cíclico:
/// IDLE -> ALERTA -> FASE_1 -> CONCLUSAO -> IDLE -> ...
enum AppState {
  /// Padrão: bolinha azul, cronômetro de ciclo rodando silenciosamente.
  idle,

  /// Disparo inicial da pausa: bolinha vermelha piscando, som de alerta.
  alerta,

  /// Pausa de [phaseSeconds]: olhar a 6 m e piscar até o cronômetro zerar.
  fase1,

  /// Tela final de parabéns antes de voltar ao IDLE.
  conclusao,
}

extension AppStateX on AppState {
  /// Indica se a bolinha deve estar vermelha e piscando.
  bool get isActive => this != AppState.idle;

  /// Texto principal do overlay para o estado atual.
  String get title {
    switch (this) {
      case AppState.idle:
        return '';
      case AppState.alerta:
        return AppTexts.alertTitle;
      case AppState.fase1:
        return AppTexts.phaseTitle;
      case AppState.conclusao:
        return AppTexts.doneTitle;
    }
  }

  /// Texto secundário do overlay para o estado atual.
  String get subtitle {
    switch (this) {
      case AppState.idle:
        return '';
      case AppState.alerta:
        return AppTexts.alertSubtitle;
      case AppState.fase1:
        return AppTexts.phaseSubtitle;
      case AppState.conclusao:
        return AppTexts.doneSubtitle;
    }
  }

  /// Se o cronômetro regressivo deve ser exibido neste estado.
  bool get showsCountdown => this == AppState.fase1;
}

/// Cantos possíveis para a posição padrão da bolinha.
enum BallCorner { topLeft, topRight, bottomLeft, bottomRight, center }

extension BallCornerX on BallCorner {
  String get label {
    switch (this) {
      case BallCorner.topLeft:
        return 'Superior esquerdo';
      case BallCorner.topRight:
        return 'Superior direito';
      case BallCorner.bottomLeft:
        return 'Inferior esquerdo';
      case BallCorner.bottomRight:
        return 'Inferior direito';
      case BallCorner.center:
        return 'Centro';
    }
  }
}

/// Toques curtos usados no lembrete sonoro de piscada.
enum BlinkReminderSound { softPulse, clearDrop, warmBell, lightTick }

/// Densidade visual da interface (espaçamento de controles e painéis).
enum UiDensity {
  /// Mais compacto: menos padding, VisualDensity.compact.
  compact,

  /// Padrão confortável.
  comfortable,
}

extension UiDensityX on UiDensity {
  String get id => name;

  VisualDensity get visualDensity => this == UiDensity.compact
      ? VisualDensity.compact
      : VisualDensity.standard;

  /// Fator de padding (1.0 confortável, 0.85 compacto).
  double get spacingScale => this == UiDensity.compact ? 0.85 : 1.0;
}

UiDensity uiDensityFromId(String? id) {
  switch (id) {
    case 'compact':
      return UiDensity.compact;
    case 'comfortable':
    default:
      return UiDensity.comfortable;
  }
}

/// Frequência do lembrete visual de piscada.
enum BlinkReminderFrequency { discreet, normal, frequent }

extension BlinkReminderFrequencyX on BlinkReminderFrequency {
  /// Intervalo entre avisos, em milissegundos.
  int get intervalMs {
    switch (this) {
      case BlinkReminderFrequency.discreet:
        return 12000;
      case BlinkReminderFrequency.normal:
        return 7500;
      case BlinkReminderFrequency.frequent:
        return 4500;
    }
  }
}

extension BlinkReminderSoundX on BlinkReminderSound {
  String get assetName {
    switch (this) {
      case BlinkReminderSound.softPulse:
        return 'blink_soft_pulse.wav';
      case BlinkReminderSound.clearDrop:
        return 'blink_clear_drop.wav';
      case BlinkReminderSound.warmBell:
        return 'blink_warm_bell.wav';
      case BlinkReminderSound.lightTick:
        return 'blink_light_tick.wav';
    }
  }
}
