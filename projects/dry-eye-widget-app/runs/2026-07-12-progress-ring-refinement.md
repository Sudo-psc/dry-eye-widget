# Refinamento do anel de progresso — 2026-07-12

## Objetivo

Modernizar o anel da bolinha, melhorar legibilidade em todos os tamanhos e
reduzir o custo do desenho sem alterar a semântica do progresso.

## Implementação

- Arco contínuo em vez de até 48 segmentos pintados individualmente.
- Trilha com profundidade, sombra externa e aro interno.
- Progresso com halo, gradiente frio, reflexo interno e ponta luminosa.
- Aquecimento discreto após 75% para indicar aproximação da pausa.
- Espessura adaptativa de 2,4 a 4,4 px e folga de 3 a 5 px.
- Pulsação e shimmer continuam desativados quando reduzir movimento está ativo.

## Verificação

- `flutter test test/floating_ball_test.dart`: passou, 8 testes.
- `flutter test --update-goldens tool/liquid_orb_preview_test.dart`: passou.
- Prévia revisada em 32, 56 e 96 px: `artifacts/liquid-orb-preview.png`.
- `flutter analyze`: passou sem problemas.
- `flutter test`: suíte completa passou.
- `flutter build macos --release -t lib/main.dart`: concluído; app universal
  gerado em `build/macos/Build/Products/Release/Dry Eye Widget.app`.
- `git diff --check`: passou.

## Aprendizado e próxima ação

O arco contínuo preserva a leitura exata e elimina o serrilhado visual que pode
surgir entre segmentos durante transições. A próxima validação útil é medir o
frame pacing da bolinha em hardware Windows de entrada.
