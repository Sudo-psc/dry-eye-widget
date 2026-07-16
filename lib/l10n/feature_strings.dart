/// Strings das melhorias 1.23+ (hub de saúde, meus dados, DVRS 1.1).
///
/// Mantidas fora de [AppStrings] para não inflar o construtor monolítico.
/// Migração futura: copiar para ARB (`lib/l10n/arb/`) e `flutter gen-l10n`.
class FeatureStrings {
  const FeatureStrings._(this._en);
  final bool _en;

  factory FeatureStrings.of(String languageCode) =>
      FeatureStrings._(languageCode == 'en');

  String get menuHealthHub => _en ? 'Visual health' : 'Saúde visual';
  String get menuMyData => _en ? 'My data' : 'Meus dados';
  String get menuQuickStart => _en ? 'Start' : 'Iniciar';
  String get menuQuickReset => _en ? 'Reset' : 'Reiniciar';
  String get menuQuickPause => _en ? 'Pause' : 'Pausar';
  String get menuQuickResume => _en ? 'Resume' : 'Retomar';
  String get menuQuickExtend => _en ? 'Extend' : 'Estender';
  String get menuTrackingSection => _en ? 'Track' : 'Acompanhar';

  String get settingsGeneral => _en ? 'General' : 'Geral';
  String get settingsReminders => _en ? 'Reminders' : 'Lembretes';
  String get settingsAppearance => _en ? 'Appearance' : 'Aparência';
  String get settingsPrivacy => _en ? 'Privacy' : 'Privacidade';
  String get settingsPreview => _en ? 'Live preview' : 'Prévia ao vivo';
  String get settingsLocalOnly => _en
      ? 'Screen and presence data stay on this device.'
      : 'Dados de tela e presença ficam somente neste dispositivo.';

  String get healthHubTitle => _en ? 'Visual health' : 'Saúde visual';
  String get healthHubTabToday => _en ? 'Today' : 'Hoje';
  String get healthHubTabProgress => _en ? 'Trends' : 'Tendências';
  String get healthHubTabScreen => _en ? 'Screen' : 'Tela';
  String get healthHubTabDvrs => 'DVRS';
  String get healthHubTabReports => _en ? 'Reports' : 'Relatórios';
  String get healthHubEvolutionHabits => _en ? 'Habits' : 'Hábitos';
  String get healthHubEvolutionIndicators => _en ? 'Indicators' : 'Indicadores';
  String get stateProgressEmptyTitle =>
      _en ? 'Your progress starts here' : 'Sua evolução começa aqui';
  String get stateDvrsEmptyTitle =>
      _en ? 'No saved results' : 'Sem resultados salvos';
  String get stateDvrsEmptyMessage => _en
      ? 'Complete and save the DVRS to follow changes over time.'
      : 'Responda e salve o DVRS para acompanhar a evolução ao longo do tempo.';
  String get stateScreenEmptyTitle =>
      _en ? 'No data in this period' : 'Sem dados neste período';
  String get stateScreenEmptyMessage => _en
      ? 'Active screen time will appear here as it is recorded.'
      : 'O tempo de tela ativo aparecerá aqui conforme for registrado.';
  String get stateScreenUnavailableTitle =>
      _en ? 'Screen tracking is off' : 'Monitoramento de tela desativado';
  String get stateScreenUnavailableMessage => _en
      ? 'Enable local screen tracking in Settings to view trends.'
      : 'Ative a coleta local nas Configurações para visualizar tendências.';
  String get stateReportSuccessTitle =>
      _en ? 'Report saved' : 'Relatório salvo';
  String get stateReportErrorTitle => _en
      ? 'Could not create the report'
      : 'Não foi possível gerar o relatório';
  String get healthHubOpenQuestionnaire =>
      _en ? 'Take DVRS questionnaire' : 'Responder DVRS';
  String get healthHubOpenReports =>
      _en ? 'Export PDF report' : 'Exportar relatório PDF';

  String get myDataTitle => _en ? 'My data' : 'Meus dados';
  String get myDataSubtitle => _en
      ? 'Everything stays on this device. Export or erase health history '
            'whenever you want.'
      : 'Tudo fica neste dispositivo. Exporte ou apague o histórico de saúde '
            'quando quiser.';
  String get myDataExport =>
      _en ? 'Export health data (JSON)' : 'Exportar dados de saúde (JSON)';
  String get myDataClearHealth =>
      _en ? 'Erase health history' : 'Apagar histórico de saúde';
  String get myDataClearHealthHint => _en
      ? 'Removes DVRS results, break stats, screen time, activity stats and '
            'environment checklist. Preferences are kept.'
      : 'Remove resultados do DVRS, estatísticas de pausas, tempo de tela, '
            'atividade e checklist ambiental. Preferências são mantidas.';
  String get myDataConfirmClear => _en
      ? 'Erase all local health history? This cannot be undone.'
      : 'Apagar todo o histórico local de saúde? Esta ação não pode ser desfeita.';
  String get myDataExported =>
      _en ? 'Exported to: {path}' : 'Exportado para: {path}';
  String get myDataCleared =>
      _en ? 'Health history erased.' : 'Histórico de saúde apagado.';
  String get myDataCancel => _en ? 'Cancel' : 'Cancelar';
  String get myDataConfirm => _en ? 'Erase' : 'Apagar';
  String get myDataClose => _en ? 'Close' : 'Fechar';
  String get myDataInstrument => _en ? 'Instrument' : 'Instrumento';
  String get myDataDvrsCount =>
      _en ? 'DVRS results saved' : 'Resultados DVRS salvos';
  String get myDataDisclaimer => _en
      ? 'Educational data only — not a medical record. No data is sent to servers.'
      : 'Dados apenas educativos — não são prontuário médico. Nada é enviado a servidores.';

  String get dvrsDraftBanner =>
      _en ? 'You have an unfinished draft' : 'Você tem um rascunho incompleto';
  String get dvrsDraftResume => _en ? 'Resume' : 'Continuar';
  String get dvrsDraftDiscard => _en ? 'Discard' : 'Descartar';
  String get dvrsDraftSaved =>
      _en ? 'Draft saved locally' : 'Rascunho salvo localmente';
  String get dvrsDomainCompare => _en
      ? 'Domain comparison (latest vs previous)'
      : 'Comparação de domínios (atual vs anterior)';
  String get dvrsTooltipScore =>
      _en ? 'Score: {score}/100 on {date}' : 'Score: {score}/100 em {date}';
  String get dvrsDeleteConfirmTitle =>
      _en ? 'Delete this DVRS result?' : 'Excluir este resultado do DVRS?';
  String get dvrsDeleteConfirmMessage => _en
      ? 'This assessment will be permanently removed from your history.'
      : 'Esta avaliação será removida permanentemente do seu histórico.';
  String get dvrsDeleteCancel => _en ? 'Cancel' : 'Cancelar';
  String get dvrsDeleteConfirm => _en ? 'Delete' : 'Excluir';
  String get dvrsVersionLabel =>
      _en ? 'Instrument version' : 'Versão do instrumento';
  String dvrsMissingAnswers(int count) => _en
      ? '$count unanswered ${count == 1 ? 'question' : 'questions'}. '
            'Review the first one highlighted.'
      : '$count ${count == 1 ? 'pergunta não respondida' : 'perguntas não respondidas'}. '
            'Revise a primeira destacada.';

  String get narrativeSectionTitle => _en
      ? 'Narrative for the ophthalmologist'
      : 'Narrativa para o oftalmologista';
}
