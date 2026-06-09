export type Lang = 'pt' | 'en';

export const urls = {
  github: 'https://github.com/Sudo-psc/dry-eye-widget',
  releases: 'https://github.com/Sudo-psc/dry-eye-widget/releases/latest',
  mac: 'https://github.com/Sudo-psc/dry-eye-widget/releases/latest/download/DryEyeWidget.dmg',
  windows: 'https://github.com/Sudo-psc/dry-eye-widget/releases/latest/download/DryEyeWidget-Setup-x64.exe',
  windowsZip: 'https://github.com/Sudo-psc/dry-eye-widget/releases/latest/download/DryEyeWidget-windows-x64.zip'
};

export const author = {
  pt: 'Dr. Philipe Saraiva Cruz',
  en: 'Dr. Philipe Saraiva Cruz',
  credentials: 'Médico Oftalmologista · CRM-MG 69.870 · CRM-SP 204.923 · RQE 71.903'
};

export const references = [
  {
    title: 'Prevalence of dry eye disease in visual display terminal workers: a systematic review and meta-analysis.',
    journal: 'BMJ Open. 2016;6(1):e009675.',
    doi: '10.1136/bmjopen-2015-009675',
    url: 'https://doi.org/10.1136/bmjopen-2015-009675'
  },
  {
    title: "Impact of Dry Eye Disease on Work Productivity, and Patients' Satisfaction With Over-the-Counter Dry Eye Treatments.",
    journal: 'Invest Ophthalmol Vis Sci. 2016;57(7):2975-82.',
    doi: '10.1167/iovs.16-19419',
    url: 'https://doi.org/10.1167/iovs.16-19419'
  },
  {
    title: 'Functional impairment of reading in patients with dry eye.',
    journal: 'Br J Ophthalmol. 2016;101(4):481-6.',
    doi: '10.1136/bjophthalmol-2015-308237',
    url: 'https://doi.org/10.1136/bjophthalmol-2015-308237'
  },
  {
    title: 'Impact of Dry Eye on Prolonged Reading.',
    journal: 'Optom Vis Sci. 2018;95(12):1105-13.',
    doi: '10.1097/OPX.0000000000001303',
    url: 'https://doi.org/10.1097/OPX.0000000000001303'
  }
];

export const blogArticles = {
  pt: [
    {
      slug: 'regra-20-20-20',
      title: 'Regra 20-20-20: por que micro-pausas ajudam os olhos',
      description: 'Um guia médico direto sobre descanso visual, foco acomodativo e filme lacrimal durante o uso intenso de telas.',
      date: '2026-06-09',
      readTime: '5 min'
    },
    {
      slug: 'olho-seco-telas',
      title: 'Olho seco e telas: o problema clínico que motivou o app',
      description: 'A motivação profissional por trás do Dry Eye Widget e como transformar orientação clínica em hábito digital.',
      date: '2026-06-09',
      readTime: '6 min'
    }
  ],
  en: [
    {
      slug: '20-20-20-rule',
      title: 'The 20-20-20 rule: why micro-breaks help the eyes',
      description: 'A practical medical overview of visual rest, accommodative focus and tear-film stability during heavy screen use.',
      date: '2026-06-09',
      readTime: '5 min'
    },
    {
      slug: 'dry-eye-screens',
      title: 'Dry eye and screens: the clinical problem behind the app',
      description: 'The professional motivation behind Dry Eye Widget and how clinical guidance can become a digital habit.',
      date: '2026-06-09',
      readTime: '6 min'
    }
  ]
} satisfies Record<Lang, Array<{ slug: string; title: string; description: string; date: string; readTime: string }>>;

export const content = {
  pt: {
    htmlLang: 'pt-BR',
    canonical: 'https://olhossecos.com.br/app/pt/',
    alternate: 'https://olhossecos.com.br/app/en/',
    title: 'Dry Eye Widget - regra 20-20-20 para olho seco e fadiga visual',
    description: 'Landing page oficial do Dry Eye Widget, app open source criado por oftalmologista para micro-pausas oculares, regra 20-20-20, olho seco e fadiga visual digital.',
    nav: {
      science: 'Ciência',
      screenshots: 'Screenshots',
      downloads: 'Downloads',
      blog: 'Blog',
      github: 'GitHub'
    },
    langLabel: 'English',
    langHref: '/app/en/',
    themeLabel: 'Alternar tema',
    hero: {
      eyebrow: 'Open source · macOS e Windows · criado por oftalmologista',
      title: 'Dry Eye Widget',
      subtitle: 'Micro-pausas oculares guiadas pela regra 20-20-20 para reduzir fadiga visual digital e apoiar a saúde da superfície ocular.',
      primary: 'Ver downloads',
      secondary: 'Projeto open source',
      doctor: 'Criado e documentado clinicamente pelo Dr. Philipe Saraiva Cruz, médico oftalmologista.',
      chips: ['A cada 20 min', 'Olhe para 6 m', 'Por 20 s', 'Piscar completo']
    },
    proof: [
      { value: '~50%', label: 'prevalência de olho seco entre trabalhadores que usam terminais de vídeo em meta-análise' },
      { value: '~30%', label: 'queda documentada de produtividade em indivíduos com olho seco sintomático' },
      { value: 'até 14%', label: 'redução de velocidade e fluência em leitura prolongada associada ao olho seco' }
    ],
    sections: {
      motivationTitle: 'Motivação clínica',
      motivationBody: 'Na prática oftalmológica, o uso prolongado de telas aparece de forma recorrente associado a ardência, sensação de areia, visão turva transitória, dor de cabeça e piora da lubrificação ocular. O Dry Eye Widget nasceu para transformar uma recomendação simples e baseada em evidências em um lembrete discreto, contínuo e integrado ao fluxo de trabalho.',
      rationaleTitle: 'Por que o app existe',
      rationale: [
        'Durante tarefas cognitivas em telas, a frequência e a amplitude do piscar tendem a cair. Isso desestabiliza o filme lacrimal e aumenta evaporação.',
        'A focalização sustentada para perto mantém esforço acomodativo e convergencial, contribuindo para astenopia e desconforto.',
        'A regra 20-20-20 é simples, mas a adesão falha quando o usuário está imerso no trabalho. O widget automatiza o gatilho comportamental.'
      ],
      appTitle: 'O que o Dry Eye Widget entrega',
      appItems: [
        'Overlay translúcido sempre visível, sem bloquear o uso normal do computador.',
        'Ciclo personalizável de alerta e pausa de 20 segundos.',
        'Controle pela bandeja/menu do sistema, pausa, reset e preferências.',
        'Modo Liquid Glass, cores e tamanho ajustáveis.',
        'Lembrete de colírio e acompanhamento OSDI em versões recentes.'
      ],
      downloadsTitle: 'Baixe a versão mais recente',
      downloadsSubtitle: 'Links diretos para os binários publicados no GitHub Releases. O projeto completo permanece auditável como software open source.',
      mac: 'Baixar para macOS',
      macMeta: 'DMG universal para Apple Silicon e Intel',
      windows: 'Baixar para Windows',
      windowsMeta: 'Instalador x64 para Windows 10/11',
      portable: 'Versão portátil .zip',
      screenshotsTitle: 'Screenshots do app em funcionamento',
      screenshotsSubtitle: 'Estados principais da experiência: pausa guiada, personalização visual e acompanhamento de sintomas.',
      authorityTitle: 'Credibilidade médica e transparência',
      authorityBody: 'O app foi concebido por médico oftalmologista para apoiar prevenção comportamental. Ele não substitui consulta, exame oftalmológico, diagnóstico ou tratamento individualizado.',
      referencesTitle: 'Referências científicas',
      referencesIntro: 'As referências abaixo sustentam a justificativa clínica usada no README e nesta landing page.',
      blogTitle: 'Blog',
      blogSubtitle: 'Artigos autorais sobre olho seco, fadiga visual digital e uso saudável de telas.',
      footer: 'Autoria, concepção clínica e documentação por Dr. Philipe Saraiva Cruz.'
    },
    screenshots: [
      { image: '/assets/app-floating-widget.jpg', title: 'Widget flutuante discreto', text: 'Bolinha de status sempre visível, com progresso do ciclo sem bloquear a tela.' },
      { image: '/assets/app-menu.jpg', title: 'Menu rápido', text: 'Inicie pausa, resete, abra orientações, OSDI, atualizações e configurações.' },
      { image: '/assets/app-break-timer.jpg', title: 'Pausa de 20 segundos', text: 'Contador de repouso ocular com orientação para olhar a 6 metros.' },
      { image: '/assets/app-settings.jpg', title: 'Configurações completas', text: 'Idioma, temporização, aparência, tamanho, cores e preferências do widget.' },
      { image: '/assets/app-guidance.jpg', title: 'Orientações médicas', text: 'Conteúdo educativo sobre fadiga visual digital, olho seco e regra 20-20-20.' },
      { image: '/assets/app-osdi.jpg', title: 'Questionário OSDI', text: 'Triagem educativa para acompanhar sintomas de olho seco ao longo do tempo.' }
    ],
    articleContent: {
      'regra-20-20-20': [
        'A regra 20-20-20 propõe que, a cada 20 minutos de tela, a pessoa olhe para uma distância de aproximadamente 6 metros por 20 segundos. O objetivo é interromper o esforço sustentado de foco para perto e estimular piscadas completas.',
        'Do ponto de vista oftalmológico, o benefício não depende apenas do tempo. Ele depende de transformar a pausa em comportamento repetível: relaxar a acomodação, piscar com amplitude adequada e permitir redistribuição do filme lacrimal.',
        'O Dry Eye Widget foi desenhado para reduzir a barreira de adesão. Em vez de depender da memória do usuário, o lembrete aparece no fluxo real de trabalho, com baixa intrusão e feedback visual contínuo.'
      ],
      'olho-seco-telas': [
        'O olho seco relacionado ao uso intenso de telas é frequente porque o comportamento visual muda: piscamos menos, piscamos de forma incompleta e mantemos atenção prolongada em uma distância fixa.',
        'Na prática clínica, muitos pacientes compreendem a recomendação, mas não conseguem sustentá-la no trabalho diário. Essa lacuna entre orientação e hábito foi a motivação central do app.',
        'A proposta é simples: levar uma recomendação de consultório para o ambiente onde o problema acontece, mantendo transparência open source e uma abordagem educativa.'
      ]
    }
  },
  en: {
    htmlLang: 'en',
    canonical: 'https://olhossecos.com.br/app/en/',
    alternate: 'https://olhossecos.com.br/app/pt/',
    title: 'Dry Eye Widget - 20-20-20 rule for dry eye and digital eye strain',
    description: 'Official landing page for Dry Eye Widget, an open-source desktop app created by an ophthalmologist for ocular micro-breaks, the 20-20-20 rule, dry eye and digital eye strain.',
    nav: {
      science: 'Science',
      screenshots: 'Screenshots',
      downloads: 'Downloads',
      blog: 'Blog',
      github: 'GitHub'
    },
    langLabel: 'Português',
    langHref: '/app/pt/',
    themeLabel: 'Toggle theme',
    hero: {
      eyebrow: 'Open source · macOS and Windows · created by an ophthalmologist',
      title: 'Dry Eye Widget',
      subtitle: 'Guided ocular micro-breaks based on the 20-20-20 rule to reduce digital eye strain and support ocular surface health.',
      primary: 'View downloads',
      secondary: 'Open-source project',
      doctor: 'Created and clinically documented by Dr. Philipe Saraiva Cruz, ophthalmologist.',
      chips: ['Every 20 min', 'Look 20 ft away', 'For 20 sec', 'Complete blink']
    },
    proof: [
      { value: '~50%', label: 'dry eye prevalence among visual display terminal workers in meta-analysis' },
      { value: '~30%', label: 'documented productivity reduction in people with symptomatic dry eye' },
      { value: 'up to 14%', label: 'reduction in prolonged reading speed and fluency associated with dry eye' }
    ],
    sections: {
      motivationTitle: 'Clinical motivation',
      motivationBody: 'In ophthalmology practice, prolonged screen exposure repeatedly appears alongside burning, gritty sensation, transient blurred vision, headaches and worsening ocular lubrication. Dry Eye Widget was created to turn a simple evidence-based recommendation into a discreet, continuous reminder integrated with modern work.',
      rationaleTitle: 'Why the app exists',
      rationale: [
        'During cognitive screen work, blink rate and blink amplitude tend to drop. This destabilizes the tear film and increases evaporation.',
        'Sustained near focus maintains accommodative and convergence effort, contributing to asthenopia and discomfort.',
        'The 20-20-20 rule is simple, but adherence fails during deep work. The widget automates the behavioral trigger.'
      ],
      appTitle: 'What Dry Eye Widget delivers',
      appItems: [
        'Translucent overlay that remains visible without blocking normal computer use.',
        'Customizable alert cycle and 20-second guided break.',
        'System tray/menu control for pause, reset and preferences.',
        'Liquid Glass mode, adjustable colors and size.',
        'Eye-drop reminder and OSDI tracking in recent versions.'
      ],
      downloadsTitle: 'Download the latest version',
      downloadsSubtitle: 'Direct links to binaries published on GitHub Releases. The complete project remains auditable as open-source software.',
      mac: 'Download for macOS',
      macMeta: 'Universal DMG for Apple Silicon and Intel',
      windows: 'Download for Windows',
      windowsMeta: 'x64 installer for Windows 10/11',
      portable: 'Portable .zip version',
      screenshotsTitle: 'Screenshots of the app running',
      screenshotsSubtitle: 'Core interface states: guided break, visual customization and symptom tracking.',
      authorityTitle: 'Medical credibility and transparency',
      authorityBody: 'The app was conceived by an ophthalmologist to support preventive behavior. It does not replace consultation, eye examination, diagnosis or individualized treatment.',
      referencesTitle: 'Scientific references',
      referencesIntro: 'The references below support the clinical rationale used in the README and this landing page.',
      blogTitle: 'Blog',
      blogSubtitle: 'Authored articles about dry eye, digital eye strain and healthier screen use.',
      footer: 'Authorship, clinical concept and documentation by Dr. Philipe Saraiva Cruz.'
    },
    screenshots: [
      { image: '/assets/app-floating-widget.jpg', title: 'Discreet floating widget', text: 'Always-visible status ball with cycle progress without blocking the screen.' },
      { image: '/assets/app-menu.jpg', title: 'Quick menu', text: 'Start a break, reset, open guidance, OSDI, updates and settings.' },
      { image: '/assets/app-break-timer.jpg', title: '20-second break', text: 'Ocular-rest countdown with guidance to look about 6 meters away.' },
      { image: '/assets/app-settings.jpg', title: 'Complete settings', text: 'Language, timing, appearance, size, colors and widget preferences.' },
      { image: '/assets/app-guidance.jpg', title: 'Medical guidance', text: 'Educational content about digital eye strain, dry eye and the 20-20-20 rule.' },
      { image: '/assets/app-osdi.jpg', title: 'OSDI questionnaire', text: 'Educational screening to follow dry-eye symptoms over time.' }
    ],
    articleContent: {
      '20-20-20-rule': [
        'The 20-20-20 rule suggests that every 20 minutes of screen use, a person should look about 20 feet away for 20 seconds. The goal is to interrupt sustained near focus and encourage complete blinking.',
        'From an ophthalmology standpoint, the benefit is not only the pause itself. It is the repeatable behavior: relaxing accommodation, blinking with adequate amplitude and allowing tear-film redistribution.',
        'Dry Eye Widget was designed to reduce the adherence barrier. Instead of relying on memory, the reminder appears inside the real work context with low intrusion and continuous visual feedback.'
      ],
      'dry-eye-screens': [
        'Screen-associated dry eye is common because visual behavior changes: we blink less, blink incompletely and keep attention fixed at a near distance for long periods.',
        'In clinical practice, many patients understand the recommendation but cannot sustain it during daily work. This gap between guidance and habit motivated the app.',
        'The proposal is simple: bring a clinic recommendation into the environment where the problem happens, with open-source transparency and an educational approach.'
      ]
    }
  }
} satisfies Record<Lang, any>;
