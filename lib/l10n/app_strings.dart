import '../models/app_state.dart';

/// Conjunto de textos do app em um idioma. Há duas instâncias const:
/// [ptStrings] e [enStrings]. O idioma ativo vem do `SettingsProvider`.
class AppStrings {
  const AppStrings({
    required this.languageCode,
    // Menu / bandeja
    required this.menuStartBreak,
    required this.menuReset,
    required this.menuPause,
    required this.menuResume,
    required this.menuGuidance,
    required this.menuOsdi,
    required this.menuScreenTime,
    required this.menuCheckUpdates,
    required this.menuSettings,
    required this.menuQuit,
    required this.menuGitHub,
    required this.menuAbout,
    required this.aboutDescription,
    required this.aboutAuthorLabel,
    required this.aboutAuthorRole,
    required this.trayDisable,
    required this.trayEnable,
    // Estados
    required this.alertTitle,
    required this.alertSubtitle,
    required this.phaseTitle,
    required this.phaseSubtitle,
    required this.doneTitle,
    required this.doneSubtitle,
    // Notificações
    required this.notifyBreakTitle,
    required this.notifyBreakBody,
    required this.notifyDoneTitle,
    required this.notifyDoneBody,
    // Configurações
    required this.settingsTitle,
    required this.secTiming,
    required this.secAppearance,
    required this.secDuringBreak,
    required this.secVisibility,
    required this.secGeneral,
    required this.secLanguage,
    required this.workCycle,
    required this.breakDuration,
    required this.ballSize,
    required this.colorNormal,
    required this.colorAlert,
    required this.opacityNormal,
    required this.blinkSpeed,
    required this.progressRing,
    required this.dynamicOrbEffect,
    required this.hoverReactiveBall,
    required this.orbIntensity,
    required this.gentleMode,
    required this.gentleHint,
    required this.lockScreenOnBreak,
    required this.lockScreenHint,
    required this.dimBackground,
    required this.dimIntensity,
    required this.overlayOpacity,
    required this.overlayBlur,
    required this.enableSound,
    required this.enableNotifications,
    required this.visualBlinkReminders,
    required this.visualBlinkRemindersHint,
    required this.blinkReminderText,
    required this.blinkReminderSound,
    required this.blinkReminderSoundHint,
    required this.blinkReminderVolume,
    required this.blinkReminderToneSoftPulse,
    required this.blinkReminderToneClearDrop,
    required this.blinkReminderToneWarmBell,
    required this.blinkReminderToneLightTick,
    required this.launchAtLogin,
    required this.hideDock,
    required this.disableMenuBar,
    required this.disableFloating,
    required this.exclusivityHint,
    required this.defaultPosition,
    required this.cornerTopLeft,
    required this.cornerTopRight,
    required this.cornerBottomLeft,
    required this.cornerBottomRight,
    required this.cornerCenter,
    required this.restoreDefaults,
    required this.save,
    required this.unitMin,
    required this.unitSec,
    // Orientações
    required this.guidanceTitle,
    required this.cvsTitle,
    required this.cvsBody,
    required this.dryEyeTitle,
    required this.dryEyeBody,
    required this.ruleTitle,
    required this.ruleBody,
    required this.statsTitle,
    required this.stat1Value,
    required this.stat1Text,
    required this.stat2Value,
    required this.stat2Text,
    required this.stat3Value,
    required this.stat3Text,
    required this.refsTitle,
    required this.disclaimer,
    // Colírio
    required this.secEyeDrops,
    required this.eyeDropsEnable,
    required this.eyeDropsInterval,
    required this.eyeDropsEvery4h,
    required this.eyeDropsEvery6h,
    required this.eyeDropsTitle,
    required this.eyeDropsBody,
    required this.eyeDropsDone,
    required this.eyeDropsNotifyTitle,
    required this.eyeDropsNotifyBody,
    // Atualização
    required this.updateUpToDate,
    required this.updateAvailable,
    required this.updateDownload,
    required this.updateError,
    required this.updateChecking,
    required this.updateMacInstallTitle,
    required this.updateMacInstallSteps,
    required this.updateCopyCommand,
    required this.updateCommandCopied,
    required this.close,
    // OSDI
    required this.osdiTitle,
    required this.osdiSubtitle,
    required this.osdiInstruction,
    required this.osdiHistoryTitle,
    required this.osdiNoHistory,
    required this.osdiSave,
    required this.osdiReset,
    required this.osdiScoreLabel,
    required this.osdiAnsweredLabel,
    required this.osdiLatestLabel,
    required this.osdiSeverityNormal,
    required this.osdiSeverityMild,
    required this.osdiSeverityModerate,
    required this.osdiSeveritySevere,
    required this.osdiTrendBetter,
    required this.osdiTrendWorse,
    required this.osdiTrendSame,
    required this.osdiNotApplicable,
    required this.osdiAnswerLabels,
    required this.osdiQuestions,
    required this.osdiDisclaimer,
    // Inatividade
    required this.pauseOnInactivityLabel,
    required this.inactivityTitle,
    required this.inactivityBody,
    required this.inactivityContinue,
    required this.secInactivity,
    required this.resetLearningLabel,
    required this.cameraPresenceLabel,
    required this.cameraPresenceHint,
    required this.cameraUnavailableHint,
    required this.cameraConsentTitle,
    required this.cameraConsentBody,
    required this.cameraConsentAllow,
    required this.cameraConsentCancel,
    // Tempo de tela
    required this.secScreenTime,
    required this.screenTimeEnable,
    required this.screenTimeHint,
    required this.screenTimeView,
    required this.screenTimeTitle,
    required this.screenTimeSubtitle,
    required this.screenTimeToday,
    required this.screenTimeWeek,
    required this.screenTimeMonth,
    required this.screenTimeYear,
    required this.screenTimeTotal,
    required this.screenTimeDailyAverage,
    required this.screenTimeNoData,
    required this.screenTimeClear,
    required this.screenTimeDisabledHint,
    required this.screenTimeDisclaimer,
    required this.unitHour,
    required this.weekdayShort,
    required this.monthShort,
  });

  final String languageCode;

  final String menuStartBreak;
  final String menuReset;
  final String menuPause;
  final String menuResume;
  final String menuGuidance;
  final String menuOsdi;
  final String menuScreenTime;
  final String menuCheckUpdates;
  final String menuSettings;
  final String menuQuit;
  final String menuGitHub;
  final String menuAbout;
  final String aboutDescription;
  final String aboutAuthorLabel;
  final String aboutAuthorRole;
  final String trayDisable;
  final String trayEnable;

  final String alertTitle;
  final String alertSubtitle;
  final String phaseTitle;
  final String phaseSubtitle;
  final String doneTitle;
  final String doneSubtitle;

  final String notifyBreakTitle;
  final String notifyBreakBody;
  final String notifyDoneTitle;
  final String notifyDoneBody;

  final String settingsTitle;
  final String secTiming;
  final String secAppearance;
  final String secDuringBreak;
  final String secVisibility;
  final String secGeneral;
  final String secLanguage;
  final String workCycle;
  final String breakDuration;
  final String ballSize;
  final String colorNormal;
  final String colorAlert;
  final String opacityNormal;
  final String blinkSpeed;
  final String progressRing;
  final String dynamicOrbEffect;
  final String hoverReactiveBall;
  final String orbIntensity;
  final String gentleMode;
  final String gentleHint;
  final String lockScreenOnBreak;
  final String lockScreenHint;
  final String dimBackground;
  final String dimIntensity;
  final String overlayOpacity;
  final String overlayBlur;
  final String enableSound;
  final String enableNotifications;
  final String visualBlinkReminders;
  final String visualBlinkRemindersHint;
  final String blinkReminderText;
  final String blinkReminderSound;
  final String blinkReminderSoundHint;
  final String blinkReminderVolume;
  final String blinkReminderToneSoftPulse;
  final String blinkReminderToneClearDrop;
  final String blinkReminderToneWarmBell;
  final String blinkReminderToneLightTick;
  final String launchAtLogin;
  final String hideDock;
  final String disableMenuBar;
  final String disableFloating;
  final String exclusivityHint;
  final String defaultPosition;
  final String cornerTopLeft;
  final String cornerTopRight;
  final String cornerBottomLeft;
  final String cornerBottomRight;
  final String cornerCenter;
  final String restoreDefaults;
  final String save;
  final String unitMin;
  final String unitSec;

  final String guidanceTitle;
  final String cvsTitle;
  final String cvsBody;
  final String dryEyeTitle;
  final String dryEyeBody;
  final String ruleTitle;
  final String ruleBody;
  final String statsTitle;
  final String stat1Value;
  final String stat1Text;
  final String stat2Value;
  final String stat2Text;
  final String stat3Value;
  final String stat3Text;
  final String refsTitle;
  final String disclaimer;

  final String secEyeDrops;
  final String eyeDropsEnable;
  final String eyeDropsInterval;
  final String eyeDropsEvery4h;
  final String eyeDropsEvery6h;
  final String eyeDropsTitle;
  final String eyeDropsBody;
  final String eyeDropsDone;
  final String eyeDropsNotifyTitle;
  final String eyeDropsNotifyBody;

  final String updateUpToDate;
  final String updateAvailable;
  final String updateDownload;
  final String updateError;
  final String updateChecking;
  final String updateMacInstallTitle;
  final String updateMacInstallSteps;
  final String updateCopyCommand;
  final String updateCommandCopied;
  final String close;

  final String osdiTitle;
  final String osdiSubtitle;
  final String osdiInstruction;
  final String osdiHistoryTitle;
  final String osdiNoHistory;
  final String osdiSave;
  final String osdiReset;
  final String osdiScoreLabel;
  final String osdiAnsweredLabel;
  final String osdiLatestLabel;
  final String osdiSeverityNormal;
  final String osdiSeverityMild;
  final String osdiSeverityModerate;
  final String osdiSeveritySevere;
  final String osdiTrendBetter;
  final String osdiTrendWorse;
  final String osdiTrendSame;
  final String osdiNotApplicable;
  final List<String> osdiAnswerLabels;
  final List<String> osdiQuestions;
  final String osdiDisclaimer;

  final String pauseOnInactivityLabel;
  final String inactivityTitle;
  final String inactivityBody;
  final String inactivityContinue;
  final String secInactivity;
  final String resetLearningLabel;
  final String cameraPresenceLabel;
  final String cameraPresenceHint;
  final String cameraUnavailableHint;
  final String cameraConsentTitle;
  final String cameraConsentBody;
  final String cameraConsentAllow;
  final String cameraConsentCancel;

  final String secScreenTime;
  final String screenTimeEnable;
  final String screenTimeHint;
  final String screenTimeView;
  final String screenTimeTitle;
  final String screenTimeSubtitle;
  final String screenTimeToday;
  final String screenTimeWeek;
  final String screenTimeMonth;
  final String screenTimeYear;
  final String screenTimeTotal;
  final String screenTimeDailyAverage;
  final String screenTimeNoData;
  final String screenTimeClear;
  final String screenTimeDisabledHint;
  final String screenTimeDisclaimer;
  final String unitHour;

  /// Rótulos curtos dos dias da semana (segunda a domingo).
  final List<String> weekdayShort;

  /// Rótulos curtos dos meses (janeiro a dezembro).
  final List<String> monthShort;

  // --- Helpers dependentes de enum --------------------------------------

  String stateTitle(AppState state) {
    switch (state) {
      case AppState.idle:
        return '';
      case AppState.alerta:
        return alertTitle;
      case AppState.fase1:
        return phaseTitle;
      case AppState.conclusao:
        return doneTitle;
    }
  }

  String stateSubtitle(AppState state) {
    switch (state) {
      case AppState.idle:
        return '';
      case AppState.alerta:
        return alertSubtitle;
      case AppState.fase1:
        return phaseSubtitle;
      case AppState.conclusao:
        return doneSubtitle;
    }
  }

  String cornerLabel(BallCorner corner) {
    switch (corner) {
      case BallCorner.topLeft:
        return cornerTopLeft;
      case BallCorner.topRight:
        return cornerTopRight;
      case BallCorner.bottomLeft:
        return cornerBottomLeft;
      case BallCorner.bottomRight:
        return cornerBottomRight;
      case BallCorner.center:
        return cornerCenter;
    }
  }

  String blinkReminderSoundLabel(BlinkReminderSound sound) {
    switch (sound) {
      case BlinkReminderSound.softPulse:
        return blinkReminderToneSoftPulse;
      case BlinkReminderSound.clearDrop:
        return blinkReminderToneClearDrop;
      case BlinkReminderSound.warmBell:
        return blinkReminderToneWarmBell;
      case BlinkReminderSound.lightTick:
        return blinkReminderToneLightTick;
    }
  }

  static AppStrings of(String code) => code == 'en' ? enStrings : ptStrings;
}

const AppStrings ptStrings = AppStrings(
  languageCode: 'pt',
  menuStartBreak: 'Iniciar pausa agora',
  menuReset: 'Resetar cronômetro',
  menuPause: 'Pausar cronômetro',
  menuResume: 'Retomar cronômetro',
  menuGuidance: 'Orientações',
  menuOsdi: 'Questionário OSDI',
  menuScreenTime: 'Tempo de tela',
  menuCheckUpdates: 'Verificar atualizações',
  menuSettings: 'Configurações',
  menuQuit: 'Sair',
  menuGitHub: 'GitHub',
  menuAbout: 'Sobre',
  aboutDescription:
      'Lembretes da regra 20-20-20 para descanso visual durante o uso '
      'prolongado de telas, ajudando a aliviar a fadiga ocular digital. '
      'Funciona localmente, sem coletar dados de atividade nem enviar '
      'informações para fora do computador.',
  aboutAuthorLabel: 'AUTOR',
  aboutAuthorRole: 'Médico oftalmologista',
  trayDisable: 'Desabilitar widget',
  trayEnable: 'Habilitar widget',
  alertTitle: 'Tire uma pausa de 20 segundos',
  alertSubtitle: 'Vou iniciar um cronômetro',
  phaseTitle: 'Olhe para longe e pisque devagar',
  phaseSubtitle:
      'Foque a cerca de 6 metros e continue a piscar lenta e completamente '
      'até o cronômetro zerar.',
  doneTitle: 'Parabéns!',
  doneSubtitle:
      'Você renovou suas lágrimas. Volte ao trabalho com os olhos descansados',
  notifyBreakTitle: 'Hora da pausa 👀',
  notifyBreakBody: 'Descanse os olhos por alguns segundos.',
  notifyDoneTitle: 'Pausa concluída ✅',
  notifyDoneBody: 'Lágrimas renovadas! Voltando ao trabalho.',
  settingsTitle: 'Configurações',
  secTiming: 'Temporização',
  secAppearance: 'Aparência',
  secDuringBreak: 'Durante a pausa',
  secVisibility: 'Visibilidade',
  secGeneral: 'Geral',
  secLanguage: 'Idioma',
  workCycle: 'Ciclo de trabalho',
  breakDuration: 'Duração da pausa',
  ballSize: 'Tamanho da bolinha',
  colorNormal: 'Cor (normal)',
  colorAlert: 'Cor (alerta)',
  opacityNormal: 'Opacidade (normal)',
  blinkSpeed: 'Velocidade do piscar',
  progressRing: 'Anel de progresso',
  dynamicOrbEffect: 'Efeito dinâmico na bolinha',
  hoverReactiveBall: 'Reagir ao passar o mouse',
  orbIntensity: 'Intensidade do efeito',
  gentleMode: 'Notificações suaves (não bloquear a tela)',
  gentleHint:
      'Mostra apenas um cartão pequeno no canto superior direito, em '
      'vez do aviso em tela cheia.',
  lockScreenOnBreak: 'Bloquear a tela na pausa',
  lockScreenHint:
      'Mostra o aviso em tela cheia durante a pausa mesmo com as '
      'notificações suaves ligadas, para forçar o descanso.',
  dimBackground: 'Escurecer o fundo',
  dimIntensity: 'Intensidade do escurecimento',
  overlayOpacity: 'Opacidade do overlay',
  overlayBlur: 'Desfoque do overlay',
  enableSound: 'Som dos avisos 20-20-20',
  enableNotifications: 'Ativar notificações',
  visualBlinkReminders: 'Lembretes visuais de piscada',
  visualBlinkRemindersHint:
      'Mostra um aviso delicado no widget a cada 7,5 s, sem notificação '
      'do sistema.',
  blinkReminderText: 'Pisque',
  blinkReminderSound: 'Aviso sonoro de piscada',
  blinkReminderSoundHint:
      'Toca um som curto e suave junto do lembrete de piscada. Tem controle '
      'próprio, independente do som dos avisos 20-20-20.',
  blinkReminderVolume: 'Volume do aviso sonoro',
  blinkReminderToneSoftPulse: 'Pulso suave',
  blinkReminderToneClearDrop: 'Gota clara',
  blinkReminderToneWarmBell: 'Sino quente',
  blinkReminderToneLightTick: 'Toque leve',
  launchAtLogin: 'Iniciar com o sistema',
  hideDock: 'Ocultar ícone do Dock',
  disableMenuBar: 'Desabilitar item da barra de menu',
  disableFloating: 'Desabilitar widget flutuante',
  exclusivityHint:
      'Não é possível ocultar o widget e a barra de menu ao mesmo tempo.',
  defaultPosition: 'Posição padrão da bolinha',
  cornerTopLeft: 'Superior esquerdo',
  cornerTopRight: 'Superior direito',
  cornerBottomLeft: 'Inferior esquerdo',
  cornerBottomRight: 'Inferior direito',
  cornerCenter: 'Centro',
  restoreDefaults: 'Restaurar padrões',
  save: 'Salvar',
  unitMin: 'min',
  unitSec: 's',
  guidanceTitle: 'Orientações — Saúde Ocular Digital',
  cvsTitle: 'Síndrome da Visão de Computador',
  cvsBody:
      'O uso prolongado de telas pode causar a Síndrome da Visão de '
      'Computador (fadiga visual digital): cansaço nos olhos, ardência, visão '
      'embaçada, dor de cabeça e sensação de olhos secos. É frequente em quem '
      'passa muitas horas no computador, tablet ou celular.',
  dryEyeTitle: 'Olho seco',
  dryEyeBody:
      'Diante das telas tendemos a piscar bem menos. Piscar espalha o '
      'filme lacrimal que lubrifica e protege os olhos; piscando menos, a '
      'lágrima evapora mais rápido e surge o desconforto do olho seco. Não é à '
      'toa que ele é tão comum entre quem trabalha no digital.',
  ruleTitle: 'Regra 20-20-20',
  ruleBody:
      'A cada 20 minutos, olhe para algo a cerca de 6 metros (20 pés) '
      'por 20 segundos — e pisque algumas vezes, devagar e completo. Esses 20 '
      'segundos relaxam o foco e ajudam a renovar a lágrima. É exatamente o '
      'que este app lembra você de fazer.',
  statsTitle: 'O que dizem os estudos',
  stat1Value: '~50%',
  stat1Text:
      'dos trabalhadores que usam telas têm olho seco — em alguns '
      'estudos, perto de 60% [1].',
  stat2Value: '~30%',
  stat2Text:
      'de queda no desempenho no trabalho (presenteísmo) em quem tem '
      'olho seco sintomático [2].',
  stat3Value: 'até 14%',
  stat3Text:
      'mais lenta fica a leitura prolongada por causa do olho seco '
      '[3, 4].',
  refsTitle: 'Referências',
  disclaimer:
      'Conteúdo educativo — não substitui a avaliação de um '
      'oftalmologista. Sintomas persistentes merecem consulta.',
  secEyeDrops: 'Colírio',
  eyeDropsEnable: 'Lembrete de colírio',
  eyeDropsInterval: 'Lembrar a cada',
  eyeDropsEvery4h: '4 horas',
  eyeDropsEvery6h: '6 horas',
  eyeDropsTitle: 'Hora do colírio',
  eyeDropsBody:
      'Está na hora de pingar o seu colírio. Aplique e siga '
      'cuidando dos seus olhos.',
  eyeDropsDone: 'Apliquei',
  eyeDropsNotifyTitle: 'Hora do colírio 💧',
  eyeDropsNotifyBody: 'Está na hora de pingar o seu colírio.',
  updateUpToDate: 'Seu app está atualizado.',
  updateAvailable: 'Nova versão {v} disponível — baixe e atualize o app.',
  updateDownload: 'Baixar',
  updateError:
      'Não foi possível verificar atualizações agora. '
      'Tente novamente mais tarde.',
  updateChecking: 'Verificando atualizações…',
  updateMacInstallTitle: 'Instalar a atualização no macOS',
  updateMacInstallSteps:
      'Baixe o .dmg, rode o comando abaixo no Terminal para liberá-lo e então '
      'abra o arquivo e arraste o app para Aplicativos, substituindo a versão '
      'atual.',
  updateCopyCommand: 'Copiar comando',
  updateCommandCopied: 'Comando copiado',
  close: 'Fechar',
  osdiTitle: 'Questionário OSDI',
  osdiSubtitle: 'Acompanhe sintomas de olho seco ao longo do tempo.',
  osdiInstruction:
      'Na última semana, com que frequência você percebeu cada situação?',
  osdiHistoryTitle: 'Histórico e comparação',
  osdiNoHistory: 'Nenhum resultado salvo ainda.',
  osdiSave: 'Salvar resultado',
  osdiReset: 'Limpar respostas',
  osdiScoreLabel: 'Pontuação OSDI: {score}',
  osdiAnsweredLabel: '{count}/12 respondidas',
  osdiLatestLabel: 'Último resultado',
  osdiSeverityNormal: 'Normal',
  osdiSeverityMild: 'Leve',
  osdiSeverityModerate: 'Moderado',
  osdiSeveritySevere: 'Severo',
  osdiTrendBetter: 'Melhorou {delta} pontos',
  osdiTrendWorse: 'Piorou {delta} pontos',
  osdiTrendSame: 'Estável',
  osdiNotApplicable: 'Não se aplica',
  osdiAnswerLabels: [
    'Nunca',
    'Raramente',
    'Às vezes',
    'Frequentemente',
    'Sempre',
  ],
  osdiQuestions: [
    'Olhos sensíveis à luz',
    'Sensação de areia ou corpo estranho nos olhos',
    'Dor ou desconforto ocular',
    'Visão embaçada',
    'Visão ruim ou instável',
    'Dificuldade para ler',
    'Dificuldade para dirigir à noite',
    'Dificuldade para trabalhar no computador ou usar caixa eletrônico',
    'Dificuldade para assistir TV',
    'Desconforto em locais com vento',
    'Desconforto em locais secos ou com baixa umidade',
    'Desconforto em ambientes com ar-condicionado',
  ],
  osdiDisclaimer:
      'Triagem educativa. O resultado não substitui avaliação oftalmológica.',
  pauseOnInactivityLabel: 'Pausar por inatividade (adaptativo)',
  inactivityTitle: 'Timer pausado',
  inactivityBody:
      'Inatividade detectada. O ciclo será retomado quando você voltar.',
  inactivityContinue: 'Retomar',
  secInactivity: 'Inatividade',
  resetLearningLabel: 'Resetar aprendizado de inatividade',
  cameraPresenceLabel: 'Confirmar presença pela câmera',
  cameraPresenceHint:
      'Quando ocioso, tira uma única foto para checar se há um rosto e a '
      'descarta na hora. Nada é gravado nem enviado.',
  cameraUnavailableHint: 'Disponível apenas no macOS por enquanto.',
  cameraConsentTitle: 'Usar a câmera para confirmar presença?',
  cameraConsentBody:
      'Ao detectar inatividade, o app tira uma única foto, verifica se há um '
      'rosto à frente da tela e descarta a imagem imediatamente. O '
      'processamento é local; nada é gravado em disco nem enviado pela rede. '
      'Você pode desligar a qualquer momento. O macOS pedirá a permissão de '
      'câmera na primeira vez.',
  cameraConsentAllow: 'Permitir',
  cameraConsentCancel: 'Agora não',
  secScreenTime: 'Tempo de tela',
  screenTimeEnable: 'Coletar tempo de tela',
  screenTimeHint:
      'Mede o tempo de uso ativo de tela por dia, descartando a '
      'inatividade. Os dados ficam só no seu computador.',
  screenTimeView: 'Ver tempo de tela',
  screenTimeTitle: 'Tempo de tela',
  screenTimeSubtitle: 'Seu uso ativo de tela ao longo do tempo.',
  screenTimeToday: 'Hoje',
  screenTimeWeek: 'Semana',
  screenTimeMonth: 'Mês',
  screenTimeYear: 'Ano',
  screenTimeTotal: 'Total',
  screenTimeDailyAverage: 'Média diária',
  screenTimeNoData: 'Sem dados de uso ainda.',
  screenTimeClear: 'Limpar histórico',
  screenTimeDisabledHint:
      'A coleta de tempo de tela está desativada. Ative nas configurações '
      'para acompanhar seu uso.',
  screenTimeDisclaimer:
      'Estimativa local baseada no tempo ativo do app; não substitui '
      'medições do sistema operacional.',
  unitHour: 'h',
  weekdayShort: ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'],
  monthShort: [
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez',
  ],
);

const AppStrings enStrings = AppStrings(
  languageCode: 'en',
  menuStartBreak: 'Start break now',
  menuReset: 'Reset timer',
  menuPause: 'Pause timer',
  menuResume: 'Resume timer',
  menuGuidance: 'Eye care guide',
  menuOsdi: 'OSDI questionnaire',
  menuScreenTime: 'Screen time',
  menuCheckUpdates: 'Check for updates',
  menuSettings: 'Settings',
  menuQuit: 'Quit',
  menuGitHub: 'GitHub',
  menuAbout: 'About',
  aboutDescription:
      'A 20-20-20 rule reminder for visual rest during prolonged screen '
      'use, helping to ease digital eye strain. It runs locally, without '
      'collecting activity data or sending information off your computer.',
  aboutAuthorLabel: 'AUTHOR',
  aboutAuthorRole: 'Ophthalmologist (MD)',
  trayDisable: 'Disable widget',
  trayEnable: 'Enable widget',
  alertTitle: 'Take a 20-second break',
  alertSubtitle: 'Starting a timer',
  phaseTitle: 'Look away and blink slowly',
  phaseSubtitle:
      'Focus about 6 m (20 ft) away. Blink slowly and fully until the timer '
      'reaches zero.',
  doneTitle: 'Well done!',
  doneSubtitle: 'You refreshed your tears. Back to work with rested eyes',
  notifyBreakTitle: 'Time for a break 👀',
  notifyBreakBody: 'Rest your eyes for a few seconds.',
  notifyDoneTitle: 'Break complete ✅',
  notifyDoneBody: 'Tears refreshed! Back to work.',
  settingsTitle: 'Settings',
  secTiming: 'Timing',
  secAppearance: 'Appearance',
  secDuringBreak: 'During the break',
  secVisibility: 'Visibility',
  secGeneral: 'General',
  secLanguage: 'Language',
  workCycle: 'Work cycle',
  breakDuration: 'Break duration',
  ballSize: 'Ball size',
  colorNormal: 'Color (normal)',
  colorAlert: 'Color (alert)',
  opacityNormal: 'Opacity (normal)',
  blinkSpeed: 'Blink speed',
  progressRing: 'Progress ring',
  dynamicOrbEffect: 'Dynamic ball effect',
  hoverReactiveBall: 'React on mouse hover',
  orbIntensity: 'Effect intensity',
  gentleMode: "Gentle notifications (don't block the screen)",
  gentleHint:
      'Shows just a small card in the top-right corner instead of the '
      'full-screen alert.',
  lockScreenOnBreak: 'Lock the screen on break',
  lockScreenHint:
      'Shows the full-screen alert during the break even with gentle '
      'notifications on, to enforce the rest.',
  dimBackground: 'Dim the background',
  dimIntensity: 'Dim intensity',
  overlayOpacity: 'Overlay opacity',
  overlayBlur: 'Overlay blur',
  enableSound: '20-20-20 break sound',
  enableNotifications: 'Enable notifications',
  visualBlinkReminders: 'Visual blink reminders',
  visualBlinkRemindersHint:
      'Shows a delicate cue in the widget every 7.5 s, without a system '
      'notification.',
  blinkReminderText: 'Blink',
  blinkReminderSound: 'Blink sound reminder',
  blinkReminderSoundHint:
      'Plays a short, gentle sound with the blink reminder. It has its own '
      'control, independent from the 20-20-20 break sound.',
  blinkReminderVolume: 'Sound reminder volume',
  blinkReminderToneSoftPulse: 'Soft pulse',
  blinkReminderToneClearDrop: 'Clear drop',
  blinkReminderToneWarmBell: 'Warm bell',
  blinkReminderToneLightTick: 'Light tap',
  launchAtLogin: 'Launch at startup',
  hideDock: 'Hide Dock icon',
  disableMenuBar: 'Disable menu bar item',
  disableFloating: 'Disable floating widget',
  exclusivityHint:
      "You can't hide both the widget and the menu bar item at the same time.",
  defaultPosition: 'Default ball position',
  cornerTopLeft: 'Top left',
  cornerTopRight: 'Top right',
  cornerBottomLeft: 'Bottom left',
  cornerBottomRight: 'Bottom right',
  cornerCenter: 'Center',
  restoreDefaults: 'Restore defaults',
  save: 'Save',
  unitMin: 'min',
  unitSec: 's',
  guidanceTitle: 'Guidance — Digital Eye Health',
  cvsTitle: 'Computer Vision Syndrome',
  cvsBody:
      'Prolonged screen use can cause Computer Vision Syndrome (digital '
      'eye strain): tired eyes, burning, blurred vision, headaches and a dry-'
      'eye feeling. It is common in people who spend many hours on a computer, '
      'tablet or phone.',
  dryEyeTitle: 'Dry eye',
  dryEyeBody:
      'In front of screens we tend to blink much less. Blinking '
      'spreads the tear film that lubricates and protects the eyes; blinking '
      'less, tears evaporate faster and dry-eye discomfort sets in. No wonder '
      'it is so common among digital workers.',
  ruleTitle: 'The 20-20-20 rule',
  ruleBody:
      'Every 20 minutes, look at something about 6 meters (20 feet) away '
      'for 20 seconds — and blink a few times, slowly and fully. Those 20 '
      'seconds relax your focus and help refresh your tears. That is exactly '
      'what this app reminds you to do.',
  statsTitle: 'What studies show',
  stat1Value: '~50%',
  stat1Text:
      'of screen workers have dry eye — in some studies, close to 60% '
      '[1].',
  stat2Value: '~30%',
  stat2Text:
      'drop in work performance (presenteeism) among those with '
      'symptomatic dry eye [2].',
  stat3Value: 'up to 14%',
  stat3Text: 'slower prolonged reading because of dry eye [3, 4].',
  refsTitle: 'References',
  disclaimer:
      'Educational content — it does not replace an eye doctor’s '
      'assessment. Persistent symptoms deserve a consultation.',
  secEyeDrops: 'Eye drops',
  eyeDropsEnable: 'Eye drops reminder',
  eyeDropsInterval: 'Remind every',
  eyeDropsEvery4h: '4 hours',
  eyeDropsEvery6h: '6 hours',
  eyeDropsTitle: 'Eye drops time',
  eyeDropsBody:
      'It is time for your eye drops. Apply them and keep caring '
      'for your eyes.',
  eyeDropsDone: 'Done',
  eyeDropsNotifyTitle: 'Eye drops time 💧',
  eyeDropsNotifyBody: 'It is time for your eye drops.',
  updateUpToDate: 'Your app is up to date.',
  updateAvailable: 'New version {v} available — download and update the app.',
  updateDownload: 'Download',
  updateError: "Couldn't check for updates right now. Please try again later.",
  updateChecking: 'Checking for updates…',
  updateMacInstallTitle: 'Install the update on macOS',
  updateMacInstallSteps:
      'Download the .dmg, run the command below in Terminal to unblock it, then '
      'open the file and drag the app to Applications, replacing the current '
      'version.',
  updateCopyCommand: 'Copy command',
  updateCommandCopied: 'Command copied',
  close: 'Close',
  osdiTitle: 'OSDI questionnaire',
  osdiSubtitle: 'Track dry-eye symptoms over time.',
  osdiInstruction:
      'During the last week, how often did you notice each situation?',
  osdiHistoryTitle: 'History and comparison',
  osdiNoHistory: 'No saved result yet.',
  osdiSave: 'Save result',
  osdiReset: 'Clear answers',
  osdiScoreLabel: 'OSDI score: {score}',
  osdiAnsweredLabel: '{count}/12 answered',
  osdiLatestLabel: 'Latest result',
  osdiSeverityNormal: 'Normal',
  osdiSeverityMild: 'Mild',
  osdiSeverityModerate: 'Moderate',
  osdiSeveritySevere: 'Severe',
  osdiTrendBetter: 'Improved by {delta} points',
  osdiTrendWorse: 'Worsened by {delta} points',
  osdiTrendSame: 'Stable',
  osdiNotApplicable: 'Not applicable',
  osdiAnswerLabels: ['Never', 'Rarely', 'Sometimes', 'Often', 'Always'],
  osdiQuestions: [
    'Eyes sensitive to light',
    'Gritty or foreign-body sensation in the eyes',
    'Eye pain or discomfort',
    'Blurred vision',
    'Poor or unstable vision',
    'Difficulty reading',
    'Difficulty driving at night',
    'Difficulty working on a computer or using an ATM',
    'Difficulty watching TV',
    'Discomfort in windy places',
    'Discomfort in dry or low-humidity places',
    'Discomfort in air-conditioned environments',
  ],
  osdiDisclaimer:
      'Educational screening. The result does not replace an eye exam.',
  pauseOnInactivityLabel: 'Pause when inactive (adaptive)',
  inactivityTitle: 'Timer paused',
  inactivityBody: 'Inactivity detected. The cycle will resume when you return.',
  inactivityContinue: 'Resume',
  secInactivity: 'Inactivity',
  resetLearningLabel: 'Reset inactivity learning',
  cameraPresenceLabel: 'Confirm presence with camera',
  cameraPresenceHint:
      'When idle, takes a single photo to check for a face and discards it '
      'immediately. Nothing is recorded or uploaded.',
  cameraUnavailableHint: 'Available on macOS only for now.',
  cameraConsentTitle: 'Use the camera to confirm presence?',
  cameraConsentBody:
      'When inactivity is detected, the app takes a single photo, checks '
      'whether a face is in front of the screen, and discards the image '
      'immediately. Processing is local; nothing is saved to disk or sent over '
      'the network. You can turn it off anytime. macOS will ask for camera '
      'permission the first time.',
  cameraConsentAllow: 'Allow',
  cameraConsentCancel: 'Not now',
  secScreenTime: 'Screen time',
  screenTimeEnable: 'Collect screen time',
  screenTimeHint:
      'Measures your active screen time per day, discarding inactivity. '
      'The data stays on your computer only.',
  screenTimeView: 'View screen time',
  screenTimeTitle: 'Screen time',
  screenTimeSubtitle: 'Your active screen use over time.',
  screenTimeToday: 'Today',
  screenTimeWeek: 'Week',
  screenTimeMonth: 'Month',
  screenTimeYear: 'Year',
  screenTimeTotal: 'Total',
  screenTimeDailyAverage: 'Daily average',
  screenTimeNoData: 'No usage data yet.',
  screenTimeClear: 'Clear history',
  screenTimeDisabledHint:
      'Screen-time collection is off. Enable it in settings to track your '
      'usage.',
  screenTimeDisclaimer:
      'Local estimate based on the app\'s active time; it does not replace '
      'operating-system measurements.',
  unitHour: 'h',
  weekdayShort: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
  monthShort: [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ],
);
