import 'dart:convert';

import 'package:flutter/material.dart';

import '../utils/constants.dart';
import 'app_state.dart';

/// Conjunto imutável de todas as preferências personalizáveis do widget.
///
/// Agrupa tanto as opções de temporização/som quanto as de aparência. É
/// serializável para JSON (persistido em [StorageService]) e expõe [copyWith]
/// para edições pontuais.
@immutable
class WidgetSettings {
  const WidgetSettings({
    required this.cycleMinutes,
    required this.phaseSeconds,
    required this.soundEnabled,
    required this.notificationsEnabled,
    required this.visualBlinkRemindersEnabled,
    required this.blinkReminderSoundEnabled,
    required this.blinkReminderSound,
    required this.blinkReminderVolume,
    required this.defaultCorner,
    required this.ballSize,
    required this.idleColor,
    required this.alertColor,
    required this.idleOpacity,
    required this.blinkMs,
    required this.dynamicOrbEffect,
    required this.hoverReactiveBall,
    required this.edgeSnap,
    required this.orbIntensity,
    required this.dimBackground,
    required this.dimOpacity,
    required this.launchAtLogin,
    required this.overlayOpacity,
    required this.overlayBlur,
    required this.showProgressRing,
    required this.hideDockIcon,
    required this.hideMenuBarItem,
    required this.hideFloatingWidget,
    required this.gentleMode,
    required this.lockScreenOnBreak,
    required this.screenTimeTracking,
    required this.activityMonitorEnabled,
    required this.languageCode,
    required this.eyeDropsEnabled,
    required this.eyeDropsIntervalHours,
    required this.pauseOnInactivity,
    required this.cameraPresence,
    required this.uiScale,
    required this.onboardingComplete,
  });

  // --- Temporização / som -------------------------------------------------
  final int cycleMinutes;
  final int phaseSeconds;
  final bool soundEnabled;
  final bool notificationsEnabled;
  final bool visualBlinkRemindersEnabled;
  final bool blinkReminderSoundEnabled;
  final BlinkReminderSound blinkReminderSound;
  final double blinkReminderVolume;
  final BallCorner defaultCorner;

  // --- Aparência ----------------------------------------------------------
  /// Diâmetro da bolinha em pixels.
  final double ballSize;

  /// Cor da bolinha no estado IDLE (valor ARGB).
  final int idleColor;

  /// Cor da bolinha em alerta/pausa (valor ARGB).
  final int alertColor;

  /// Opacidade da bolinha no IDLE (0.2-1.0) para deixá-la mais discreta.
  final double idleOpacity;

  /// Intervalo do piscar em milissegundos.
  final int blinkMs;

  /// Renderiza um efeito dinâmico inspirado em assistentes visuais, usando
  /// apenas tons de azul/ciano/verde/branco.
  final bool dynamicOrbEffect;

  /// Faz a bolinha reagir ao mouse com brilho, movimento e leve ampliação.
  final bool hoverReactiveBall;

  /// Encosta a bolinha na borda lateral ao arrastar até ela (meia-lua).
  final bool edgeSnap;

  /// Intensidade visual do efeito dinâmico (0.0–1.0).
  final double orbIntensity;

  // --- Comportamento da pausa --------------------------------------------
  /// Escurece o fundo da tela durante a pausa para ajudar no foco.
  final bool dimBackground;

  /// Intensidade do escurecimento (0.0–0.6).
  final double dimOpacity;

  // --- Inicialização ------------------------------------------------------
  /// Inicia o app automaticamente ao fazer login no sistema.
  final bool launchAtLogin;

  // --- Overlay de vidro ---------------------------------------------------
  /// Opacidade do preenchimento do overlay de vidro (0.05–0.4).
  final double overlayOpacity;

  /// Intensidade do desfoque (blur) do overlay em pixels (0–40).
  final double overlayBlur;

  // --- Indicador de progresso --------------------------------------------
  /// Desenha um anel branco ao redor da bolinha que se preenche em sentido
  /// horário conforme o tempo avança até a próxima pausa.
  final bool showProgressRing;

  // --- Integração com o sistema ------------------------------------------
  /// Oculta o ícone do app no Dock (macOS) / barra de tarefas (Windows),
  /// deixando o controle pela bolinha e pelo ícone da barra de menu.
  final bool hideDockIcon;

  /// Oculta o item da barra de menu (o olho). Mutuamente exclusivo com
  /// [hideFloatingWidget] — não é permitido ocultar os dois ao mesmo tempo.
  final bool hideMenuBarItem;

  /// Oculta a bolinha flutuante. Mutuamente exclusivo com [hideMenuBarItem].
  final bool hideFloatingWidget;

  /// Modo de notificação suave: durante a pausa, em vez do overlay em tela
  /// cheia, mostra apenas um pequeno cartão no canto superior direito, sem
  /// bloquear o restante da tela.
  final bool gentleMode;

  /// Mostra o overlay em tela cheia durante a pausa mesmo com [gentleMode]
  /// ligado — "bloqueia a tela" para forçar o descanso. Quando ligado, tem
  /// precedência sobre o modo suave.
  final bool lockScreenOnBreak;

  /// Coleta localmente o tempo de uso diário de tela (sem contabilizar
  /// inatividade). Alimenta a janela de visualização de tempo de tela.
  final bool screenTimeTracking;

  /// Monitora cliques, teclas (só contagem) e apps em foco. Opt-in.
  final bool activityMonitorEnabled;

  /// Idioma da interface: 'pt' ou 'en'.
  final String languageCode;

  /// Usa o overlay em tela cheia (bloqueio) na pausa. O modo suave só vale
  /// quando ativo e [lockScreenOnBreak] desligado.
  bool get usesFullScreenBreak => !gentleMode || lockScreenOnBreak;

  /// Lembrete de colírio ligado/desligado.
  final bool eyeDropsEnabled;

  /// Intervalo do lembrete de colírio em horas (4 ou 6).
  final int eyeDropsIntervalHours;

  /// Pausar o timer automaticamente após inatividade do sistema.
  final bool pauseOnInactivity;

  /// Confirmar presença visual pela câmera quando o input fica ocioso
  /// (opt-in, desligado por padrão; só consulta a câmera no limiar).
  final bool cameraPresence;

  /// Escala global da interface para acessibilidade (0.8–1.6). Aplicada via
  /// `MediaQuery.textScaler`, afeta todo o texto dos diálogos e telas.
  final double uiScale;

  /// Marca que o onboarding de primeira execução já foi concluído.
  final bool onboardingComplete;

  /// Valores de fábrica.
  factory WidgetSettings.defaults() => const WidgetSettings(
    cycleMinutes: AppDefaults.cycleMinutes,
    phaseSeconds: AppDefaults.phaseSeconds,
    soundEnabled: AppDefaults.soundEnabled,
    notificationsEnabled: AppDefaults.notificationsEnabled,
    visualBlinkRemindersEnabled: AppDefaults.visualBlinkRemindersEnabled,
    blinkReminderSoundEnabled: AppDefaults.blinkReminderSoundEnabled,
    blinkReminderSound: BlinkReminderSound.softPulse,
    blinkReminderVolume: AppDefaults.blinkReminderVolume,
    defaultCorner: BallCorner.topRight,
    ballSize: AppDefaults.ballSize,
    idleColor: AppDefaults.idleColor,
    alertColor: AppDefaults.alertColor,
    idleOpacity: AppDefaults.idleOpacity,
    blinkMs: AppDefaults.blinkMs,
    dynamicOrbEffect: AppDefaults.dynamicOrbEffect,
    hoverReactiveBall: AppDefaults.hoverReactiveBall,
    edgeSnap: AppDefaults.edgeSnap,
    orbIntensity: AppDefaults.orbIntensity,
    dimBackground: AppDefaults.dimBackground,
    dimOpacity: AppDefaults.dimOpacity,
    launchAtLogin: AppDefaults.launchAtLogin,
    overlayOpacity: AppDefaults.overlayOpacity,
    overlayBlur: AppDefaults.overlayBlur,
    showProgressRing: AppDefaults.showProgressRing,
    hideDockIcon: AppDefaults.hideDockIcon,
    hideMenuBarItem: AppDefaults.hideMenuBarItem,
    hideFloatingWidget: AppDefaults.hideFloatingWidget,
    gentleMode: AppDefaults.gentleMode,
    lockScreenOnBreak: AppDefaults.lockScreenOnBreak,
    screenTimeTracking: AppDefaults.screenTimeTracking,
    activityMonitorEnabled: AppDefaults.activityMonitorEnabled,
    languageCode: AppDefaults.languageCode,
    eyeDropsEnabled: AppDefaults.eyeDropsEnabled,
    eyeDropsIntervalHours: AppDefaults.eyeDropsIntervalHours,
    pauseOnInactivity: AppDefaults.pauseOnInactivity,
    cameraPresence: AppDefaults.cameraPresence,
    uiScale: AppDefaults.uiScale,
    onboardingComplete: AppDefaults.onboardingComplete,
  );

  // --- Conveniências ------------------------------------------------------
  int get cycleSeconds => cycleMinutes * 60;
  Color get idleColorValue => Color(idleColor);
  Color get alertColorValue => Color(alertColor);
  Duration get blinkDuration => Duration(milliseconds: blinkMs);

  WidgetSettings copyWith({
    int? cycleMinutes,
    int? phaseSeconds,
    bool? soundEnabled,
    bool? notificationsEnabled,
    bool? visualBlinkRemindersEnabled,
    bool? blinkReminderSoundEnabled,
    BlinkReminderSound? blinkReminderSound,
    double? blinkReminderVolume,
    BallCorner? defaultCorner,
    double? ballSize,
    int? idleColor,
    int? alertColor,
    double? idleOpacity,
    int? blinkMs,
    bool? dynamicOrbEffect,
    bool? hoverReactiveBall,
    bool? edgeSnap,
    double? orbIntensity,
    bool? dimBackground,
    double? dimOpacity,
    bool? launchAtLogin,
    double? overlayOpacity,
    double? overlayBlur,
    bool? showProgressRing,
    bool? hideDockIcon,
    bool? hideMenuBarItem,
    bool? hideFloatingWidget,
    bool? gentleMode,
    bool? lockScreenOnBreak,
    bool? screenTimeTracking,
    bool? activityMonitorEnabled,
    String? languageCode,
    bool? eyeDropsEnabled,
    int? eyeDropsIntervalHours,
    bool? pauseOnInactivity,
    bool? cameraPresence,
    double? uiScale,
    bool? onboardingComplete,
  }) {
    final nextHideMenuBarItem = hideMenuBarItem ?? this.hideMenuBarItem;
    final nextHideFloatingWidget =
        hideFloatingWidget ?? this.hideFloatingWidget;

    return WidgetSettings(
      cycleMinutes: cycleMinutes ?? this.cycleMinutes,
      phaseSeconds: phaseSeconds ?? this.phaseSeconds,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      visualBlinkRemindersEnabled:
          visualBlinkRemindersEnabled ?? this.visualBlinkRemindersEnabled,
      blinkReminderSoundEnabled:
          blinkReminderSoundEnabled ?? this.blinkReminderSoundEnabled,
      blinkReminderSound: blinkReminderSound ?? this.blinkReminderSound,
      blinkReminderVolume: blinkReminderVolume ?? this.blinkReminderVolume,
      defaultCorner: defaultCorner ?? this.defaultCorner,
      ballSize: ballSize ?? this.ballSize,
      idleColor: idleColor ?? this.idleColor,
      alertColor: alertColor ?? this.alertColor,
      idleOpacity: idleOpacity ?? this.idleOpacity,
      blinkMs: blinkMs ?? this.blinkMs,
      dynamicOrbEffect: dynamicOrbEffect ?? this.dynamicOrbEffect,
      hoverReactiveBall: hoverReactiveBall ?? this.hoverReactiveBall,
      edgeSnap: edgeSnap ?? this.edgeSnap,
      orbIntensity: orbIntensity ?? this.orbIntensity,
      dimBackground: dimBackground ?? this.dimBackground,
      dimOpacity: dimOpacity ?? this.dimOpacity,
      launchAtLogin: launchAtLogin ?? this.launchAtLogin,
      overlayOpacity: overlayOpacity ?? this.overlayOpacity,
      overlayBlur: overlayBlur ?? this.overlayBlur,
      showProgressRing: showProgressRing ?? this.showProgressRing,
      hideDockIcon: hideDockIcon ?? this.hideDockIcon,
      hideMenuBarItem: nextHideMenuBarItem,
      hideFloatingWidget: nextHideFloatingWidget,
      gentleMode: gentleMode ?? this.gentleMode,
      lockScreenOnBreak: lockScreenOnBreak ?? this.lockScreenOnBreak,
      screenTimeTracking: screenTimeTracking ?? this.screenTimeTracking,
      activityMonitorEnabled:
          activityMonitorEnabled ?? this.activityMonitorEnabled,
      languageCode: languageCode ?? this.languageCode,
      eyeDropsEnabled: eyeDropsEnabled ?? this.eyeDropsEnabled,
      eyeDropsIntervalHours:
          eyeDropsIntervalHours ?? this.eyeDropsIntervalHours,
      pauseOnInactivity: pauseOnInactivity ?? this.pauseOnInactivity,
      cameraPresence: cameraPresence ?? this.cameraPresence,
      uiScale: uiScale ?? this.uiScale,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    ).normalized();
  }

  /// Garante invariantes que podem ser violadas por JSON antigo/corrompido ou
  /// por construção manual fora da tela de configurações.
  WidgetSettings normalized() {
    final d = WidgetSettings.defaults();
    return WidgetSettings(
      cycleMinutes: _clampInt(cycleMinutes, 1, 60),
      phaseSeconds: _clampInt(phaseSeconds, 5, 120),
      soundEnabled: soundEnabled,
      notificationsEnabled: notificationsEnabled,
      visualBlinkRemindersEnabled: visualBlinkRemindersEnabled,
      blinkReminderSoundEnabled: blinkReminderSoundEnabled,
      blinkReminderSound: blinkReminderSound,
      blinkReminderVolume: _clampDouble(
        blinkReminderVolume,
        0.0,
        1.0,
        d.blinkReminderVolume,
      ),
      defaultCorner: defaultCorner,
      ballSize: _clampDouble(
        ballSize,
        AppDefaults.minBallSize,
        AppDefaults.maxBallSize,
        d.ballSize,
      ),
      idleColor: idleColor,
      alertColor: alertColor,
      idleOpacity: _clampDouble(idleOpacity, 0.2, 1.0, d.idleOpacity),
      blinkMs: _clampInt(blinkMs, 200, 1500),
      dynamicOrbEffect: dynamicOrbEffect,
      hoverReactiveBall: hoverReactiveBall,
      edgeSnap: edgeSnap,
      orbIntensity: _clampDouble(orbIntensity, 0.0, 1.0, d.orbIntensity),
      dimBackground: dimBackground,
      dimOpacity: _clampDouble(dimOpacity, 0.0, 0.6, d.dimOpacity),
      launchAtLogin: launchAtLogin,
      overlayOpacity: _clampDouble(overlayOpacity, 0.05, 0.4, d.overlayOpacity),
      overlayBlur: _clampDouble(overlayBlur, 0.0, 40.0, d.overlayBlur),
      showProgressRing: showProgressRing,
      hideDockIcon: hideDockIcon,
      hideMenuBarItem: hideMenuBarItem && hideFloatingWidget
          ? false
          : hideMenuBarItem,
      hideFloatingWidget: hideFloatingWidget,
      gentleMode: gentleMode,
      lockScreenOnBreak: lockScreenOnBreak,
      screenTimeTracking: screenTimeTracking,
      activityMonitorEnabled: activityMonitorEnabled,
      languageCode: languageCode == 'en' || languageCode == 'pt'
          ? languageCode
          : d.languageCode,
      eyeDropsEnabled: eyeDropsEnabled,
      eyeDropsIntervalHours:
          eyeDropsIntervalHours == 4 || eyeDropsIntervalHours == 6
          ? eyeDropsIntervalHours
          : d.eyeDropsIntervalHours,
      pauseOnInactivity: pauseOnInactivity,
      cameraPresence: cameraPresence,
      uiScale: _clampDouble(
        uiScale,
        AppDefaults.minUiScale,
        AppDefaults.maxUiScale,
        d.uiScale,
      ),
      onboardingComplete: onboardingComplete,
    );
  }

  static int _clampInt(int value, int min, int max) =>
      value.clamp(min, max).toInt();

  static double _clampDouble(
    double value,
    double min,
    double max,
    double fallback,
  ) {
    if (!value.isFinite) return fallback;
    return value.clamp(min, max).toDouble();
  }

  Map<String, dynamic> toMap() => {
    'cycleMinutes': cycleMinutes,
    'phaseSeconds': phaseSeconds,
    'soundEnabled': soundEnabled,
    'notificationsEnabled': notificationsEnabled,
    'visualBlinkRemindersEnabled': visualBlinkRemindersEnabled,
    'blinkReminderSoundEnabled': blinkReminderSoundEnabled,
    'blinkReminderSound': blinkReminderSound.index,
    'blinkReminderVolume': blinkReminderVolume,
    'defaultCorner': defaultCorner.index,
    'ballSize': ballSize,
    'idleColor': idleColor,
    'alertColor': alertColor,
    'idleOpacity': idleOpacity,
    'blinkMs': blinkMs,
    'dynamicOrbEffect': dynamicOrbEffect,
    'hoverReactiveBall': hoverReactiveBall,
    'edgeSnap': edgeSnap,
    'orbIntensity': orbIntensity,
    'dimBackground': dimBackground,
    'dimOpacity': dimOpacity,
    'launchAtLogin': launchAtLogin,
    'overlayOpacity': overlayOpacity,
    'overlayBlur': overlayBlur,
    'showProgressRing': showProgressRing,
    'hideDockIcon': hideDockIcon,
    'hideMenuBarItem': hideMenuBarItem,
    'hideFloatingWidget': hideFloatingWidget,
    'gentleMode': gentleMode,
    'lockScreenOnBreak': lockScreenOnBreak,
    'screenTimeTracking': screenTimeTracking,
    'activityMonitorEnabled': activityMonitorEnabled,
    'languageCode': languageCode,
    'eyeDropsEnabled': eyeDropsEnabled,
    'eyeDropsIntervalHours': eyeDropsIntervalHours,
    'pauseOnInactivity': pauseOnInactivity,
    'cameraPresence': cameraPresence,
    'uiScale': uiScale,
    'onboardingComplete': onboardingComplete,
  };

  /// Reconstrói a partir de um mapa, caindo para os defaults em campos
  /// ausentes ou inválidos (robusto contra versões antigas do JSON).
  factory WidgetSettings.fromMap(Map<String, dynamic> map) {
    final d = WidgetSettings.defaults();
    int cornerIndex =
        (map['defaultCorner'] as num?)?.toInt() ?? d.defaultCorner.index;
    if (cornerIndex < 0 || cornerIndex >= BallCorner.values.length) {
      cornerIndex = d.defaultCorner.index;
    }
    var blinkSoundIndex =
        (map['blinkReminderSound'] as num?)?.toInt() ??
        d.blinkReminderSound.index;
    if (blinkSoundIndex < 0 ||
        blinkSoundIndex >= BlinkReminderSound.values.length) {
      blinkSoundIndex = d.blinkReminderSound.index;
    }
    return WidgetSettings(
      cycleMinutes: (map['cycleMinutes'] as num?)?.toInt() ?? d.cycleMinutes,
      phaseSeconds: (map['phaseSeconds'] as num?)?.toInt() ?? d.phaseSeconds,
      soundEnabled: map['soundEnabled'] as bool? ?? d.soundEnabled,
      notificationsEnabled:
          map['notificationsEnabled'] as bool? ?? d.notificationsEnabled,
      visualBlinkRemindersEnabled:
          map['visualBlinkRemindersEnabled'] as bool? ??
          d.visualBlinkRemindersEnabled,
      blinkReminderSoundEnabled:
          map['blinkReminderSoundEnabled'] as bool? ??
          d.blinkReminderSoundEnabled,
      blinkReminderSound: BlinkReminderSound.values[blinkSoundIndex],
      blinkReminderVolume:
          (map['blinkReminderVolume'] as num?)?.toDouble() ??
          d.blinkReminderVolume,
      defaultCorner: BallCorner.values[cornerIndex],
      ballSize: (map['ballSize'] as num?)?.toDouble() ?? d.ballSize,
      idleColor: (map['idleColor'] as num?)?.toInt() ?? d.idleColor,
      alertColor: (map['alertColor'] as num?)?.toInt() ?? d.alertColor,
      idleOpacity: (map['idleOpacity'] as num?)?.toDouble() ?? d.idleOpacity,
      blinkMs: (map['blinkMs'] as num?)?.toInt() ?? d.blinkMs,
      dynamicOrbEffect: map['dynamicOrbEffect'] as bool? ?? d.dynamicOrbEffect,
      hoverReactiveBall:
          map['hoverReactiveBall'] as bool? ?? d.hoverReactiveBall,
      edgeSnap: map['edgeSnap'] as bool? ?? d.edgeSnap,
      orbIntensity: (map['orbIntensity'] as num?)?.toDouble() ?? d.orbIntensity,
      dimBackground: map['dimBackground'] as bool? ?? d.dimBackground,
      dimOpacity: (map['dimOpacity'] as num?)?.toDouble() ?? d.dimOpacity,
      launchAtLogin: map['launchAtLogin'] as bool? ?? d.launchAtLogin,
      overlayOpacity:
          (map['overlayOpacity'] as num?)?.toDouble() ?? d.overlayOpacity,
      overlayBlur: (map['overlayBlur'] as num?)?.toDouble() ?? d.overlayBlur,
      showProgressRing: map['showProgressRing'] as bool? ?? d.showProgressRing,
      hideDockIcon: map['hideDockIcon'] as bool? ?? d.hideDockIcon,
      hideMenuBarItem: map['hideMenuBarItem'] as bool? ?? d.hideMenuBarItem,
      hideFloatingWidget:
          map['hideFloatingWidget'] as bool? ?? d.hideFloatingWidget,
      gentleMode: map['gentleMode'] as bool? ?? d.gentleMode,
      lockScreenOnBreak:
          map['lockScreenOnBreak'] as bool? ?? d.lockScreenOnBreak,
      screenTimeTracking:
          map['screenTimeTracking'] as bool? ?? d.screenTimeTracking,
      activityMonitorEnabled:
          map['activityMonitorEnabled'] as bool? ?? d.activityMonitorEnabled,
      languageCode: map['languageCode'] as String? ?? d.languageCode,
      eyeDropsEnabled: map['eyeDropsEnabled'] as bool? ?? d.eyeDropsEnabled,
      eyeDropsIntervalHours:
          (map['eyeDropsIntervalHours'] as num?)?.toInt() ??
          d.eyeDropsIntervalHours,
      pauseOnInactivity:
          map['pauseOnInactivity'] as bool? ?? d.pauseOnInactivity,
      cameraPresence: map['cameraPresence'] as bool? ?? d.cameraPresence,
      uiScale: (map['uiScale'] as num?)?.toDouble() ?? d.uiScale,
      onboardingComplete:
          map['onboardingComplete'] as bool? ?? d.onboardingComplete,
    ).normalized();
  }

  String toJson() => jsonEncode(toMap());

  factory WidgetSettings.fromJson(String source) {
    try {
      return WidgetSettings.fromMap(jsonDecode(source) as Map<String, dynamic>);
    } catch (_) {
      return WidgetSettings.defaults();
    }
  }
}
