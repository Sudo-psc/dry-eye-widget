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
    required this.defaultCorner,
    required this.ballSize,
    required this.idleColor,
    required this.alertColor,
    required this.idleOpacity,
    required this.blinkMs,
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
    required this.languageCode,
    required this.eyeDropsEnabled,
    required this.eyeDropsIntervalHours,
    required this.pauseOnInactivity,
  });

  // --- Temporização / som -------------------------------------------------
  final int cycleMinutes;
  final int phaseSeconds;
  final bool soundEnabled;
  final bool notificationsEnabled;
  final BallCorner defaultCorner;

  // --- Aparência ----------------------------------------------------------
  /// Diâmetro da bolinha em pixels.
  final double ballSize;

  /// Cor da bolinha no estado IDLE (valor ARGB).
  final int idleColor;

  /// Cor da bolinha em alerta/pausa (valor ARGB).
  final int alertColor;

  /// Opacidade da bolinha no IDLE (0.3–1.0) para deixá-la mais discreta.
  final double idleOpacity;

  /// Intervalo do piscar em milissegundos.
  final int blinkMs;

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

  /// Idioma da interface: 'pt' ou 'en'.
  final String languageCode;

  /// Lembrete de colírio ligado/desligado.
  final bool eyeDropsEnabled;

  /// Intervalo do lembrete de colírio em horas (4 ou 6).
  final int eyeDropsIntervalHours;

  /// Pausar o timer automaticamente após inatividade do sistema.
  final bool pauseOnInactivity;

  /// Valores de fábrica.
  factory WidgetSettings.defaults() => const WidgetSettings(
        cycleMinutes: AppDefaults.cycleMinutes,
        phaseSeconds: AppDefaults.phaseSeconds,
        soundEnabled: AppDefaults.soundEnabled,
        notificationsEnabled: AppDefaults.notificationsEnabled,
        defaultCorner: BallCorner.topRight,
        ballSize: AppDefaults.ballSize,
        idleColor: AppDefaults.idleColor,
        alertColor: AppDefaults.alertColor,
        idleOpacity: AppDefaults.idleOpacity,
        blinkMs: AppDefaults.blinkMs,
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
        languageCode: AppDefaults.languageCode,
        eyeDropsEnabled: AppDefaults.eyeDropsEnabled,
        eyeDropsIntervalHours: AppDefaults.eyeDropsIntervalHours,
        pauseOnInactivity: AppDefaults.pauseOnInactivity,
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
    BallCorner? defaultCorner,
    double? ballSize,
    int? idleColor,
    int? alertColor,
    double? idleOpacity,
    int? blinkMs,
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
    String? languageCode,
    bool? eyeDropsEnabled,
    int? eyeDropsIntervalHours,
    bool? pauseOnInactivity,
  }) {
    return WidgetSettings(
      cycleMinutes: cycleMinutes ?? this.cycleMinutes,
      phaseSeconds: phaseSeconds ?? this.phaseSeconds,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      defaultCorner: defaultCorner ?? this.defaultCorner,
      ballSize: ballSize ?? this.ballSize,
      idleColor: idleColor ?? this.idleColor,
      alertColor: alertColor ?? this.alertColor,
      idleOpacity: idleOpacity ?? this.idleOpacity,
      blinkMs: blinkMs ?? this.blinkMs,
      dimBackground: dimBackground ?? this.dimBackground,
      dimOpacity: dimOpacity ?? this.dimOpacity,
      launchAtLogin: launchAtLogin ?? this.launchAtLogin,
      overlayOpacity: overlayOpacity ?? this.overlayOpacity,
      overlayBlur: overlayBlur ?? this.overlayBlur,
      showProgressRing: showProgressRing ?? this.showProgressRing,
      hideDockIcon: hideDockIcon ?? this.hideDockIcon,
      hideMenuBarItem: hideMenuBarItem ?? this.hideMenuBarItem,
      hideFloatingWidget: hideFloatingWidget ?? this.hideFloatingWidget,
      gentleMode: gentleMode ?? this.gentleMode,
      languageCode: languageCode ?? this.languageCode,
      eyeDropsEnabled: eyeDropsEnabled ?? this.eyeDropsEnabled,
      eyeDropsIntervalHours:
          eyeDropsIntervalHours ?? this.eyeDropsIntervalHours,
      pauseOnInactivity: pauseOnInactivity ?? this.pauseOnInactivity,
    );
  }

  Map<String, dynamic> toMap() => {
        'cycleMinutes': cycleMinutes,
        'phaseSeconds': phaseSeconds,
        'soundEnabled': soundEnabled,
        'notificationsEnabled': notificationsEnabled,
        'defaultCorner': defaultCorner.index,
        'ballSize': ballSize,
        'idleColor': idleColor,
        'alertColor': alertColor,
        'idleOpacity': idleOpacity,
        'blinkMs': blinkMs,
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
        'languageCode': languageCode,
        'eyeDropsEnabled': eyeDropsEnabled,
        'eyeDropsIntervalHours': eyeDropsIntervalHours,
        'pauseOnInactivity': pauseOnInactivity,
      };

  /// Reconstrói a partir de um mapa, caindo para os defaults em campos
  /// ausentes ou inválidos (robusto contra versões antigas do JSON).
  factory WidgetSettings.fromMap(Map<String, dynamic> map) {
    final d = WidgetSettings.defaults();
    int cornerIndex = (map['defaultCorner'] as num?)?.toInt() ?? d.defaultCorner.index;
    if (cornerIndex < 0 || cornerIndex >= BallCorner.values.length) {
      cornerIndex = d.defaultCorner.index;
    }
    return WidgetSettings(
      cycleMinutes: (map['cycleMinutes'] as num?)?.toInt() ?? d.cycleMinutes,
      phaseSeconds: (map['phaseSeconds'] as num?)?.toInt() ?? d.phaseSeconds,
      soundEnabled: map['soundEnabled'] as bool? ?? d.soundEnabled,
      notificationsEnabled:
          map['notificationsEnabled'] as bool? ?? d.notificationsEnabled,
      defaultCorner: BallCorner.values[cornerIndex],
      ballSize: (map['ballSize'] as num?)?.toDouble() ?? d.ballSize,
      idleColor: (map['idleColor'] as num?)?.toInt() ?? d.idleColor,
      alertColor: (map['alertColor'] as num?)?.toInt() ?? d.alertColor,
      idleOpacity: (map['idleOpacity'] as num?)?.toDouble() ?? d.idleOpacity,
      blinkMs: (map['blinkMs'] as num?)?.toInt() ?? d.blinkMs,
      dimBackground: map['dimBackground'] as bool? ?? d.dimBackground,
      dimOpacity: (map['dimOpacity'] as num?)?.toDouble() ?? d.dimOpacity,
      launchAtLogin: map['launchAtLogin'] as bool? ?? d.launchAtLogin,
      overlayOpacity:
          (map['overlayOpacity'] as num?)?.toDouble() ?? d.overlayOpacity,
      overlayBlur: (map['overlayBlur'] as num?)?.toDouble() ?? d.overlayBlur,
      showProgressRing:
          map['showProgressRing'] as bool? ?? d.showProgressRing,
      hideDockIcon: map['hideDockIcon'] as bool? ?? d.hideDockIcon,
      hideMenuBarItem: map['hideMenuBarItem'] as bool? ?? d.hideMenuBarItem,
      hideFloatingWidget:
          map['hideFloatingWidget'] as bool? ?? d.hideFloatingWidget,
      gentleMode: map['gentleMode'] as bool? ?? d.gentleMode,
      languageCode: map['languageCode'] as String? ?? d.languageCode,
      eyeDropsEnabled: map['eyeDropsEnabled'] as bool? ?? d.eyeDropsEnabled,
      eyeDropsIntervalHours:
          (map['eyeDropsIntervalHours'] as num?)?.toInt() ??
              d.eyeDropsIntervalHours,
      pauseOnInactivity:
          map['pauseOnInactivity'] as bool? ?? d.pauseOnInactivity,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory WidgetSettings.fromJson(String source) {
    try {
      return WidgetSettings.fromMap(
          jsonDecode(source) as Map<String, dynamic>);
    } catch (_) {
      return WidgetSettings.defaults();
    }
  }
}
