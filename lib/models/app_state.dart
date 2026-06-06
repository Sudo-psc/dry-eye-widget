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
