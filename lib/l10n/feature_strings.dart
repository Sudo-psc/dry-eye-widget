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

  String get healthHubTitle => _en ? 'Visual health' : 'Saúde visual';
  String get healthHubTabToday => _en ? 'Today' : 'Hoje';
  String get healthHubTabProgress => _en ? 'Progress' : 'Progresso';
  String get healthHubTabScreen => _en ? 'Screen' : 'Tela';
  String get healthHubTabDvrs => 'DVRS';
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
  String get myDataInstrument =>
      _en ? 'Instrument' : 'Instrumento';
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
  String get dvrsDomainCompare =>
      _en ? 'Domain comparison (latest vs previous)' : 'Comparação de domínios (atual vs anterior)';
  String get dvrsTooltipScore =>
      _en ? 'Score: {score}/100 on {date}' : 'Score: {score}/100 em {date}';
  String get dvrsVersionLabel =>
      _en ? 'Instrument version' : 'Versão do instrumento';

  String get narrativeSectionTitle =>
      _en ? 'Narrative for the ophthalmologist' : 'Narrativa para o oftalmologista';
}
