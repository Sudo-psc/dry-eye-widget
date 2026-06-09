import 'package:flutter/material.dart';

/// Constantes globais do aplicativo: cores, durações e textos.
///
/// Centralizar esses valores facilita o ajuste fino do visual e da
/// temporização sem precisar caçar números mágicos pelos widgets.
class AppColors {
  AppColors._();

  /// Cor padrão da bolinha no estado IDLE.
  static const Color idleBall = Color(0xFF4A90E2);

  /// Cor padrão da bolinha durante alerta e fases de pausa.
  static const Color alertBall = Color(0xFFFF4444);

  /// Fundo do overlay de vidro líquido (branco semitransparente).
  static const Color glassFill = Color(0x26FFFFFF); // 0.15 de opacidade
  static const Color glassBorder = Color(0x4DFFFFFF); // 0.30 de opacidade
  static const Color glassShadow = Color(0x4D000000); // 0.30 de opacidade

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xCCFFFFFF);
}

/// Paleta de cores sugeridas no seletor de cor das configurações.
class AppPalette {
  AppPalette._();

  static const List<Color> options = [
    Color(0xFF4A90E2), // azul
    Color(0xFF50C878), // verde esmeralda
    Color(0xFF9B59B6), // roxo
    Color(0xFFFF4444), // vermelho
    Color(0xFFFF8C00), // laranja
    Color(0xFFFFD400), // amarelo
    Color(0xFF1ABC9C), // turquesa
    Color(0xFFE91E63), // rosa
    Color(0xFF607D8B), // cinza-azulado
    Color(0xFF000000), // preto
    Color(0xFFFFFFFF), // branco
  ];
}

/// Valores de fábrica usados quando o usuário ainda não personalizou nada.
class AppDefaults {
  AppDefaults._();

  static const int cycleMinutes = 20;
  static const int phaseSeconds = 20;
  static const bool soundEnabled = true;
  static const bool notificationsEnabled = true;

  static const double ballSize = 40.0;
  static const int idleColor = 0xFF4A90E2;
  static const int alertColor = 0xFFFF4444;
  static const double idleOpacity = 1.0;
  static const int blinkMs = 500;
  static const bool dimBackground = true;
  static const double dimOpacity = 0.2;

  static const bool launchAtLogin = false;
  static const double overlayOpacity = 0.15;
  static const double overlayBlur = 20.0;
  static const bool showProgressRing = true;
  static const bool hideDockIcon = false;
  static const bool hideMenuBarItem = false;
  static const bool hideFloatingWidget = false;
  static const bool gentleMode = false;
  static const String languageCode = 'pt';
  static const bool eyeDropsEnabled = false;
  static const int eyeDropsIntervalHours = 4;
  static const bool pauseOnInactivity = true;

  /// Segundos de inatividade do sistema antes de pausar o timer.
  static const int inactivitySeconds = 120;

  static const double minBallSize = 24.0;
  static const double maxBallSize = 80.0;
}

/// Durações fixas (não configuráveis) usadas em animações.
class AppDurations {
  AppDurations._();

  /// Ciclo principal padrão (referência; o valor real vem das configurações).
  static const Duration defaultCycle = Duration(minutes: 20);

  /// Duração padrão de cada fase (referência).
  static const Duration defaultPhase = Duration(seconds: 20);

  /// Tempo que a tela de conclusão permanece visível.
  static const Duration completion = Duration(seconds: 3);

  /// Transições de fade do overlay.
  static const Duration fade = Duration(milliseconds: 500);
}

/// Tamanhos auxiliares.
class AppSizes {
  AppSizes._();

  /// Margem entre a bolinha e a borda da janela compacta.
  static const double ballPadding = 8.0;

  /// Largura máxima do overlay.
  static const double overlayMaxWidth = 400.0;
}

/// Textos exibidos em cada fase. Mantidos em PT-BR.
class AppTexts {
  AppTexts._();

  static const String alertTitle = 'Tire uma pausa de 20 segundos';
  static const String alertSubtitle = 'Vou iniciar um cronômetro';

  static const String phaseTitle = 'Olhe para uma distância de 6 metros';
  static const String phaseSubtitle =
      'Lembre-se de piscar ao olhar a uma distância de 6 m e mantenha o '
      'olhar até o cronômetro zerar';

  static const String doneTitle = 'Parabéns!';
  static const String doneSubtitle =
      'Você renovou suas lágrimas. Volte ao trabalho com os olhos descansados';
}

/// Chaves de persistência usadas pelo [StorageService].
class StorageKeys {
  StorageKeys._();

  static const String ballX = 'ball_x';
  static const String ballY = 'ball_y';
  static const String elapsedSeconds = 'elapsed_seconds';
  static const String eyeDropsElapsed = 'eye_drops_elapsed';

  /// JSON serializado de [WidgetSettings] com todas as preferências.
  static const String widgetSettings = 'widget_settings_json';
}

/// Informações do app usadas na verificação de atualização.
class AppInfo {
  AppInfo._();

  /// Versão atual (deve acompanhar a `version` do pubspec.yaml).
  static const String version = '1.6.2';

  static const String repoOwner = 'Sudo-psc';
  static const String repoName = 'dry-eye-widget';

  static String get latestReleaseApi =>
      'https://api.github.com/repos/$repoOwner/$repoName/releases/latest';
  static String get releasesPage =>
      'https://github.com/$repoOwner/$repoName/releases/latest';
}
