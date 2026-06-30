import 'package:flutter/foundation.dart';

import 'dvrs_assessment.dart';

/// Conteúdo (textos) do **DVRS — Índice de Risco Visual Digital** v1.0.
///
/// Centraliza enunciados, opções, mensagens educativas, alertas de segurança e
/// avisos médico-legais. Toda a linguagem é de TRIAGEM e EDUCAÇÃO — nunca
/// diagnóstica. As perguntas avaliam sempre os **últimos 7 dias**.

/// Período avaliado por todas as perguntas.
const String kDvrsPeriodLabel = 'últimos 7 dias';

/// Uma opção de resposta com a pontuação associada (0–4).
@immutable
class DvrsOption {
  const DvrsOption({required this.label, required this.score});
  final String label;
  final int score;
}

/// Uma pergunta do DVRS.
@immutable
class DvrsQuestion {
  const DvrsQuestion({
    required this.id,
    required this.domain,
    required this.title,
    required this.text,
    required this.options,
    this.detail,
  });

  /// Id estável (q1..q16).
  final String id;
  final DvrsDomain domain;

  /// Título curto da pergunta.
  final String title;

  /// Enunciado completo.
  final String text;

  /// Opções de resposta na ordem de exibição (5 opções, scores 0..4).
  final List<DvrsOption> options;

  /// Orientação educativa opcional.
  final String? detail;
}

/// Escala de frequência padrão (Nunca…Quase sempre).
const List<DvrsOption> _frequency = [
  DvrsOption(label: 'Nunca', score: 0),
  DvrsOption(label: 'Raramente', score: 1),
  DvrsOption(label: 'Às vezes', score: 2),
  DvrsOption(label: 'Frequentemente', score: 3),
  DvrsOption(label: 'Quase sempre', score: 4),
];

/// As 16 perguntas do DVRS, na ordem canônica de domínios (6/3/3/3/1).
const List<DvrsQuestion> kDvrsQuestions = [
  // --- Domínio A: Sintomas visuais e oculares (Q1–Q6) ---------------------
  DvrsQuestion(
    id: 'q1',
    domain: DvrsDomain.symptoms,
    title: 'Olhos secos, sensação de areia ou corpo estranho',
    text:
        'Nos últimos 7 dias, com que frequência você sentiu olho seco, areia, '
        'corpo estranho ou necessidade de piscar para aliviar desconforto?',
    options: _frequency,
  ),
  DvrsQuestion(
    id: 'q2',
    domain: DvrsDomain.symptoms,
    title: 'Ardência, queimação ou irritação ocular',
    text:
        'Nos últimos 7 dias, com que frequência você sentiu ardência, '
        'queimação ou irritação nos olhos durante ou após o uso de telas?',
    options: _frequency,
  ),
  DvrsQuestion(
    id: 'q3',
    domain: DvrsDomain.symptoms,
    title: 'Visão embaçada que melhora ao piscar ou pausar',
    text:
        'Nos últimos 7 dias, com que frequência sua visão ficou embaçada '
        'durante o uso de telas e melhorou ao piscar, fechar os olhos ou fazer '
        'uma pausa?',
    options: _frequency,
  ),
  DvrsQuestion(
    id: 'q4',
    domain: DvrsDomain.symptoms,
    title: 'Sensibilidade à luz, brilho ou contraste',
    text:
        'Nos últimos 7 dias, com que frequência luz forte, brilho da tela, '
        'fundo branco, modo escuro ou contraste causaram desconforto visual?',
    options: _frequency,
  ),
  DvrsQuestion(
    id: 'q5',
    domain: DvrsDomain.symptoms,
    title: 'Lacrimejamento durante uso de telas',
    text:
        'Nos últimos 7 dias, com que frequência você percebeu lacrimejamento, '
        'olhos molhados ou necessidade de enxugar os olhos durante o uso de '
        'telas?',
    options: _frequency,
  ),
  DvrsQuestion(
    id: 'q6',
    domain: DvrsDomain.symptoms,
    title: 'Piora dos sintomas no fim do dia',
    text:
        'Nos últimos 7 dias, seus sintomas visuais ou oculares pioraram no fim '
        'do expediente ou após várias horas de tela?',
    options: [
      DvrsOption(label: 'Não pioraram', score: 0),
      DvrsOption(label: 'Pioraram pouco', score: 1),
      DvrsOption(label: 'Pioraram moderadamente', score: 2),
      DvrsOption(label: 'Pioraram bastante', score: 3),
      DvrsOption(
          label: 'Pioraram quase todos os dias de forma importante', score: 4),
    ],
  ),
  // --- Domínio B: Impacto funcional (Q7–Q9) -------------------------------
  DvrsQuestion(
    id: 'q7',
    domain: DvrsDomain.functional,
    title: 'Releitura, refoco ou perda de fluidez',
    text:
        'Nos últimos 7 dias, com que frequência você precisou reler textos, '
        'refocar a tela, aumentar zoom ou interromper a tarefa por desconforto '
        'visual?',
    options: _frequency,
  ),
  DvrsQuestion(
    id: 'q8',
    domain: DvrsDomain.functional,
    title: 'Dificuldade em tarefas visuais prolongadas',
    text:
        'Nos últimos 7 dias, com que frequência tarefas como ler documentos, '
        'revisar planilhas, programar, testar sistemas, desenhar interfaces ou '
        'participar de videochamadas ficaram mais difíceis por cansaço visual?',
    options: _frequency,
  ),
  DvrsQuestion(
    id: 'q9',
    domain: DvrsDomain.functional,
    title: 'Impacto percebido na precisão, velocidade ou concentração',
    text:
        'Nos últimos 7 dias, quanto o desconforto visual prejudicou sua '
        'velocidade, precisão, concentração ou tolerância a tarefas de tela?',
    options: [
      DvrsOption(label: 'Não prejudicou', score: 0),
      DvrsOption(label: 'Prejudicou pouco', score: 1),
      DvrsOption(label: 'Prejudicou moderadamente', score: 2),
      DvrsOption(label: 'Prejudicou bastante', score: 3),
      DvrsOption(label: 'Prejudicou muito', score: 4),
    ],
  ),
  // --- Domínio C: Exposição digital e pausas (Q10–Q12) --------------------
  DvrsQuestion(
    id: 'q10',
    domain: DvrsDomain.exposure,
    title: 'Tempo médio diário de tela',
    text:
        'Em média, quantas horas por dia você usou telas nos últimos 7 dias, '
        'somando trabalho e uso pessoal relevante?',
    options: [
      DvrsOption(label: 'Menos de 2 horas/dia', score: 0),
      DvrsOption(label: '2 a 4 horas/dia', score: 1),
      DvrsOption(label: '4 a 6 horas/dia', score: 2),
      DvrsOption(label: '6 a 8 horas/dia', score: 3),
      DvrsOption(label: 'Mais de 8 horas/dia', score: 4),
    ],
  ),
  DvrsQuestion(
    id: 'q11',
    domain: DvrsDomain.exposure,
    title: 'Tempo contínuo sem pausa visual',
    text:
        'Em um dia típico, qual foi o maior período contínuo em tela sem pausa '
        'visual real?',
    options: [
      DvrsOption(label: 'Menos de 30 minutos', score: 0),
      DvrsOption(label: '30 a 60 minutos', score: 1),
      DvrsOption(label: '1 a 2 horas', score: 2),
      DvrsOption(label: '2 a 3 horas', score: 3),
      DvrsOption(label: 'Mais de 3 horas', score: 4),
    ],
  ),
  DvrsQuestion(
    id: 'q12',
    domain: DvrsDomain.exposure,
    title: 'Adesão a pausas visuais',
    text:
        'Nos últimos 7 dias, com que frequência você fez pausas visuais '
        'intencionais, como olhar para longe, levantar, piscar conscientemente '
        'ou aplicar a regra 20-20-20?',
    options: [
      DvrsOption(label: 'Quase sempre fiz pausas adequadas', score: 0),
      DvrsOption(label: 'Fiz pausas na maioria dos dias', score: 1),
      DvrsOption(label: 'Fiz pausas de forma irregular', score: 2),
      DvrsOption(label: 'Raramente fiz pausas', score: 3),
      DvrsOption(label: 'Quase nunca fiz pausas', score: 4),
    ],
  ),
  // --- Domínio D: Ambiente e ergonomia visual (Q13–Q15) -------------------
  DvrsQuestion(
    id: 'q13',
    domain: DvrsDomain.environment,
    title: 'Ar-condicionado, ventilador ou ambiente seco',
    text:
        'Nos últimos 7 dias, quanto seu ambiente de trabalho teve '
        'ar-condicionado, ventilador, fluxo de ar no rosto ou sensação de ar '
        'seco?',
    options: [
      DvrsOption(label: 'Quase nunca', score: 0),
      DvrsOption(label: 'Pouco', score: 1),
      DvrsOption(label: 'Moderadamente', score: 2),
      DvrsOption(label: 'Bastante', score: 3),
      DvrsOption(label: 'Quase o tempo todo', score: 4),
    ],
  ),
  DvrsQuestion(
    id: 'q14',
    domain: DvrsDomain.environment,
    title: 'Brilho, reflexo ou iluminação desconfortável',
    text:
        'Nos últimos 7 dias, quanto reflexo na tela, iluminação inadequada, '
        'brilho excessivo ou contraste desconfortável incomodaram sua visão?',
    options: [
      DvrsOption(label: 'Não incomodaram', score: 0),
      DvrsOption(label: 'Incomodaram pouco', score: 1),
      DvrsOption(label: 'Incomodaram moderadamente', score: 2),
      DvrsOption(label: 'Incomodaram bastante', score: 3),
      DvrsOption(label: 'Incomodaram muito', score: 4),
    ],
  ),
  DvrsQuestion(
    id: 'q15',
    domain: DvrsDomain.environment,
    title: 'Configuração do posto de tela',
    text:
        'Nos últimos 7 dias, com que frequência você trabalhou com tela muito '
        'próxima, fonte pequena, notebook sem suporte, múltiplos monitores ou '
        'postura visual desconfortável?',
    options: _frequency,
  ),
  // --- Domínio E: Sinais de alerta (Q16) ----------------------------------
  DvrsQuestion(
    id: 'q16',
    domain: DvrsDomain.warning,
    title: 'Sinais que merecem avaliação oftalmológica',
    text: 'Assinale a alternativa mais grave que se aplica a você:',
    options: [
      DvrsOption(label: 'Nenhum sinal de alerta', score: 0),
      DvrsOption(
          label:
              'Sintomas leves persistentes por mais de 2 semanas, sem piora '
              'importante',
          score: 1),
      DvrsOption(
          label:
              'Piora progressiva, sintomas por mais de 4 semanas ou impacto '
              'funcional relevante',
          score: 2),
      DvrsOption(
          label:
              'Dor ocular, fotofobia importante, olho vermelho relevante, '
              'visão embaçada recorrente ou desconforto com lente de contato',
          score: 3),
      DvrsOption(
          label:
              'Perda visual súbita, dor intensa, trauma ocular, secreção '
              'importante ou olho vermelho doloroso com lente de contato',
          score: 4),
    ],
  ),
];

/// Disclaimer médico-legal obrigatório (tela inicial).
const String kDvrsIntroDisclaimer =
    'O DVRS é uma ferramenta educativa de triagem e acompanhamento. Ele não '
    'confirma diagnóstico, não substitui avaliação oftalmológica e não prescreve '
    'tratamento. Em caso de sintomas persistentes, dor ocular, fotofobia, olho '
    'vermelho, visão embaçada recorrente ou piora progressiva, procure um médico '
    'oftalmologista.';

/// Texto curto explicativo da tela inicial.
const String kDvrsIntroDescription =
    'O DVRS combina sintomas visuais, impacto funcional, exposição a telas, '
    'pausas, ambiente e sinais de alerta para estimar risco visual digital '
    'autorreferido. O resultado é educativo e não substitui avaliação '
    'oftalmológica.';

/// Aviso médico-legal obrigatório no relatório PDF.
const String kDvrsPdfLegalNotice =
    'O DVRS é uma ferramenta educativa de triagem e acompanhamento de risco '
    'visual digital. Não confirma diagnóstico e não substitui consulta '
    'oftalmológica.';

/// Mensagens educativas por classificação (seção 8 da especificação).
const Map<DvrsClassification, String> kDvrsEducationalMessages = {
  DvrsClassification.low:
      'Seu resultado sugere baixo risco visual digital neste momento. Continue '
      'acompanhando sintomas, mantendo pausas visuais e revisando seu ambiente '
      'de trabalho.',
  DvrsClassification.mildAttention:
      'Seu resultado sugere sinais iniciais de sobrecarga visual. Ajustar '
      'pausas, brilho, reflexos, distância da tela e tempo contínuo de uso pode '
      'ajudar no conforto visual.',
  DvrsClassification.moderateRisk:
      'Seu resultado sugere risco visual digital moderado. Reforce pausas '
      'visuais, revise o ambiente e acompanhe o score nas próximas semanas. Se '
      'os sintomas persistirem, considere avaliação oftalmológica.',
  DvrsClassification.highRisk:
      'Seu resultado sugere risco visual digital elevado. A combinação de '
      'sintomas, exposição e impacto funcional merece atenção. Considere '
      'avaliação oftalmológica, principalmente se houver piora, sintomas '
      'persistentes ou uso frequente de colírios sem orientação.',
  DvrsClassification.veryHighRisk:
      'Seu resultado sugere risco visual digital muito elevado. Este '
      'questionário não realiza diagnóstico, mas recomenda-se avaliação '
      'oftalmológica, especialmente se houver dor, fotofobia, embaçamento '
      'recorrente, piora progressiva ou impacto no trabalho.',
};

/// Mensagens de alerta de segurança por nível (seção 9 da especificação).
/// Não há mensagem para [DvrsSafetyAlertLevel.none].
const Map<DvrsSafetyAlertLevel, String> kDvrsSafetyAlertMessages = {
  DvrsSafetyAlertLevel.attention:
      'Há sinais de persistência, piora ou impacto funcional. Considere '
      'avaliação oftalmológica, especialmente se os sintomas continuarem.',
  DvrsSafetyAlertLevel.medicalEvaluation:
      'Este questionário identificou sinais que merecem avaliação '
      'oftalmológica. O resultado não confirma diagnóstico, mas sintomas como '
      'dor, fotofobia, olho vermelho relevante, visão embaçada recorrente ou '
      'desconforto com lente de contato devem ser avaliados por um médico.',
  DvrsSafetyAlertLevel.priorityEvaluation:
      'Procure atendimento oftalmológico com prioridade. Perda visual súbita, '
      'dor intensa, trauma ocular, secreção importante ou olho vermelho doloroso '
      'com lente de contato não devem ser acompanhados apenas por aplicativo.',
};

/// Rótulos curtos de cada domínio (para gráficos e relatório).
const Map<DvrsDomain, String> kDvrsDomainLabels = {
  DvrsDomain.symptoms: 'Sintomas visuais e oculares',
  DvrsDomain.functional: 'Impacto funcional',
  DvrsDomain.exposure: 'Exposição digital e pausas',
  DvrsDomain.environment: 'Ambiente e ergonomia visual',
  DvrsDomain.warning: 'Sinais de alerta',
};
