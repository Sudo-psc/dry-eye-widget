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
  /// Secundário com contraste ≥ ~4.5:1 sobre vidro escuro típico (WCAG AA).
  static const Color textSecondary = Color(0xE0FFFFFF);

  /// Rótulos terciários (headers de seção, meta) — ainda legíveis em vidro.
  static const Color textMuted = Color(0xB3FFFFFF);

  /// Fundo escuro de diálogos (Sobre, configurações).
  static const Color surface = Color(0xFF2A2A2A);

  /// Realce de hover sobre vidro (menu, botões compactos).
  static const Color hoverFillTop = Color(0x33FFFFFF);
  static const Color hoverFillBottom = Color(0x0FFFFFFF);
  static const Color hoverBorder = Color(0x33FFFFFF);

  /// Divisores e traços sutis.
  static const Color divider = Color(0x1FFFFFFF);
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
  static const bool visualBlinkRemindersEnabled = true;
  static const bool blinkReminderSoundEnabled = false;
  static const double blinkReminderVolume = 0.3;
  static const int blinkReminderIntervalMs = 7500;
  static const int blinkReminderVisibleMs = 1800;

  static const double ballSize = 32.0;
  static const int idleColor = 0xFF4A90E2;
  static const int alertColor = 0xFFFF4444;
  static const double idleOpacity = 0.82;
  static const int blinkMs = 500;
  static const bool dynamicOrbEffect = true;
  static const bool hoverReactiveBall = true;

  /// Encostar a bolinha na borda lateral ao arrastá-la até ela (meia-lua).
  static const bool edgeSnap = true;
  static const double orbIntensity = 0.72;
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

  /// Bloqueia a tela (overlay em tela cheia) durante a pausa mesmo quando o
  /// modo de notificação suave está ligado. Desligado por padrão.
  static const bool lockScreenOnBreak = false;

  /// Coleta o tempo de uso diário de tela (apenas local, sem envio). Ligado
  /// por padrão — alimenta a janela de visualização de tempo de tela.
  static const bool screenTimeTracking = true;

  /// Monitorar cliques, teclas (só contagem) e apps em foco (opt-in, OFF).
  static const bool activityMonitorEnabled = false;

  static const String languageCode = 'pt';
  static const bool eyeDropsEnabled = false;
  static const int eyeDropsIntervalHours = 4;
  static const bool pauseOnInactivity = true;

  /// Confirmar presença pela câmera (opt-in, desligado por padrão).
  static const bool cameraPresence = false;

  /// Segundos de inatividade do sistema antes de pausar o timer.
  static const int inactivitySeconds = 120;

  /// Limiar (em segundos de inatividade) para retomar o ciclo após uma pausa
  /// por inatividade. Menor que [inactivitySeconds] para criar histerese e
  /// evitar oscilação do estado perto do limite.
  static const int inactivityResumeSeconds = 5;

  static const double minBallSize = 18.0;
  static const double maxBallSize = 96.0;

  /// Escala global da interface (acessibilidade). 1.0 = tamanho padrão.
  static const double uiScale = 1.0;
  static const double minUiScale = 0.8;
  static const double maxUiScale = 1.6;

  /// Densidade de espaçamento: confortável (padrão) ou compacta.
  static const String uiDensity = 'comfortable';

  /// Indica se o usuário já concluiu o onboarding de primeira execução.
  static const bool onboardingComplete = false;

  /// Lembrete suave de reavaliação do DVRS (educativo, opt-out nas configs).
  static const bool dvrsReminderEnabled = true;

  /// Intervalo em dias entre lembretes de reavaliação do DVRS.
  static const int dvrsReminderDays = 14;
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

  static const String phaseTitle = 'Olhe para longe e pisque devagar';
  static const String phaseSubtitle =
      'Foque a cerca de 6 metros e continue a piscar lenta e completamente '
      'até o cronômetro zerar.';

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

  /// Estado agregado, cifrado, do modelo de presença.
  static const String presenceModel = 'presence_model_enc';

  /// JSON serializado com o tempo de uso de tela por dia ({'AAAA-MM-DD': seg}).
  static const String screenTime = 'screen_time_json';

  /// JSON serializado com as estatísticas de pausas visuais por dia
  /// ({'AAAA-MM-DD': {'r': lembretes, 'c': concluídas}}).
  static const String breakStats = 'break_stats_json';

  /// JSON serializado com o último checklist ambiental autorreferido.
  static const String environmentChecklist = 'environment_checklist_json';

  /// JSON serializado com o histórico de resultados do DVRS — Índice de Risco
  /// Visual Digital (questionário principal).
  static const String dvrsResults = 'dvrs_results_json';

  /// Rascunho parcial do DVRS (respostas incompletas entre sessões).
  static const String dvrsDraft = 'dvrs_draft_json';

  /// Borda em que a bolinha está encaixada ('left'/'right'), vazio = solta.
  static const String dockEdge = 'ball_dock_edge';

  /// JSON com estatísticas de atividade por dia (cliques, teclas, tempo/app).
  static const String activityStats = 'activity_stats_json';

  /// ISO-8601 da data até a qual o lembrete de reavaliação do DVRS fica adiado.
  static const String dvrsNudgeSnoozedUntil = 'dvrs_nudge_snoozed_until';

  /// Dia (`AAAA-MM-DD`) em que a notificação de reavaliação do DVRS já foi
  /// enviada — no máximo uma por dia.
  static const String dvrsNudgeNotifiedDay = 'dvrs_nudge_notified_day';
}

/// Informações do app usadas na verificação de atualização.
class AppInfo {
  AppInfo._();

  /// Versão atual (deve acompanhar a `version` do pubspec.yaml).
  static const String version = '1.24.0';

  static const String repoOwner = 'Sudo-psc';
  static const String repoName = 'dry-eye-widget';

  /// Comando que remove a quarentena do .dmg baixado, contornando o falso
  /// "app danificado" do Gatekeeper (build sem notarização). Mostrado no
  /// diálogo de atualização do macOS.
  static const String macUnblockCommand =
      'xattr -cr ~/Downloads/DryEyeWidget*.dmg';

  static String get latestReleaseApi =>
      'https://api.github.com/repos/$repoOwner/$repoName/releases/latest';
  static String get releasesPage =>
      'https://github.com/$repoOwner/$repoName/releases/latest';
}
