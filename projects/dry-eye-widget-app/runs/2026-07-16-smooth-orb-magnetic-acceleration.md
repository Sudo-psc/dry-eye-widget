# Movimento interno suave e magnetismo acelerado — 2026-07-16

## Objetivo

Suavizar a resposta visual interna da bolinha durante o arraste e tornar o
encaixe lateral mais rápido e magnético, sem reintroduzir quique ou overshoot.

## Implementação

- O vetor visual da íris passou de resposta direta de 42% por amostra para um
  filtro amortecido de 22%.
- A energia do movimento interno foi limitada a 0,82; inversões bruscas não
  mudam instantaneamente a direção visual.
- A transição entre arraste e soltura combina o vetor filtrado com a velocidade
  final, evitando um salto no material interno.
- O docking lateral passou a ter curva própria: acelera até 72% do percurso e
  usa o trecho final para desacelerar e pousar sem impacto.
- A duração magnética agora varia de 125 a 220 ms conforme a distância lateral;
  a inércia comum continua com 180–340 ms.

## Verificação

- `flutter analyze`: sem ocorrências.
- Testes focados de bolinha e trajetória: 19 aprovados.
- Suíte completa: 254 testes aprovados.
- A curva magnética foi verificada em 100 amostras: monotônica, limitada ao
  alvo e sem overshoot; ganho central maior que o ganho inicial e final.
- `flutter build macos --release`: aprovado; app universal de 59,4 MB.
- O selo ad hoc externo foi renovado após o build e
  `codesign --verify --deep --strict` passou.
- O Release foi iniciado localmente e o clique real de desencaixe moveu a
  janela para uma posição totalmente visível, preservando o processo ativo.

## Limite

A trajetória do `windowManager.startDragging` depende do gesto nativo do mouse e
não é reproduzida de forma confiável pelo harness de acessibilidade. A matemática
de soltura e docking está coberta deterministicamente; a sensação final deve ser
confirmada com um arraste manual no macOS e, depois, em Windows real.
