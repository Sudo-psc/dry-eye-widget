import '../models/dvrs_assessment.dart';
import '../models/dvrs_definitions.dart';

/// Strings das melhorias 1.23+ (hub de saúde, meus dados, DVRS 1.1).
///
/// Mantidas fora de [AppStrings] para não inflar o construtor monolítico.
/// Migração futura: copiar para ARB (`lib/l10n/arb/`) e `flutter gen-l10n`.
enum DvrsPublicMessageKey { domainFollowUp }

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
  String get dashboardDvrsTitle =>
      _en ? 'Digital visual log — DVRS' : 'Registro visual digital — DVRS';
  String get dashboardDvrsEmpty => _en
      ? 'Use the log to follow the symptoms and habits you report.'
      : 'Use o registro para acompanhar sintomas e hábitos relatados.';
  String get dvrsEducationalProfile =>
      _en ? 'Educational profile by domain' : 'Perfil educativo por domínio';
  String get dvrsEducationalProfileNote => _en
      ? 'Self-reported educational profile; it is not clinical risk, a '
            'diagnosis or a measure for workplace decisions.'
      : 'Perfil educativo autorrelatado; não é risco clínico, diagnóstico ou '
            'medida para decisões corporativas.';
  String get dvrsRetakeHint => _en
      ? 'Retake the DVRS when it is useful to follow changes in the symptoms '
            'and habits you reported.'
      : 'Refaça o DVRS quando for útil para acompanhar mudanças nos sintomas '
            'e hábitos que você relatou.';
  String dvrsLatest(String date) =>
      _en ? 'Latest DVRS · $date' : 'Último DVRS · $date';
  String get dvrsHistoryIntro => _en
      ? 'Compare the domains you reported over time below. The DVRS is a '
            'self-report and does not produce a clinical score.'
      : 'Compare abaixo os domínios que você relatou ao longo do tempo. '
            'O DVRS é um autorregistro e não produz um escore clínico.';
  String get dvrsHistoryResults => _en ? 'Results' : 'Resultados';
  String get dvrsHistoryRecord =>
      _en ? 'Educational record' : 'Registro educativo';
  String get dvrsResultTitle => _en
      ? 'Educational log of symptoms and habits'
      : 'Registro educativo de sintomas e hábitos';
  String get dvrsResultNote => _en
      ? 'This profile organizes answers for personal follow-up. It is not a '
            'validated clinical instrument, diagnosis, fitness assessment or '
            'measure for workplace decisions.'
      : 'Este perfil organiza respostas para acompanhamento pessoal. Não é '
            'instrumento clínico validado, diagnóstico, aptidão ou medida '
            'para decisões da empresa.';
  String get dvrsDomainProfile =>
      _en ? 'Profile by domain' : 'Perfil por domínio';
  String dvrsPublicMessage(DvrsPublicMessageKey key) => switch (key) {
    DvrsPublicMessageKey.domainFollowUp =>
      _en
          ? 'Use the domain profile to observe the symptoms, habits and '
                'conditions you reported over time. The numbers do not measure '
                'clinical risk.'
          : 'Use o perfil por domínio para observar os sintomas, hábitos e '
                'condições que você relatou ao longo do tempo. Os números não '
                'medem risco clínico.',
  };
  String get dvrsDisclaimer => _en
      ? 'This result is educational, does not confirm a diagnosis and does '
            'not replace an eye examination.'
      : 'Este resultado é educativo, não confirma diagnóstico e não substitui '
            'avaliação oftalmológica.';
  String dvrsDomainLabel(String id) => switch (id) {
    'symptoms' =>
      _en ? 'Visual and ocular symptoms' : 'Sintomas visuais e oculares',
    'functional' => _en ? 'Functional impact' : 'Impacto funcional',
    'exposure' =>
      _en ? 'Digital exposure and breaks' : 'Exposição digital e pausas',
    'environment' =>
      _en ? 'Environment and visual ergonomics' : 'Ambiente e ergonomia visual',
    'warning' => _en ? 'Warning signs' : 'Sinais de alerta',
    _ => id,
  };
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
  String get dvrsHeaderTitle =>
      _en ? 'Digital visual log — DVRS' : 'Registro visual digital — DVRS';
  String get dvrsHistoryTitle => _en ? 'DVRS history' : 'Histórico do DVRS';
  String get dvrsIntroTitle => _en
      ? 'Educational log of symptoms and habits'
      : 'Registro educativo de sintomas e hábitos';
  String get dvrsIntroMeta => _en
      ? 'Educational self-report, not validated for diagnosis or workplace '
            'decisions · period assessed: past 7 days'
      : 'Autorregistro educativo, não validado para diagnóstico ou decisões '
            'corporativas · período avaliado: $kDvrsPeriodLabel';
  String get dvrsIntroDescription => _en
      ? 'The DVRS organizes visual symptoms, functional impact, screen '
            'exposure, breaks, environment and warning signs into a '
            'self-reported profile by domain. This educational log does not '
            'replace an eye examination.'
      : kDvrsIntroDescription;
  String get dvrsIntroDisclaimer => _en
      ? 'The DVRS is an educational screening and follow-up tool. It does not '
            'confirm a diagnosis, replace an eye examination or prescribe '
            'treatment. Seek an ophthalmologist for persistent symptoms, eye '
            'pain, light sensitivity, recurrent blurred vision or progressive '
            'worsening.'
      : kDvrsIntroDisclaimer;
  String dvrsAnsweredProgress(int answered, int total) =>
      _en ? '$answered of $total answered' : '$answered de $total respondidas';
  String dvrsProgressSemantics(int answered, int total) => _en
      ? 'DVRS progress: $answered of $total questions answered'
      : 'Progresso do DVRS: $answered de $total perguntas respondidas';
  String get dvrsQuestionInstructions => _en
      ? 'Answer all 16 questions below on this page. Scroll through the list '
            'and calculate the result after every question is answered.'
      : 'Responda as 16 perguntas abaixo na mesma página. Role a lista e '
            'calcule o resultado quando todas estiverem marcadas.';
  String dvrsQuestionNumber(int number) =>
      _en ? 'Question $number' : 'Pergunta $number';
  String dvrsOptionSemantics(int questionNumber, String label) => _en
      ? 'Question $questionNumber, answer: $label'
      : 'Pergunta $questionNumber, resposta: $label';
  String get dvrsSafetyAlertLabel =>
      _en ? 'Safety alert' : 'Alerta de segurança';
  String? dvrsSafetyMessage(DvrsSafetyAlertLevel level) => switch (level) {
    DvrsSafetyAlertLevel.none => null,
    DvrsSafetyAlertLevel.attention =>
      _en
          ? 'There are reports of persistence, worsening or functional impact. '
                'Consider an eye examination, especially if symptoms continue.'
          : 'Há sinais de persistência, piora ou impacto funcional. Considere '
                'avaliação oftalmológica, especialmente se os sintomas '
                'continuarem.',
    DvrsSafetyAlertLevel.medicalEvaluation =>
      _en
          ? 'This questionnaire identified signs that deserve an eye '
                'examination. The result does not confirm a diagnosis, but eye '
                'pain, marked light sensitivity, significant redness, recurrent '
                'blurred vision or contact-lens discomfort should be evaluated '
                'by a physician.'
          : 'Este questionário identificou sinais que merecem avaliação '
                'oftalmológica. O resultado não confirma diagnóstico, mas '
                'sintomas como dor, fotofobia, olho vermelho relevante, visão '
                'embaçada recorrente ou desconforto com lente de contato devem '
                'ser avaliados por um médico.',
    DvrsSafetyAlertLevel.priorityEvaluation =>
      _en
          ? 'Seek priority eye care. Sudden vision loss, severe eye pain, eye '
                'trauma, significant discharge or a painful red eye while '
                'wearing contact lenses should not be monitored only with an app.'
          : 'Procure atendimento oftalmológico com prioridade. Perda visual '
                'súbita, dor intensa, trauma ocular, secreção importante ou olho '
                'vermelho doloroso com lente de contato não devem ser '
                'acompanhados apenas por aplicativo.',
  };
  String dvrsQuestionTitle(String id) {
    final question = _dvrsQuestion(id);
    if (!_en) return question.title;
    return _dvrsQuestionTitlesEn[id] ?? question.title;
  }

  String dvrsQuestionPrompt(String id) {
    final question = _dvrsQuestion(id);
    if (!_en) return question.text;
    return _dvrsQuestionPromptsEn[id] ?? question.text;
  }

  String dvrsOptionLabel(String questionId, int optionIndex) {
    final question = _dvrsQuestion(questionId);
    if (!_en) return question.options[optionIndex].label;
    final options = _dvrsQuestionOptionsEn[questionId];
    if (options == null || optionIndex < 0 || optionIndex >= options.length) {
      return question.options[optionIndex].label;
    }
    return options[optionIndex];
  }

  String get narrativeSectionTitle => _en
      ? 'Narrative for the ophthalmologist'
      : 'Narrativa para o oftalmologista';
}

DvrsQuestion _dvrsQuestion(String id) =>
    kDvrsQuestions.firstWhere((question) => question.id == id);

const Map<String, String> _dvrsQuestionTitlesEn = {
  'q1': 'Dry eyes, gritty or foreign-body sensation',
  'q2': 'Burning, stinging or eye irritation',
  'q3': 'Blurred vision that improves after blinking or a break',
  'q4': 'Sensitivity to light, glare or contrast',
  'q5': 'Watery eyes during screen use',
  'q6': 'Symptoms worsening at the end of the day',
  'q7': 'Rereading, refocusing or loss of fluency',
  'q8': 'Difficulty with prolonged visual tasks',
  'q9': 'Perceived impact on accuracy, speed or concentration',
  'q10': 'Average daily screen time',
  'q11': 'Continuous screen time without a visual break',
  'q12': 'Following visual breaks',
  'q13': 'Air conditioning, fan or dry environment',
  'q14': 'Glare, reflections or uncomfortable lighting',
  'q15': 'Screen workstation setup',
  'q16': 'Signs that deserve an eye examination',
};

const Map<String, String> _dvrsQuestionPromptsEn = {
  'q1':
      'In the past 7 days, how often did your eyes feel dry or gritty, as if '
      'something were in them, or did you need to blink to relieve discomfort?',
  'q2':
      'In the past 7 days, how often did you feel burning, stinging or eye '
      'irritation during or after screen use?',
  'q3':
      'In the past 7 days, how often did your vision become blurred during '
      'screen use and improve after blinking, closing your eyes or taking a '
      'break?',
  'q4':
      'In the past 7 days, how often did bright light, screen glare, white '
      'backgrounds, dark mode or contrast cause visual discomfort?',
  'q5':
      'In the past 7 days, how often did you notice tearing, watery eyes or a '
      'need to wipe your eyes during screen use?',
  'q6':
      'In the past 7 days, did your visual or eye symptoms worsen at the end '
      'of the workday or after several hours of screen use?',
  'q7':
      'In the past 7 days, how often did you need to reread text, refocus the '
      'screen, increase zoom or interrupt a task because of visual discomfort?',
  'q8':
      'In the past 7 days, how often did tasks such as reading documents, '
      'reviewing spreadsheets, coding, testing systems, designing interfaces '
      'or joining video calls become harder because of visual fatigue?',
  'q9':
      'In the past 7 days, how much did visual discomfort affect your speed, '
      'accuracy, concentration or tolerance for screen tasks?',
  'q10':
      'On average, how many hours per day did you use screens in the past 7 '
      'days, including work and relevant personal use?',
  'q11':
      'On a typical day, what was your longest continuous period of screen use '
      'without a real visual break?',
  'q12':
      'In the past 7 days, how often did you take intentional visual breaks, '
      'such as looking into the distance, standing up, blinking consciously or '
      'using the 20-20-20 rule?',
  'q13':
      'In the past 7 days, how much did your work environment involve air '
      'conditioning, a fan, airflow toward your face or a feeling of dry air?',
  'q14':
      'In the past 7 days, how much did screen reflections, unsuitable '
      'lighting, excessive brightness or uncomfortable contrast bother your '
      'vision?',
  'q15':
      'In the past 7 days, how often did you work with the screen too close, '
      'small text, an unsupported laptop, multiple monitors or an uncomfortable '
      'visual posture?',
  'q16': 'Select the most serious option that applies to you:',
};

const List<String> _dvrsFrequencyOptionsEn = [
  'Never',
  'Rarely',
  'Sometimes',
  'Often',
  'Almost always',
];

const Map<String, List<String>> _dvrsQuestionOptionsEn = {
  'q1': _dvrsFrequencyOptionsEn,
  'q2': _dvrsFrequencyOptionsEn,
  'q3': _dvrsFrequencyOptionsEn,
  'q4': _dvrsFrequencyOptionsEn,
  'q5': _dvrsFrequencyOptionsEn,
  'q6': [
    'They did not worsen',
    'They worsened slightly',
    'They worsened moderately',
    'They worsened considerably',
    'They worsened significantly on almost every day',
  ],
  'q7': _dvrsFrequencyOptionsEn,
  'q8': _dvrsFrequencyOptionsEn,
  'q9': [
    'No impact',
    'Slight impact',
    'Moderate impact',
    'Considerable impact',
    'Very strong impact',
  ],
  'q10': [
    'Less than 2 hours/day',
    '2 to 4 hours/day',
    '4 to 6 hours/day',
    '6 to 8 hours/day',
    'More than 8 hours/day',
  ],
  'q11': [
    'Less than 30 minutes',
    '30 to 60 minutes',
    '1 to 2 hours',
    '2 to 3 hours',
    'More than 3 hours',
  ],
  'q12': [
    'I almost always took adequate breaks',
    'I took breaks on most days',
    'I took breaks irregularly',
    'I rarely took breaks',
    'I almost never took breaks',
  ],
  'q13': [
    'Almost never',
    'A little',
    'Moderately',
    'A lot',
    'Almost all the time',
  ],
  'q14': [
    'They did not bother me',
    'They bothered me a little',
    'They bothered me moderately',
    'They bothered me considerably',
    'They bothered me a lot',
  ],
  'q15': _dvrsFrequencyOptionsEn,
  'q16': [
    'No warning signs',
    'Mild symptoms persisting for more than 2 weeks, without significant '
        'worsening',
    'Progressive worsening, symptoms for more than 4 weeks or relevant '
        'functional impact',
    'Eye pain, marked light sensitivity, significant eye redness, recurrent '
        'blurred vision or contact-lens discomfort',
    'Sudden vision loss, severe eye pain, eye trauma, significant discharge or '
        'a painful red eye while wearing contact lenses',
  ],
};
