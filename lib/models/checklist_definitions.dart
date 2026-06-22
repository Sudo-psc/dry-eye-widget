import 'checklist.dart';

/// Faixa de pontuação que mapeia um intervalo de score para um nível de risco,
/// uma classificação curta e um feedback educativo.
class RiskBand {
  const RiskBand({
    required this.minScore,
    required this.maxScore,
    required this.level,
    required this.classification,
    required this.feedback,
  });

  /// Pontuação mínima (inclusiva) coberta pela faixa.
  final int minScore;

  /// Pontuação máxima (inclusiva) coberta pela faixa. Use um valor alto
  /// (ex.: 9999) para a última faixa, aberta à direita.
  final int maxScore;

  final ChecklistRiskLevel level;
  final String classification;
  final String feedback;

  /// `true` se [score] cai dentro de [minScore, maxScore].
  bool contains(int score) => score >= minScore && score <= maxScore;
}

/// Definição completa de um módulo de checklist (módulos 1–5).
class ChecklistDefinition {
  const ChecklistDefinition({
    required this.type,
    required this.title,
    required this.shortDescription,
    required this.version,
    required this.questions,
    required this.bands,
  });

  final ChecklistType type;
  final String title;
  final String shortDescription;
  final String version;
  final List<ChecklistQuestion> questions;
  final List<RiskBand> bands;
}

// --- Opções reutilizáveis ---------------------------------------------------

/// Opções Sim/Não/Não sei/Não se aplica onde "Sim" é o fator de risco (1 pt).
const List<ChecklistOption> _yesRisk = [
  ChecklistOption(label: 'Sim', score: 1),
  ChecklistOption(label: 'Não', score: 0),
  ChecklistOption(label: 'Não sei', score: 0),
  ChecklistOption(label: 'Não se aplica', score: 0),
];

/// Opções Sim/Não/Não sei/Não se aplica onde "Não" é o fator de risco (1 pt).
const List<ChecklistOption> _noRisk = [
  ChecklistOption(label: 'Sim', score: 0),
  ChecklistOption(label: 'Não', score: 1),
  ChecklistOption(label: 'Não sei', score: 0),
  ChecklistOption(label: 'Não se aplica', score: 0),
];

/// Escala de frequência de sintomas (Nunca…Quase sempre).
const List<ChecklistOption> _frequency = [
  ChecklistOption(label: 'Nunca', score: 0),
  ChecklistOption(label: 'Raramente', score: 1),
  ChecklistOption(label: 'Às vezes', score: 2),
  ChecklistOption(label: 'Frequentemente', score: 3),
  ChecklistOption(label: 'Quase sempre', score: 4),
];

/// Opções Sim/Não simples, "Sim" soma 1 (usado em sinais de alerta).
const List<ChecklistOption> _yesNoRisk = [
  ChecklistOption(label: 'Sim', score: 1),
  ChecklistOption(label: 'Não', score: 0),
];

// --- Módulo 1: Ergonomia visual --------------------------------------------

const ChecklistDefinition _ergonomics = ChecklistDefinition(
  type: ChecklistType.visualErgonomics,
  title: 'Ergonomia visual',
  shortDescription:
      'Como a distância, altura e ajustes da tela influenciam seu conforto '
      'visual durante o trabalho.',
  version: '1',
  questions: [
    ChecklistQuestion(
      id: 'erg_glare',
      text: 'Você percebe reflexos de luz ou janelas na sua tela?',
      options: _yesRisk,
      detail:
          'Referência: tela posicionada perpendicular às janelas (de lado para '
          'a luz), sem fontes de luz diretamente atrás ou à frente do monitor. '
          'Em telas brilhantes, considere acabamento fosco ou reduzir a luz '
          'incidente; reflexos forçam o foco e aumentam o esforço visual.',
    ),
    ChecklistQuestion(
      id: 'erg_distance',
      text:
          'A tela fica a uma distância confortável (cerca de um braço estendido)?',
      options: _noRisk,
      detail:
          'Referência: cerca de 50–70 cm dos olhos (aproximadamente um braço '
          'estendido). Telas maiores (27"+) pedem um pouco mais de distância. '
          'Se precisar aproximar o rosto para ler, aumente a fonte em vez de '
          'encurtar a distância.',
    ),
    ChecklistQuestion(
      id: 'erg_height',
      text:
          'A parte superior da tela está na altura dos olhos ou um pouco abaixo?',
      options: _noRisk,
      detail:
          'Referência: topo da área útil na linha dos olhos ou até ~5 cm abaixo, '
          'com o centro da tela cerca de 15–20° abaixo da horizontal do olhar. '
          'O olhar levemente para baixo reduz a exposição da superfície ocular '
          'e o esforço do pescoço.',
    ),
    ChecklistQuestion(
      id: 'erg_font',
      text: 'O tamanho da fonte é confortável para ler sem esforço?',
      options: _noRisk,
      detail:
          'Referência: o texto deve ser legível com folga na distância de uso '
          '(regra prática: legível a cerca do dobro da distância habitual). '
          'Se necessário, use zoom de 100–125% ou aumente o tamanho do sistema '
          'em vez de aproximar os olhos.',
    ),
    ChecklistQuestion(
      id: 'erg_squint',
      text: 'Você aperta os olhos para enxergar o conteúdo da tela?',
      options: _yesRisk,
      detail:
          'Apertar os olhos costuma indicar fonte pequena, baixo contraste ou '
          'reflexo. Ajuste tamanho/contraste e a iluminação; apertar os olhos de '
          'forma repetida aumenta a fadiga visual.',
    ),
    ChecklistQuestion(
      id: 'erg_lean',
      text: 'Você costuma inclinar o corpo para frente para enxergar melhor?',
      options: _yesRisk,
      detail:
          'Referência: tronco apoiado no encosto, ombros relaxados e a tela '
          'trazida para perto (não o corpo para a tela). Inclinar-se para frente '
          'sinaliza distância/fonte inadequadas.',
    ),
    ChecklistQuestion(
      id: 'erg_brightness',
      text: 'O brilho da tela está bem ajustado ao ambiente (nem forte demais)?',
      options: _noRisk,
      detail:
          'Referência: o brilho da tela deve se aproximar do brilho do entorno '
          '— a tela não deve parecer uma "lâmpada" no ambiente nem ficar apagada. '
          'Reavalie pela manhã, à tarde e à noite, acompanhando a luz do local.',
    ),
    ChecklistQuestion(
      id: 'erg_contrast',
      text: 'O contraste do texto facilita a leitura?',
      options: _noRisk,
      detail:
          'Referência: texto escuro sobre fundo claro (ou tema escuro bem '
          'contrastado), evitando cinza sobre cinza. Bom contraste reduz o '
          'esforço de foco; em leitura prolongada, prefira fundos sem brilho '
          'excessivo.',
    ),
    ChecklistQuestion(
      id: 'erg_position',
      text: 'A tela fica posicionada bem à sua frente (não muito lateral)?',
      options: _noRisk,
      detail:
          'Referência: monitor principal centralizado à frente, a um braço de '
          'distância, evitando girar o pescoço. Com dois monitores de uso '
          'parecido, alinhe-os lado a lado na mesma altura, com a junção à '
          'frente; se um for o principal, deixe-o centralizado.',
    ),
    ChecklistQuestion(
      id: 'erg_eyestrain',
      text: 'Você sente cansaço visual após algumas horas de uso?',
      options: _yesRisk,
      detail:
          'Referência: aplique a regra 20-20-20 (a cada 20 minutos, olhe ~20 '
          'segundos para cerca de 6 metros) e faça pausas curtas regulares. '
          'Cansaço ao fim do dia também pode refletir distância, brilho ou '
          'reflexos inadequados.',
    ),
    ChecklistQuestion(
      id: 'erg_headache',
      text: 'Você tem dores de cabeça associadas ao tempo de tela?',
      options: _yesRisk,
      detail:
          'Dores de cabeça ligadas à tela costumam melhorar revisando fonte, '
          'contraste, brilho, reflexos e pausas. Se forem frequentes ou '
          'intensas, considere avaliação oftalmológica.',
    ),
    ChecklistQuestion(
      id: 'erg_blink',
      text: 'Você nota que pisca menos enquanto usa a tela?',
      options: _yesRisk,
      detail:
          'Em foco na tela, a frequência de piscadas cai bastante. Referência: '
          'pisque de forma consciente e completa nas pausas; baixar levemente o '
          'olhar (tela um pouco abaixo dos olhos) ajuda a reduzir a evaporação '
          'lacrimal.',
    ),
  ],
  bands: [
    RiskBand(
      minScore: 0,
      maxScore: 2,
      level: ChecklistRiskLevel.low,
      classification: 'Boa ergonomia visual',
      feedback:
          'Seu posto de trabalho aparenta estar bem ajustado para o conforto '
          'visual. Especificações de referência para manter: tela a ~50–70 cm '
          '(um braço), topo na linha dos olhos ou até ~5 cm abaixo (centro '
          '15–20° abaixo da horizontal), brilho equiparado ao ambiente, sem '
          'reflexos e com fonte legível. Continue acompanhando como seus olhos '
          'respondem ao longo do dia.',
    ),
    RiskBand(
      minScore: 3,
      maxScore: 5,
      level: ChecklistRiskLevel.attention,
      classification: 'Sinais de atenção',
      feedback:
          'Alguns pontos do seu ambiente podem ser ajustados para reduzir o '
          'esforço visual. Compare com as referências: distância ~50–70 cm, '
          'topo da tela na linha dos olhos ou um pouco abaixo, monitor '
          'centralizado e perpendicular às janelas, brilho próximo ao do '
          'ambiente e fonte/contraste confortáveis. Faça um ajuste por vez e '
          'observe se o conforto melhora. Acompanhe a evolução.',
    ),
    RiskBand(
      minScore: 6,
      maxScore: 9999,
      level: ChecklistRiskLevel.increased,
      classification: 'Risco visual aumentado',
      feedback:
          'Vários fatores ergonômicos podem estar contribuindo para o esforço '
          'visual. Revise o posto com base nas referências: tela a ~50–70 cm e '
          'centralizada à frente; topo na linha dos olhos ou até ~5 cm abaixo '
          '(centro 15–20° abaixo da horizontal); para notebook em uso '
          'prolongado, use suporte com teclado/mouse externos; elimine reflexos '
          '(tela perpendicular às janelas); equipare o brilho ao ambiente; '
          'aumente fonte/contraste em vez de aproximar os olhos; e aplique a '
          'regra 20-20-20. Se o desconforto persistir, considere avaliação '
          'oftalmológica. Este resultado não substitui consulta médica.',
    ),
  ],
);

// --- Módulo 2: Ambiente de tela --------------------------------------------

const ChecklistDefinition _environment = ChecklistDefinition(
  type: ChecklistType.screenEnvironment,
  title: 'Ambiente de tela',
  shortDescription:
      'Fatores do ambiente — ar, iluminação, umidade — que afetam o conforto '
      'dos olhos ao usar telas.',
  version: '1',
  questions: [
    ChecklistQuestion(
      id: 'env_airflow',
      text: 'Há fluxo de ar (ventilador, ar-condicionado) direcionado ao rosto?',
      options: _yesRisk,
      detail:
          'Referência: redirecione saídas de ar, ventiladores e difusores para '
          'longe do rosto. Fluxo de ar direto nos olhos acelera a evaporação da '
          'lágrima e é um dos fatores ambientais mais comuns de desconforto.',
    ),
    ChecklistQuestion(
      id: 'env_ac',
      text: 'O ambiente tem ar-condicionado ligado a maior parte do tempo?',
      options: _yesRisk,
      detail:
          'Ambientes climatizados costumam ressecar o ar. Referência: faça '
          'pausas, mantenha-se hidratado e evite ficar na linha direta do fluxo; '
          'se possível, combine com umidificação do ambiente.',
    ),
    ChecklistQuestion(
      id: 'env_dryair',
      text: 'O ar do ambiente costuma parecer seco?',
      options: _yesRisk,
      detail:
          'Referência: umidade relativa confortável em torno de 40–60%. Abaixo '
          'disso o ressecamento ocular aumenta; um umidificador ou plantas/água '
          'no ambiente ajudam a elevar a umidade.',
    ),
    ChecklistQuestion(
      id: 'env_lighting',
      text: 'A iluminação do ambiente é adequada (nem escura, nem ofuscante)?',
      options: _noRisk,
      detail:
          'Referência: cerca de 300–500 lux para tarefas de escritório/leitura. '
          'Evite trabalhar no escuro com a tela muito brilhante e evite luzes '
          'que ofusquem; prefira luz indireta e uniforme.',
    ),
    ChecklistQuestion(
      id: 'env_glare',
      text: 'Há reflexos de luz ou janelas atingindo a tela?',
      options: _yesRisk,
      detail:
          'Referência: posicione a tela perpendicular às janelas e use '
          'cortinas/persianas para controlar a luz. Acabamento fosco ajuda; '
          'reflexos competem com o conteúdo e aumentam o esforço de foco.',
    ),
    ChecklistQuestion(
      id: 'env_windowback',
      text: 'Há uma janela muito clara atrás ou em frente à sua tela?',
      options: _yesRisk,
      detail:
          'Referência: evite janela diretamente atrás da tela (ofuscamento ao '
          'fundo) ou de frente para você (reflexo na tela). O ideal é a janela '
          'ficar de lado, com a tela perpendicular a ela.',
    ),
    ChecklistQuestion(
      id: 'env_brightness',
      text: 'O brilho da tela está equilibrado com a luz do ambiente?',
      options: _noRisk,
      detail:
          'Referência: o brilho da tela deve se aproximar do brilho do entorno '
          '— a tela não deve parecer um farol no ambiente nem ficar apagada. '
          'Reavalie conforme a luz muda ao longo do dia.',
    ),
    ChecklistQuestion(
      id: 'env_dust',
      text: 'O ambiente costuma ter poeira, fumaça ou poluição perceptível?',
      options: _yesRisk,
      detail:
          'Poeira, fumaça e poluição irritam a superfície ocular. Referência: '
          'mantenha o ambiente ventilado e limpo, evite fumaça direta e, em '
          'locais muito empoeirados, considere purificação do ar.',
    ),
    ChecklistQuestion(
      id: 'env_breaks',
      text: 'Você consegue fazer pausas visuais regulares no ambiente?',
      options: _noRisk,
      detail:
          'Referência: aplique a regra 20-20-20 (a cada 20 min, ~20 s olhando '
          'para cerca de 6 metros). Ter um ponto distante para onde olhar no '
          'ambiente facilita o relaxamento do foco.',
    ),
    ChecklistQuestion(
      id: 'env_distance',
      text: 'O monitor está posicionado a uma distância confortável?',
      options: _noRisk,
      detail:
          'Referência: cerca de 50–70 cm dos olhos (um braço estendido), com o '
          'topo da tela na linha dos olhos ou um pouco abaixo.',
    ),
    ChecklistQuestion(
      id: 'env_multiscreen',
      text: 'Você usa várias telas ao mesmo tempo na maior parte do dia?',
      options: _yesRisk,
      detail:
          'Referência: alinhe os monitores na mesma altura, mantenha o principal '
          'centralizado e faça pausas mais frequentes — a varredura constante '
          'entre telas aumenta a carga visual.',
    ),
    ChecklistQuestion(
      id: 'env_humidity',
      text: 'Você sente que o ambiente tem baixa umidade (pele/olhos secos)?',
      options: _yesRisk,
      detail:
          'Referência: umidade relativa em torno de 40–60%. Pele e olhos secos '
          'são sinais de ar ressecado; umidificação e pausas ajudam a reduzir o '
          'desconforto.',
    ),
  ],
  bands: [
    RiskBand(
      minScore: 0,
      maxScore: 2,
      level: ChecklistRiskLevel.low,
      classification: 'Ambiente favorável',
      feedback:
          'Seu ambiente de tela parece favorável ao conforto visual. '
          'Especificações de referência para manter: sem fluxo de ar direto no '
          'rosto, umidade ~40–60%, iluminação ~300–500 lux sem ofuscamento, '
          'tela perpendicular às janelas e brilho equiparado ao ambiente. '
          'Acompanhe a evolução ao longo do tempo.',
    ),
    RiskBand(
      minScore: 3,
      maxScore: 5,
      level: ChecklistRiskLevel.attention,
      classification: 'Sinais de atenção',
      feedback:
          'Alguns fatores do ambiente podem incomodar seus olhos. Compare com '
          'as referências: redirecione o fluxo de ar para longe do rosto, '
          'busque umidade ~40–60%, iluminação ~300–500 lux, tela perpendicular '
          'às janelas e brilho próximo ao do ambiente. Inclua pausas visuais '
          '(20-20-20) e revise seu ambiente de trabalho.',
    ),
    RiskBand(
      minScore: 6,
      maxScore: 9999,
      level: ChecklistRiskLevel.increased,
      classification: 'Risco visual aumentado',
      feedback:
          'Vários fatores ambientais podem estar contribuindo para o '
          'desconforto visual. Revise com base nas referências: elimine o fluxo '
          'de ar direto nos olhos; eleve a umidade para ~40–60% (umidificador); '
          'ajuste a iluminação para ~300–500 lux sem ofuscamento; posicione a '
          'tela perpendicular às janelas para remover reflexos; equipare o '
          'brilho ao ambiente; reposicione o monitor a ~50–70 cm; e reforce as '
          'pausas. Se o desconforto persistir, considere avaliação '
          'oftalmológica. Este resultado não substitui consulta médica.',
    ),
  ],
);

// --- Módulo 3: Sintomas visuais --------------------------------------------

const ChecklistDefinition _symptoms = ChecklistDefinition(
  type: ChecklistType.visualSymptoms,
  title: 'Sintomas visuais',
  shortDescription:
      'Com que frequência você percebe sintomas visuais relacionados ao uso '
      'de telas.',
  version: '1',
  questions: [
    ChecklistQuestion(
      id: 'sym_dryness',
      text: 'Sensação de olhos secos',
      options: _frequency,
    ),
    ChecklistQuestion(
      id: 'sym_grit',
      text: 'Sensação de areia ou corpo estranho nos olhos',
      options: _frequency,
    ),
    ChecklistQuestion(
      id: 'sym_burning',
      text: 'Ardência ou queimação nos olhos',
      options: _frequency,
    ),
    ChecklistQuestion(
      id: 'sym_tearing',
      text: 'Lacrimejamento excessivo',
      options: _frequency,
    ),
    ChecklistQuestion(
      id: 'sym_redness',
      text: 'Olhos avermelhados ao fim do dia',
      options: _frequency,
    ),
    ChecklistQuestion(
      id: 'sym_blur',
      text: 'Visão embaçada que melhora ao piscar',
      options: _frequency,
    ),
    ChecklistQuestion(
      id: 'sym_fatigue',
      text: 'Cansaço visual',
      options: _frequency,
    ),
    ChecklistQuestion(
      id: 'sym_heavy',
      text: 'Sensação de peso ou pálpebras pesadas',
      options: _frequency,
    ),
    ChecklistQuestion(
      id: 'sym_lightsens',
      text: 'Incômodo com luz (sensibilidade luminosa)',
      options: _frequency,
    ),
    ChecklistQuestion(
      id: 'sym_headache',
      text: 'Dor de cabeça relacionada ao uso de telas',
      options: _frequency,
    ),
    ChecklistQuestion(
      id: 'sym_focus',
      text: 'Dificuldade para focar de perto e de longe',
      options: _frequency,
    ),
    ChecklistQuestion(
      id: 'sym_itch',
      text: 'Coceira nos olhos',
      options: _frequency,
    ),
    ChecklistQuestion(
      id: 'sym_strain',
      text: 'Sensação de esforço para manter os olhos abertos',
      options: _frequency,
    ),
    ChecklistQuestion(
      id: 'sym_double',
      text: 'Visão dupla ocasional ao fim do dia',
      options: _frequency,
    ),
    ChecklistQuestion(
      id: 'sym_discomfort',
      text: 'Desconforto geral nos olhos após o trabalho',
      options: _frequency,
    ),
  ],
  bands: [
    RiskBand(
      minScore: 0,
      maxScore: 10,
      level: ChecklistRiskLevel.low,
      classification: 'Poucos sintomas',
      feedback:
          'Você relata poucos sintomas visuais. Continue cuidando das pausas e '
          'do ambiente e acompanhe a evolução ao longo das semanas.',
    ),
    RiskBand(
      minScore: 11,
      maxScore: 25,
      level: ChecklistRiskLevel.attention,
      classification: 'Sintomas leves a moderados',
      feedback:
          'Há sinais de atenção: alguns sintomas visuais aparecem com certa '
          'frequência. Revise seu ambiente de trabalho, reforce as pausas e '
          'acompanhe a evolução. Se os sintomas aumentarem, considere '
          'avaliação oftalmológica.',
    ),
    RiskBand(
      minScore: 26,
      maxScore: 40,
      level: ChecklistRiskLevel.increased,
      classification: 'Sintomas frequentes',
      feedback:
          'Seus sintomas visuais aparecem com frequência, o que indica risco '
          'visual aumentado. Considere avaliação oftalmológica para entender '
          'melhor o que está acontecendo. Este resultado não substitui '
          'consulta médica.',
    ),
    RiskBand(
      minScore: 41,
      maxScore: 9999,
      level: ChecklistRiskLevel.recommendedEvaluation,
      classification: 'Sintomas relevantes',
      feedback:
          'Você relata sintomas visuais relevantes e frequentes. Considere '
          'avaliação oftalmológica para investigar a causa e acompanhar a '
          'evolução. Este resultado não substitui consulta médica.',
    ),
  ],
);

// --- Módulo 4: Sinais de alerta --------------------------------------------

const ChecklistDefinition _warningSigns = ChecklistDefinition(
  type: ChecklistType.warningSigns,
  title: 'Sinais de alerta',
  shortDescription:
      'Situações que pedem mais atenção e podem justificar uma avaliação com '
      'prioridade.',
  version: '1',
  questions: [
    ChecklistQuestion(
      id: 'warn_pain',
      text: 'Você sente dor ocular persistente?',
      options: _yesNoRisk,
      critical: true,
    ),
    ChecklistQuestion(
      id: 'warn_vision_drop',
      text: 'Notou queda da visão (visão piorando) recentemente?',
      options: _yesNoRisk,
      critical: true,
    ),
    ChecklistQuestion(
      id: 'warn_red_pain',
      text: 'Tem olho vermelho acompanhado de dor?',
      options: _yesNoRisk,
      critical: true,
    ),
    ChecklistQuestion(
      id: 'warn_contact_pain',
      text: 'Usa lente de contato e sente dor ou vermelhidão?',
      options: _yesNoRisk,
      critical: true,
    ),
    ChecklistQuestion(
      id: 'warn_photophobia',
      text: 'Tem fotofobia importante (luz causa muito incômodo)?',
      options: _yesNoRisk,
      critical: true,
    ),
    ChecklistQuestion(
      id: 'warn_progressive',
      text: 'Percebe piora progressiva dos sintomas a cada dia?',
      options: _yesNoRisk,
      critical: true,
    ),
    ChecklistQuestion(
      id: 'warn_persistent',
      text: 'Os sintomas persistem mesmo após descanso e pausas?',
      options: _yesNoRisk,
      critical: true,
    ),
    ChecklistQuestion(
      id: 'warn_secretion',
      text: 'Tem secreção ocular incomum?',
      options: _yesNoRisk,
    ),
    ChecklistQuestion(
      id: 'warn_swelling',
      text: 'Notou inchaço ao redor dos olhos?',
      options: _yesNoRisk,
    ),
    ChecklistQuestion(
      id: 'warn_flashes',
      text: 'Vê flashes de luz ou muitos pontos flutuantes novos?',
      options: _yesNoRisk,
    ),
    ChecklistQuestion(
      id: 'warn_foreign',
      text: 'Sensação constante de corpo estranho que não passa?',
      options: _yesNoRisk,
    ),
    ChecklistQuestion(
      id: 'warn_watering',
      text: 'Lacrimejamento intenso e contínuo sem melhora?',
      options: _yesNoRisk,
    ),
  ],
  bands: [
    RiskBand(
      minScore: 0,
      maxScore: 0,
      level: ChecklistRiskLevel.low,
      classification: 'Sem sinais de alerta',
      feedback:
          'Você não relatou sinais de alerta no momento. Continue acompanhando '
          'a evolução e mantenha seus cuidados visuais habituais.',
    ),
    RiskBand(
      minScore: 1,
      maxScore: 2,
      level: ChecklistRiskLevel.attention,
      classification: 'Sinais de atenção',
      feedback:
          'Você marcou alguns itens que merecem atenção. Acompanhe a evolução '
          'e, se os sinais persistirem ou aumentarem, considere avaliação '
          'oftalmológica. Este resultado não substitui consulta médica.',
    ),
    RiskBand(
      minScore: 3,
      maxScore: 9999,
      level: ChecklistRiskLevel.increased,
      classification: 'Vários sinais de atenção',
      feedback:
          'Você marcou vários sinais que indicam risco visual aumentado. '
          'Considere avaliação oftalmológica para entender melhor o quadro. '
          'Este resultado não substitui consulta médica.',
    ),
  ],
);

/// Feedback usado quando qualquer item crítico de sinais de alerta é marcado.
const String kWarningSignsUrgentFeedback =
    'Você marcou um ou mais sinais que merecem atenção prioritária. Considere '
    'procurar avaliação oftalmológica com prioridade para verificar o que está '
    'acontecendo. Este resultado não substitui consulta médica.';

/// Classificação usada no caso crítico de sinais de alerta.
const String kWarningSignsUrgentClassification = 'Atenção prioritária sugerida';

// --- Módulo 5: Pausas e hábitos --------------------------------------------

const ChecklistDefinition _breakHabits = ChecklistDefinition(
  type: ChecklistType.breakHabits,
  title: 'Pausas e hábitos',
  shortDescription:
      'Como estão seus hábitos de pausa visual e cuidados durante o uso de '
      'telas.',
  version: '1',
  questions: [
    ChecklistQuestion(
      id: 'brk_rule2020',
      text: 'Você faz pausas visuais (ex.: a cada 20 minutos)?',
      options: _noRisk,
      detail:
          'Referência: regra 20-20-20 — a cada 20 minutos, ~20 segundos olhando '
          'para uma distância de cerca de 6 metros (20 pés). Pausas curtas e '
          'frequentes funcionam melhor que poucas pausas longas.',
    ),
    ChecklistQuestion(
      id: 'brk_lookaway',
      text: 'Durante as pausas, você olha para longe por alguns segundos?',
      options: _noRisk,
      detail:
          'Referência: olhe para ~6 metros por ~20 segundos. Focar ao longe '
          'relaxa o músculo de acomodação, que fica tensionado na visão de '
          'perto prolongada.',
    ),
    ChecklistQuestion(
      id: 'brk_blink',
      text: 'Você lembra de piscar completamente durante o trabalho?',
      options: _noRisk,
      detail:
          'Em foco na tela, a frequência de piscadas cai bastante. Referência: '
          'pisque de forma consciente e completa (pálpebra fechando por inteiro) '
          'nas pausas, para reespalhar a lágrima.',
    ),
    ChecklistQuestion(
      id: 'brk_standup',
      text: 'Você se levanta e se movimenta em intervalos?',
      options: _noRisk,
      detail:
          'Referência: faça uma pausa de corpo a cada ~30–60 minutos (levantar, '
          'alongar, andar). O movimento ajuda a circulação e dá uma pausa '
          'natural à visão de perto.',
    ),
    ChecklistQuestion(
      id: 'brk_continuous',
      text: 'Você costuma usar a tela por horas seguidas sem parar?',
      options: _yesRisk,
      detail:
          'Referência: evite blocos acima de ~1–2 horas sem pausa visual. '
          'Períodos contínuos longos somam carga sobre o foco e a lubrificação '
          'ocular.',
    ),
    ChecklistQuestion(
      id: 'brk_skip',
      text: 'Você ignora os avisos de pausa quando aparecem?',
      options: _yesRisk,
      detail:
          'Referência: trate o aviso de pausa como parte do fluxo, não como '
          'interrupção. Ignorar com frequência anula o benefício; ajuste o '
          'horário/intervalo dos lembretes à sua rotina.',
    ),
    ChecklistQuestion(
      id: 'brk_night',
      text: 'Você usa telas até pouco antes de dormir?',
      options: _yesRisk,
      detail:
          'Referência: reduza o uso intenso de telas na ~1 hora antes de dormir. '
          'Ajuda no descanso visual e na qualidade do sono; use modo noturno se '
          'precisar usar à noite.',
    ),
    ChecklistQuestion(
      id: 'brk_hydration',
      text: 'Você mantém uma boa hidratação ao longo do dia?',
      options: _noRisk,
      detail:
          'A hidratação geral contribui para o conforto ocular, especialmente '
          'em ambientes climatizados/secos. Referência: beba água ao longo do '
          'dia, sem esperar a sede.',
    ),
    ChecklistQuestion(
      id: 'brk_distance_breaks',
      text: 'Você inclui atividades longe da tela no seu dia?',
      options: _noRisk,
      detail:
          'Referência: intercale tarefas de tela com atividades fora dela '
          '(telefonemas em pé, leitura em papel, conversas). Alternar reduz a '
          'sobrecarga da visão de perto.',
    ),
    ChecklistQuestion(
      id: 'brk_weekend',
      text: 'Você reduz o tempo de tela nos fins de semana?',
      options: _noRisk,
      detail:
          'Referência: períodos de menor exposição (fins de semana, folgas) '
          'ajudam a recuperar do esforço visual acumulado na semana.',
    ),
    ChecklistQuestion(
      id: 'brk_overload',
      text: 'Você sente que passa mais tempo na tela do que gostaria?',
      options: _yesRisk,
      detail:
          'A percepção de excesso costuma acompanhar maior fadiga visual. '
          'Referência: acompanhe seu tempo de tela e defina metas realistas de '
          'pausas e de redução quando possível.',
    ),
    ChecklistQuestion(
      id: 'brk_plan',
      text: 'As pausas estão organizadas no seu fluxo de trabalho?',
      options: _noRisk,
      detail:
          'Referência: pausas funcionam melhor quando agendadas (lembretes, '
          'blocos de foco com intervalos), e não dependentes só de força de '
          'vontade. Configure lembretes em horários compatíveis com sua rotina.',
    ),
  ],
  bands: [
    RiskBand(
      minScore: 0,
      maxScore: 2,
      level: ChecklistRiskLevel.low,
      classification: 'Boa adesão',
      feedback:
          'Seus hábitos de pausa estão bem estabelecidos. Referência para '
          'manter: regra 20-20-20 (a cada 20 min, ~20 s olhando a ~6 m), pausa '
          'de corpo a cada ~30–60 min e blocos contínuos abaixo de ~1–2 horas. '
          'Continue mantendo esse cuidado e acompanhe a evolução.',
    ),
    RiskBand(
      minScore: 3,
      maxScore: 5,
      level: ChecklistRiskLevel.attention,
      classification: 'Adesão irregular',
      feedback:
          'Suas pausas acontecem de forma irregular. Pausas visuais devem ser '
          'desenhadas no fluxo de trabalho, não deixadas ao acaso. Referência: '
          'configure lembretes (regra 20-20-20), faça pausa de corpo a cada '
          '~30–60 min e evite blocos acima de ~1–2 horas. Revise seu ambiente '
          'de trabalho.',
    ),
    RiskBand(
      minScore: 6,
      maxScore: 8,
      level: ChecklistRiskLevel.increased,
      classification: 'Baixa adesão',
      feedback:
          'Há baixa adesão às pausas, o que pode aumentar o esforço visual. '
          'Referência: ative a regra 20-20-20, reduza períodos contínuos para '
          'abaixo de ~1–2 horas e reforce os lembretes em horários compatíveis '
          'com sua rotina. Pausas devem ser desenhadas no fluxo de trabalho.',
    ),
    RiskBand(
      minScore: 9,
      maxScore: 9999,
      level: ChecklistRiskLevel.increased,
      classification: 'Alto risco comportamental',
      feedback:
          'Seus hábitos atuais indicam alto risco comportamental para o '
          'conforto visual. Referência: adote a regra 20-20-20, pausas de corpo '
          'a cada ~30–60 min, blocos contínuos abaixo de ~1–2 horas e redução '
          'do uso intenso na ~1 hora antes de dormir. Configure lembretes no '
          'fluxo de trabalho e acompanhe a evolução.',
    ),
  ],
);

/// Registro com as definições completas dos módulos 1–5.
///
/// Os módulos 6 (triagem) e 7 (resumo) NÃO entram aqui: são computados pelo
/// engine a partir dos demais dados.
const Map<ChecklistType, ChecklistDefinition> kChecklistDefinitions = {
  ChecklistType.visualErgonomics: _ergonomics,
  ChecklistType.screenEnvironment: _environment,
  ChecklistType.visualSymptoms: _symptoms,
  ChecklistType.warningSigns: _warningSigns,
  ChecklistType.breakHabits: _breakHabits,
};
