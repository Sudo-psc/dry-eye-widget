export const languages = {
  pt: 'Português',
  en: 'English',
};

export const defaultLang = 'pt';

export const ui = {
  pt: {
    'nav.features': 'Funcionalidades',
    'nav.science': 'Ciência',
    'hero.title': 'Saúde Ocular Digital, Refinada',
    'hero.subtitle': 'Uma ferramenta médica criada por oftalmologistas para combater a fadiga visual digital.',
    'hero.downloadMac': 'Baixar para Mac',
    'hero.downloadWin': 'Baixar para Windows',
    'motivation.title': 'Por que o Dry Eye Widget?',
    'motivation.content1': 'Como oftalmologista, atendo diariamente pacientes sofrendo com a Síndrome da Visão de Computador. O tempo prolongado de tela reduz nossa taxa de piscar em até 66%, causando ressecamento severo e desconforto.',
    'motivation.content2': 'A regra 20-20-20 (a cada 20 minutos, olhar para algo a 20 pés de distância por 20 segundos) é o padrão ouro para prevenção, mas é difícil de lembrar durante o trabalho focado. Por isso, criei este widget: uma solução não intrusiva, baseada em evidências, que cuida dos seus olhos enquanto você trabalha.',
    'carousel.title': 'Interface Limpa e Eficiente',
    'science.title': 'Base Científica',
    'science.ref1': 'American Academy of Ophthalmology. "Computer Vision Syndrome".',
    'science.ref2': 'Blehm C, et al. "Computer vision syndrome: a review". Survey of Ophthalmology. 2005.',
    'science.ref3': 'Portello JK, et al. "Blink rate, incomplete blinks and computer vision syndrome". Optometry and Vision Science. 2013.',
    'footer.author': 'Desenvolvido por Dr. Philipe Cruz, Médico Oftalmologista.',
  },
  en: {
    'nav.features': 'Features',
    'nav.science': 'Science',
    'hero.title': 'Digital Eye Wellness, Refined',
    'hero.subtitle': 'A medical-grade tool created by ophthalmologists to combat digital eye strain.',
    'hero.downloadMac': 'Download for Mac',
    'hero.downloadWin': 'Download for Windows',
    'motivation.title': 'Why Dry Eye Widget?',
    'motivation.content1': 'As an ophthalmologist, I see patients daily suffering from Computer Vision Syndrome. Prolonged screen time reduces our blink rate by up to 66%, causing severe dryness and discomfort.',
    'motivation.content2': 'The 20-20-20 rule (every 20 minutes, look at something 20 feet away for 20 seconds) is the gold standard for prevention, but it is hard to remember during focused work. That is why I built this widget: a non-intrusive, evidence-based solution that cares for your eyes while you work.',
    'carousel.title': 'Clean and Efficient Interface',
    'science.title': 'Scientific Foundation',
    'science.ref1': 'American Academy of Ophthalmology. "Computer Vision Syndrome".',
    'science.ref2': 'Blehm C, et al. "Computer vision syndrome: a review". Survey of Ophthalmology. 2005.',
    'science.ref3': 'Portello JK, et al. "Blink rate, incomplete blinks and computer vision syndrome". Optometry and Vision Science. 2013.',
    'footer.author': 'Developed by Dr. Philipe Cruz, Ophthalmologist.',
  },
} as const;

export function useTranslations(lang: keyof typeof ui) {
  return function t(key: keyof typeof ui[typeof defaultLang]) {
    return ui[lang][key] || ui[defaultLang][key];
  }
}
