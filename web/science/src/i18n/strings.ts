export type Lang = "pt" | "en";

export type FlowStepCopy = { label: string; detail: string };

export type Strings = {
  skip: string;
  brandSub: string;
  nav: { why: string; mechanism: string; monitoring: string; ovpp: string; references: string };
  backApp: string;
  langAria: string;
  themeLight: string;
  themeDark: string;
  hero: {
    kicker: string;
    titleBefore: string;
    titleEm: string;
    deck: string;
    body1: string;
    body2: string;
    ctaExplore: string;
    ctaOvpp: string;
    review: string;
    reviewSmall: string;
    visualLabel: string;
    visualFoot: string;
    visualFootStrong: string;
    flowAria: string;
  };
  heroFlow: FlowStepCopy[];
  boundary: {
    label: string;
    aTitle: string;
    aBody: string;
    bTitle: string;
    bBody: string;
  };
  why: {
    eyebrow: string;
    title: string;
    description: string;
    quote: string;
    body: string;
    impactAria: string;
    impacts: string[];
    riskLabel: string;
    riskTitle: string;
    riskFoot: string;
    factors: string[];
    modelLabel: string;
    modelTitle: string;
    modelAria: string;
    modelSteps: FlowStepCopy[];
  };
  mechanism: {
    eyebrow: string;
    title: string;
    description: string;
    stableLabel: string;
    stableTitle: string;
    stableAria: string;
    stableSteps: FlowStepCopy[];
    stressLabel: string;
    stressTitle: string;
    stressAria: string;
    stressSteps: FlowStepCopy[];
    note: string;
  };
  monitoring: {
    eyebrow: string;
    title: string;
    description: string;
    calloutStrong: string;
    calloutBody: string;
    signals: [string, string][];
    timelineLabel: string;
    timelineTitle: string;
    timelineBody: string;
    timelineAria: string;
    timeline: [string, string][];
  };
  principles: {
    eyebrow: string;
    title: string;
    description: string;
    items: { title: string; description: string; status: string }[];
  };
  ovpp: {
    eyebrow: string;
    title: string;
    lead: string;
    body: string;
    cta: string;
    attrs: [string, string][];
    futureTitle: string;
    futureBody: string;
  };
  references: {
    eyebrow: string;
    title: string;
    description: string;
    note: string;
  };
  book: {
    eyebrow: string;
    overline: string;
    title: string;
    body: string;
    bridgeTitle: string;
    bridgeBody: string;
    cta: string;
    coverAlt: string;
  };
  vision: {
    eyebrow: string;
    title: string;
    description: string;
    mapAria: string;
    mapSteps: FlowStepCopy[];
    areas: string[];
    roadmapTitle: string;
    roadmapBody: string;
  };
  ecosystem: {
    eyebrow: string;
    title: string;
    cards: { tag: string; title: string; body: string }[];
  };
  footer: {
    tagline: string;
    disclaimer: string;
    product: string;
    journal: string;
    navAria: string;
  };
  header: {
    primaryAria: string;
    sectionsAria: string;
    homeAria: string;
    backAppAria: string;
    githubAria: string;
  };
  ref: {
    view: string;
    viewAria: string; // use {name} placeholder
    categories: Record<string, string>;
  };
};

export const STRINGS: Record<Lang, Strings> = {
  en: {
    skip: "Skip to scientific content",
    brandSub: "Scientific foundation",
    nav: {
      why: "Why it matters",
      mechanism: "Mechanism",
      monitoring: "Monitoring",
      ovpp: "OVPP",
      references: "References",
    },
    backApp: "App",
    langAria: "Language",
    themeLight: "Use light theme",
    themeDark: "Use dark theme",
    hero: {
      kicker: "Research platform · Open science",
      titleBefore: "The Science Behind ",
      titleEm: "Dry Eye Widget",
      deck: "Evidence-based visual health monitoring for the digital era.",
      body1:
        "Dry Eye Widget was designed from current scientific knowledge regarding dry eye disease, digital eye strain, blinking behavior, tear-film physiology and occupational visual performance.",
      body2:
        "Rather than replacing medical evaluation, the platform organizes longitudinal information that may support awareness, clinical conversations and carefully governed future research.",
      ctaExplore: "Explore the evidence",
      ctaOvpp: "Open OVPP",
      review: "Medically reviewed · 10 July 2026",
      reviewSmall: "Scientific claims are intentionally conservative.",
      visualLabel: "Scientific model",
      visualFoot: "A framework for observation — ",
      visualFootStrong: "not a diagnostic chain.",
      flowAria:
        "Device influences blinking context, which affects the tear film, visual performance and longitudinal monitoring.",
    },
    heroFlow: [
      { label: "Device", detail: "visual demand" },
      { label: "Blink", detail: "behavior" },
      { label: "Tear film", detail: "optical interface" },
      { label: "Visual performance", detail: "functional output" },
      { label: "Longitudinal monitoring", detail: "change over time" },
    ],
    boundary: {
      label: "Evidence boundary",
      aTitle: "Association is not inevitability.",
      aBody:
        "Digital work can contribute to ocular-surface stress, but symptoms, signs and individual risk do not always align.",
      bTitle: "Monitoring is not diagnosis.",
      bBody:
        "Only a qualified clinician can evaluate causes, comorbidities and treatment needs.",
    },
    why: {
      eyebrow: "01 · Clinical relevance",
      title: "Why dry eye matters",
      description:
        "Dry eye disease is a common, multifactorial ocular-surface condition. Its burden reaches beyond discomfort because tear-film instability can affect visual function during sustained tasks.",
      quote:
        "Visual quality can fluctuate even when standard high-contrast visual acuity appears acceptable.",
      body: "Research links dry eye with quality-of-life burden, reading difficulty and work-productivity loss. The magnitude varies across populations and methods, which is why the platform emphasizes trends and provenance rather than a single universal number.",
      impactAria: "Areas that dry eye can affect",
      impacts: [
        "Visual comfort",
        "Reading and sustained attention",
        "Computer work",
        "Quality of life",
        "Task performance",
        "Productivity",
      ],
      riskLabel: "Contributing context",
      riskTitle: "Risk emerges from interacting factors.",
      riskFoot:
        "These factors may contribute to symptoms or disease; none alone establishes a diagnosis.",
      factors: [
        "Sustained digital tasks",
        "Reduced or incomplete blinking",
        "Low humidity and airflow",
        "Contact lens wear",
        "Age-related change",
        "Meibomian gland dysfunction",
      ],
      modelLabel: "Working model",
      modelTitle: "From environment to functional burden",
      modelAria:
        "Environmental and task context can affect blinking, tear-film stability, symptoms and visual performance.",
      modelSteps: [
        { label: "Environment", detail: "humidity · airflow · task" },
        { label: "Blink", detail: "rate · completeness" },
        { label: "Tear-film instability", detail: "variable by person" },
        { label: "Symptoms", detail: "comfort · fluctuation" },
        { label: "Performance", detail: "task-dependent" },
      ],
    },
    mechanism: {
      eyebrow: "02 · Ocular-surface physiology",
      title: "Biological mechanism",
      description:
        "The tear film is the eye’s first optical surface. Blinking renews and redistributes it; the interval between blinks determines how long that surface must remain stable.",
      stableLabel: "Physiological cycle",
      stableTitle: "Complete blinking",
      stableAria:
        "Complete blinking redistributes the tear film and supports tear stability, optical quality and visual performance.",
      stableSteps: [
        { label: "Blink", detail: "complete eyelid movement" },
        { label: "Tear redistribution", detail: "including the lipid layer" },
        { label: "Tear stability", detail: "smoother optical surface" },
        { label: "Optical quality", detail: "between blinks" },
        { label: "Visual performance", detail: "task-dependent" },
      ],
      stressLabel: "Potential stress pathway",
      stressTitle: "Reduced or incomplete blinking",
      stressAria:
        "Reduced or incomplete blinking can lengthen ocular-surface exposure and contribute to evaporation, tear-film breakup, optical fluctuation and functional burden.",
      stressSteps: [
        { label: "Longer exposure", detail: "between complete blinks" },
        { label: "Evaporation / breakup", detail: "tear-film stress" },
        { label: "Hyperosmolar stress", detail: "within dry-eye mechanisms" },
        { label: "Optical fluctuation", detail: "variable blur or discomfort" },
        { label: "Functional burden", detail: "fatigue · task friction" },
      ],
      note: "Hyperosmolarity, inflammation, ocular-surface damage and neurosensory abnormalities are recognized within dry-eye pathophysiology. This diagram is explanatory, not a claim that every screen session produces the full cascade.",
    },
    monitoring: {
      eyebrow: "03 · Temporal context",
      title: "Why monitoring matters",
      description:
        "A single measurement is a snapshot. Repeated observations can show direction, variability and timing — the information needed to ask better clinical and research questions.",
      calloutStrong: "The app does not diagnose disease.",
      calloutBody: "It supports structured, local-first self-monitoring.",
      signals: [
        ["Symptom evolution", "Repeated self-reports can reveal direction and variability."],
        ["Screen exposure", "Contextualize symptoms against periods of digital work."],
        ["Break adherence", "Observe whether planned visual pauses are being completed."],
        ["Eye-drop routines", "Record optional use or reminders without inferring treatment response."],
        ["Behavioral change", "Compare habits before and after a chosen intervention."],
        ["Time trends", "Move from isolated observations to interpretable trajectories."],
      ],
      timelineLabel: "Longitudinal view",
      timelineTitle: "Context becomes more useful when it is time-stamped.",
      timelineBody:
        "The scientific opportunity is not a higher volume of data. It is a clearer relationship between a question, a defined observation window, an intervention and an outcome.",
      timelineAria:
        "Timeline from baseline through observation, change, reassessment and trend interpretation",
      timeline: [
        ["Baseline", "T0"],
        ["Observe", "T1"],
        ["Change", "T2"],
        ["Reassess", "T3"],
        ["Interpret", "Trend"],
      ],
    },
    principles: {
      eyebrow: "04 · Product rationale",
      title: "Scientific principles behind the app",
      description:
        "Each capability has a defined evidence boundary. The platform separates what it records, what it supports and what remains a research direction.",
      items: [
        {
          title: "Digital exposure",
          description:
            "Local screen-time context helps frame sustained near-work patterns without cloud telemetry.",
          status: "Available",
        },
        {
          title: "Blinking behavior",
          description:
            "Blink prompts support behavior. They do not claim to measure blink physiology or diagnose dysfunction.",
          status: "Behavior support",
        },
        {
          title: "Tear-film health",
          description:
            "Symptom history can complement clinical discussion; it is not a direct tear-film measurement.",
          status: "Self-reported",
        },
        {
          title: "Occupational vision",
          description:
            "Visual comfort, task demand and work patterns are considered within the digital-work context.",
          status: "Context layer",
        },
        {
          title: "Healthy visual habits",
          description:
            "20-20-20 breaks and configurable reminders make lower-friction routines easier to practice.",
          status: "Habit support",
        },
        {
          title: "Longitudinal research",
          description:
            "A future, governed export layer could support reproducible datasets and multicenter protocols.",
          status: "Research roadmap",
        },
      ],
    },
    ovpp: {
      eyebrow: "05 · Open protocol",
      title: "Open Visual Performance Protocol",
      lead: "Dry Eye Widget is being developed toward compatibility with OVPP — an open, research-oriented initiative for standardizing visual performance monitoring in digital environments.",
      body: "OVPP aims to support reproducible methods, interoperable datasets and collaborative development of visual-health metrics. Future versions of the application may support structured export aligned with OVPP recommendations, subject to consent, privacy safeguards and an approved research protocol.",
      cta: "Explore OVPP on GitHub",
      attrs: [
        ["Open source", "CC BY 4.0 protocol"],
        ["Research-oriented", "Defined measures and decision gates"],
        ["Community-driven", "Built for review and adaptation"],
        ["Interoperable", "Portable concepts and structured outputs"],
      ],
      futureTitle: "Development direction",
      futureBody: "OVPP-compatible export is not a current production claim.",
    },
    references: {
      eyebrow: "06 · Source trail",
      title: "Scientific references",
      description:
        "Selected consensus reports, guidelines and peer-reviewed studies supporting the public scientific narrative. The list is curated, not exhaustive.",
      note: "Evidence evolves. The page prioritizes TFOS DEWS III as the current international consensus while retaining DEWS II papers that established foundational definitions and tear-film concepts.",
    },
    book: {
      eyebrow: "07 · Related book",
      overline: "The Invisible Cost of Dry Eye",
      title: "When ocular-surface science meets the economics of digital work.",
      body: "The book explores the economic, occupational and human burden of dry eye disease in modern digital work environments, translating current evidence into practical insights for clinicians, researchers, occupational-health professionals and business leaders.",
      bridgeTitle: "Conceptual foundation",
      bridgeBody:
        "The book frames the problem; OVPP defines an open measurement path; Dry Eye Widget provides the human interface.",
      cta: "Learn more with the author",
      coverAlt: "Cover of O Custo Invisível do Olho Seco by Dr. Philipe Saraiva Cruz",
    },
    vision: {
      eyebrow: "08 · Research vision",
      title: "A public interface for a broader scientific ecosystem",
      description:
        "Dry Eye Widget is part of a long-term initiative to better understand visual performance in the digital era. The roadmap links clinical questions, responsible measurement and reproducible evidence generation.",
      mapAria:
        "Research vision connects clinical research, candidate digital biomarkers, OVPP, Dry Eye Widget, population studies and evidence generation.",
      mapSteps: [
        { label: "Clinical research", detail: "questions and outcomes" },
        { label: "Digital biomarkers", detail: "validated candidates" },
        { label: "OVPP", detail: "open protocol" },
        { label: "Dry Eye Widget", detail: "participant interface" },
        { label: "Population studies", detail: "governed cohorts" },
        { label: "Evidence generation", detail: "replicable findings" },
      ],
      areas: [
        "Digital biomarkers",
        "Occupational health",
        "Human–computer interaction",
        "Clinical decision support research",
        "Artificial intelligence",
        "Longitudinal cohort studies",
        "Open science",
        "Reproducible research",
        "Public or controlled-access datasets",
      ],
      roadmapTitle: "Research vision, not current clinical functionality",
      roadmapBody:
        "Biomarkers, clinical decision support, AI models, multicenter cohorts and public datasets require prospective validation, ethics oversight, privacy governance and transparent reporting before deployment.",
    },
    ecosystem: {
      eyebrow: "One ecosystem · Three public layers",
      title:
        "Science becomes useful when it can move between knowledge, protocol and practice.",
      cards: [
        {
          tag: "Interface",
          title: "Dry Eye Widget",
          body: "Local longitudinal monitoring and lower-friction visual habits.",
        },
        {
          tag: "Protocol",
          title: "OVPP",
          body: "Open measurement logic, governance and interoperability.",
        },
        {
          tag: "Conceptual base",
          title: "The Invisible Cost",
          body: "Clinical, occupational and economic framing for digital work.",
        },
      ],
    },
    footer: {
      tagline: "Evidence-informed. Local-first. Open source.",
      disclaimer:
        "The application is intended for education, structured symptom and habit monitoring, and research support. It does not replace professional medical evaluation, diagnosis or individualized treatment.",
      product: "Product",
      journal: "Journal",
      navAria: "Footer navigation",
    },
    header: {
      primaryAria: "Primary navigation",
      sectionsAria: "Science sections",
      homeAria: "Dry Eye Widget home",
      backAppAria: "Back to Dry Eye Widget app page",
      githubAria: "Dry Eye Widget on GitHub (opens in a new tab)",
    },
    ref: {
      view: "View reference",
      viewAria: "View reference: {name} (opens in a new tab)",
      categories: {
        "Current consensus": "Current consensus",
        "Clinical guideline": "Clinical guideline",
        Definition: "Definition",
        Physiology: "Physiology",
        "Digital work": "Digital work",
        Epidemiology: "Epidemiology",
        Mechanism: "Mechanism",
        "Occupational health": "Occupational health",
        "Occupational screening": "Occupational screening",
        "Visual function": "Visual function",
        "Behavioral support": "Behavioral support",
        "Digital intervention": "Digital intervention",
      },
    },
  },
  pt: {
    skip: "Pular para o conteúdo científico",
    brandSub: "Fundação científica",
    nav: {
      why: "Por que importa",
      mechanism: "Mecanismo",
      monitoring: "Monitoramento",
      ovpp: "OVPP",
      references: "Referências",
    },
    backApp: "App",
    langAria: "Idioma",
    themeLight: "Usar tema claro",
    themeDark: "Usar tema escuro",
    hero: {
      kicker: "Plataforma de pesquisa · Ciência aberta",
      titleBefore: "A ciência por trás do ",
      titleEm: "Dry Eye Widget",
      deck: "Monitoramento visual baseado em evidências para a era digital.",
      body1:
        "O Dry Eye Widget foi desenhado a partir do conhecimento científico atual sobre doença do olho seco, fadiga visual digital, comportamento do piscar, fisiologia do filme lacrimal e desempenho visual ocupacional.",
      body2:
        "Em vez de substituir a avaliação médica, a plataforma organiza informação longitudinal que pode apoiar conscientização, conversas clínicas e pesquisa futura com governança cuidadosa.",
      ctaExplore: "Explorar as evidências",
      ctaOvpp: "Abrir OVPP",
      review: "Revisão médica · 10 de julho de 2026",
      reviewSmall: "As afirmações científicas são intencionalmente conservadoras.",
      visualLabel: "Modelo científico",
      visualFoot: "Um quadro para observação — ",
      visualFootStrong: "não uma cadeia diagnóstica.",
      flowAria:
        "O dispositivo influencia o contexto do piscar, que afeta o filme lacrimal, o desempenho visual e o monitoramento longitudinal.",
    },
    heroFlow: [
      { label: "Dispositivo", detail: "demanda visual" },
      { label: "Piscar", detail: "comportamento" },
      { label: "Filme lacrimal", detail: "interface óptica" },
      { label: "Desempenho visual", detail: "saída funcional" },
      { label: "Monitoramento longitudinal", detail: "mudança no tempo" },
    ],
    boundary: {
      label: "Limite de evidência",
      aTitle: "Associação não é inevitabilidade.",
      aBody:
        "O trabalho digital pode contribuir para estresse da superfície ocular, mas sintomas, sinais e risco individual nem sempre se alinham.",
      bTitle: "Monitorar não é diagnosticar.",
      bBody:
        "Somente um clínico qualificado pode avaliar causas, comorbidades e necessidades de tratamento.",
    },
    why: {
      eyebrow: "01 · Relevância clínica",
      title: "Por que o olho seco importa",
      description:
        "A doença do olho seco é uma condição multifatorial comum da superfície ocular. Seu ônus vai além do desconforto, porque a instabilidade do filme lacrimal pode afetar a função visual em tarefas prolongadas.",
      quote:
        "A qualidade visual pode flutuar mesmo quando a acuidade de alto contraste parece aceitável.",
      body: "Pesquisas associam o olho seco a impacto na qualidade de vida, dificuldade de leitura e perda de produtividade. A magnitude varia entre populações e métodos — por isso a plataforma enfatiza tendências e proveniência, e não um único número universal.",
      impactAria: "Áreas que o olho seco pode afetar",
      impacts: [
        "Conforto visual",
        "Leitura e atenção sustentada",
        "Trabalho no computador",
        "Qualidade de vida",
        "Desempenho em tarefas",
        "Produtividade",
      ],
      riskLabel: "Contexto contribuidor",
      riskTitle: "O risco emerge de fatores interativos.",
      riskFoot:
        "Esses fatores podem contribuir para sintomas ou doença; nenhum, sozinho, estabelece diagnóstico.",
      factors: [
        "Tarefas digitais prolongadas",
        "Piscar reduzido ou incompleto",
        "Baixa umidade e fluxo de ar",
        "Uso de lentes de contato",
        "Mudanças relacionadas à idade",
        "Disfunção das glândulas de Meibômio",
      ],
      modelLabel: "Modelo de trabalho",
      modelTitle: "Do ambiente ao ônus funcional",
      modelAria:
        "Contexto ambiental e de tarefa pode afetar o piscar, a estabilidade do filme lacrimal, os sintomas e o desempenho visual.",
      modelSteps: [
        { label: "Ambiente", detail: "umidade · ar · tarefa" },
        { label: "Piscar", detail: "taxa · completude" },
        { label: "Instabilidade lacrimal", detail: "variável por pessoa" },
        { label: "Sintomas", detail: "conforto · flutuação" },
        { label: "Desempenho", detail: "dependente da tarefa" },
      ],
    },
    mechanism: {
      eyebrow: "02 · Fisiologia da superfície ocular",
      title: "Mecanismo biológico",
      description:
        "O filme lacrimal é a primeira superfície óptica do olho. O piscar o renova e redistribui; o intervalo entre piscadas determina por quanto tempo essa superfície precisa permanecer estável.",
      stableLabel: "Ciclo fisiológico",
      stableTitle: "Piscar completo",
      stableAria:
        "O piscar completo redistribui o filme lacrimal e apoia estabilidade, qualidade óptica e desempenho visual.",
      stableSteps: [
        { label: "Piscar", detail: "movimento completo da pálpebra" },
        { label: "Redistribuição", detail: "incluindo a camada lipídica" },
        { label: "Estabilidade", detail: "superfície óptica mais uniforme" },
        { label: "Qualidade óptica", detail: "entre as piscadas" },
        { label: "Desempenho visual", detail: "dependente da tarefa" },
      ],
      stressLabel: "Via de estresse potencial",
      stressTitle: "Piscar reduzido ou incompleto",
      stressAria:
        "O piscar reduzido ou incompleto pode alongar a exposição da superfície ocular e contribuir para evaporação, quebra do filme, flutuação óptica e ônus funcional.",
      stressSteps: [
        { label: "Maior exposição", detail: "entre piscadas completas" },
        { label: "Evaporação / quebra", detail: "estresse do filme" },
        { label: "Estresse hiperosmolar", detail: "nos mecanismos do olho seco" },
        { label: "Flutuação óptica", detail: "borramento ou desconforto" },
        { label: "Ônus funcional", detail: "fadiga · atrito na tarefa" },
      ],
      note: "Hiperosmolaridade, inflamação, dano da superfície ocular e anormalidades neurossensoriais são reconhecidos na fisiopatologia do olho seco. Este diagrama é explicativo — não afirma que toda sessão de tela produza a cascata completa.",
    },
    monitoring: {
      eyebrow: "03 · Contexto temporal",
      title: "Por que o monitoramento importa",
      description:
        "Uma única medição é um instantâneo. Observações repetidas podem mostrar direção, variabilidade e timing — a informação necessária para melhores perguntas clínicas e de pesquisa.",
      calloutStrong: "O app não diagnostica doença.",
      calloutBody: "Ele apoia automonitoramento estruturado e local-first.",
      signals: [
        ["Evolução de sintomas", "Autorrelatos repetidos podem revelar direção e variabilidade."],
        ["Exposição a telas", "Contextualize sintomas em períodos de trabalho digital."],
        ["Adesão às pausas", "Observe se as micro-pausas planejadas estão sendo concluídas."],
        ["Rotina de colírio", "Registre uso ou lembretes opcionais sem inferir resposta ao tratamento."],
        ["Mudança comportamental", "Compare hábitos antes e depois de uma intervenção escolhida."],
        ["Tendências no tempo", "Passe de observações isoladas a trajetórias interpretáveis."],
      ],
      timelineLabel: "Visão longitudinal",
      timelineTitle: "O contexto fica mais útil quando tem carimbo de tempo.",
      timelineBody:
        "A oportunidade científica não é mais volume de dados. É uma relação mais clara entre pergunta, janela de observação definida, intervenção e desfecho.",
      timelineAria:
        "Linha do tempo da linha de base à observação, mudança, reavaliação e interpretação de tendência",
      timeline: [
        ["Linha de base", "T0"],
        ["Observar", "T1"],
        ["Mudança", "T2"],
        ["Reavaliar", "T3"],
        ["Interpretar", "Tendência"],
      ],
    },
    principles: {
      eyebrow: "04 · Racional do produto",
      title: "Princípios científicos por trás do app",
      description:
        "Cada capacidade tem um limite de evidência definido. A plataforma separa o que registra, o que apoia e o que permanece direção de pesquisa.",
      items: [
        {
          title: "Exposição digital",
          description:
            "Contexto local de tempo de tela ajuda a enquadrar padrões de trabalho de perto, sem telemetria em nuvem.",
          status: "Disponível",
        },
        {
          title: "Comportamento do piscar",
          description:
            "Lembretes de piscada apoiam o hábito. Não medem fisiologia do piscar nem diagnosticam disfunção.",
          status: "Apoio comportamental",
        },
        {
          title: "Saúde do filme lacrimal",
          description:
            "O histórico de sintomas pode complementar a conversa clínica; não é medição direta do filme.",
          status: "Autorrelatado",
        },
        {
          title: "Visão ocupacional",
          description:
            "Conforto visual, demanda da tarefa e padrões de trabalho entram no contexto do trabalho digital.",
          status: "Camada de contexto",
        },
        {
          title: "Hábitos visuais saudáveis",
          description:
            "Pausas 20-20-20 e lembretes configuráveis tornam rotinas de menor atrito mais fáceis de praticar.",
          status: "Apoio a hábitos",
        },
        {
          title: "Pesquisa longitudinal",
          description:
            "Uma futura camada de exportação governada pode apoiar conjuntos reprodutíveis e protocolos multicêntricos.",
          status: "Roadmap de pesquisa",
        },
      ],
    },
    ovpp: {
      eyebrow: "05 · Protocolo aberto",
      title: "Open Visual Performance Protocol",
      lead: "O Dry Eye Widget está sendo desenvolvido com vista à compatibilidade com o OVPP — uma iniciativa aberta e orientada à pesquisa para padronizar o monitoramento do desempenho visual em ambientes digitais.",
      body: "O OVPP busca métodos reprodutíveis, conjuntos de dados interoperáveis e desenvolvimento colaborativo de métricas de saúde visual. Versões futuras do aplicativo podem oferecer exportação estruturada alinhada às recomendações do OVPP, sujeita a consentimento, salvaguardas de privacidade e protocolo de pesquisa aprovado.",
      cta: "Explorar o OVPP no GitHub",
      attrs: [
        ["Código aberto", "Protocolo CC BY 4.0"],
        ["Orientado à pesquisa", "Medidas e portões de decisão definidos"],
        ["Comunitário", "Feito para revisão e adaptação"],
        ["Interoperável", "Conceitos portáveis e saídas estruturadas"],
      ],
      futureTitle: "Direção de desenvolvimento",
      futureBody: "Exportação compatível com OVPP ainda não é uma alegação de produção atual.",
    },
    references: {
      eyebrow: "06 · Trilha de fontes",
      title: "Referências científicas",
      description:
        "Relatórios de consenso, diretrizes e estudos revisados por pares selecionados que sustentam a narrativa científica pública. A lista é curada, não exaustiva.",
      note: "A evidência evolui. A página prioriza o TFOS DEWS III como consenso internacional atual, mantendo artigos do DEWS II que estabeleceram definições fundamentais e conceitos do filme lacrimal.",
    },
    book: {
      eyebrow: "07 · Livro relacionado",
      overline: "O Custo Invisível do Olho Seco",
      title: "Quando a ciência da superfície ocular encontra a economia do trabalho digital.",
      body: "O livro explora o ônus econômico, ocupacional e humano da doença do olho seco nos ambientes digitais modernos, traduzindo evidências atuais em insights práticos para clínicos, pesquisadores, profissionais de saúde ocupacional e líderes empresariais.",
      bridgeTitle: "Fundação conceitual",
      bridgeBody:
        "O livro enquadra o problema; o OVPP define um caminho aberto de medição; o Dry Eye Widget oferece a interface humana.",
      cta: "Saiba mais com o autor",
      coverAlt: "Capa de O Custo Invisível do Olho Seco, do Dr. Philipe Saraiva Cruz",
    },
    vision: {
      eyebrow: "08 · Visão de pesquisa",
      title: "Uma interface pública para um ecossistema científico mais amplo",
      description:
        "O Dry Eye Widget faz parte de uma iniciativa de longo prazo para compreender melhor o desempenho visual na era digital. O roadmap liga perguntas clínicas, medição responsável e geração reprodutível de evidência.",
      mapAria:
        "A visão de pesquisa conecta pesquisa clínica, biomarcadores digitais candidatos, OVPP, Dry Eye Widget, estudos populacionais e geração de evidência.",
      mapSteps: [
        { label: "Pesquisa clínica", detail: "perguntas e desfechos" },
        { label: "Biomarcadores digitais", detail: "candidatos validados" },
        { label: "OVPP", detail: "protocolo aberto" },
        { label: "Dry Eye Widget", detail: "interface do participante" },
        { label: "Estudos populacionais", detail: "coortes governadas" },
        { label: "Geração de evidência", detail: "achados replicáveis" },
      ],
      areas: [
        "Biomarcadores digitais",
        "Saúde ocupacional",
        "Interação humano–computador",
        "Pesquisa em suporte à decisão clínica",
        "Inteligência artificial",
        "Estudos de coorte longitudinais",
        "Ciência aberta",
        "Pesquisa reprodutível",
        "Conjuntos públicos ou de acesso controlado",
      ],
      roadmapTitle: "Visão de pesquisa, não funcionalidade clínica atual",
      roadmapBody:
        "Biomarcadores, suporte à decisão clínica, modelos de IA, coortes multicêntricas e conjuntos públicos exigem validação prospectiva, ética, governança de privacidade e relato transparente antes de qualquer implantação.",
    },
    ecosystem: {
      eyebrow: "Um ecossistema · Três camadas públicas",
      title:
        "A ciência se torna útil quando pode circular entre conhecimento, protocolo e prática.",
      cards: [
        {
          tag: "Interface",
          title: "Dry Eye Widget",
          body: "Monitoramento longitudinal local e hábitos visuais de menor atrito.",
        },
        {
          tag: "Protocolo",
          title: "OVPP",
          body: "Lógica aberta de medição, governança e interoperabilidade.",
        },
        {
          tag: "Base conceitual",
          title: "O Custo Invisível",
          body: "Enquadramento clínico, ocupacional e econômico do trabalho digital.",
        },
      ],
    },
    footer: {
      tagline: "Baseado em evidências. Local-first. Código aberto.",
      disclaimer:
        "O aplicativo destina-se a educação, monitoramento estruturado de sintomas e hábitos, e apoio à pesquisa. Não substitui avaliação médica profissional, diagnóstico ou tratamento individualizado.",
      product: "Produto",
      journal: "Blog",
      navAria: "Navegação do rodapé",
    },
    header: {
      primaryAria: "Navegação principal",
      sectionsAria: "Seções científicas",
      homeAria: "Início Dry Eye Widget",
      backAppAria: "Voltar à página do app Dry Eye Widget",
      githubAria: "Dry Eye Widget no GitHub (abre em nova aba)",
    },
    ref: {
      view: "Ver referência",
      viewAria: "Ver referência: {name} (abre em nova aba)",
      categories: {
        "Current consensus": "Consenso atual",
        "Clinical guideline": "Diretriz clínica",
        Definition: "Definição",
        Physiology: "Fisiologia",
        "Digital work": "Trabalho digital",
        Epidemiology: "Epidemiologia",
        Mechanism: "Mecanismo",
        "Occupational health": "Saúde ocupacional",
        "Occupational screening": "Triagem ocupacional",
        "Visual function": "Função visual",
        "Behavioral support": "Apoio comportamental",
        "Digital intervention": "Intervenção digital",
      },
    },
  },
};
