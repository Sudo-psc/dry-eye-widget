# Redesign calmo do ciclo 20-20-20

Data: 2026-07-25

## Diagnóstico em três linhas

O que funciona: a máquina `idle -> alerta -> fase1 -> conclusão`, os timers, o
anel de progresso, as live regions, os alvos de 44 px e a operação por teclado
já formavam uma base funcional e acessível.

O que quebrava a hierarquia: gradientes, brilhos, cores de acento e animações
simultâneas competiam com título, instrução e contador.

O que gerava atrito cognitivo: olho piscando, círculo respirando, contador,
texto, glow e progresso pediam atenção ao mesmo tempo em um produto feito para
reduzir fadiga ocular.

## Mapa preservado

- Estado silencioso: `AppState.idle`; o `TimerProvider` continua contando o
  ciclo e a bolinha mostra o progresso periférico.
- Início da pausa: `AppState.alerta`; texto e estado permanecem, com um único
  feedback visual transitório.
- Pausa ativa: `AppState.fase1`; duração e regressão permanecem, agora com
  contador tabular e anel ambiental único.
- Conclusão: `AppState.conclusao`; insight e streak permanecem, com confirmação
  estática e sem celebração pulsante.
- Superfícies: `FloatingBall`, `FloatingMenu`, `GlassOverlay`,
  `GentleBreakCard`, `TimerDisplay`, `ProgressRing` e `LiquidGlass`.
- Layout responsivo: o app usa janelas nativas por superfície, menu de 280 px,
  pausa suave de 404 px e overlay entre 240 e 400 px. Os gates existentes de
  escala de texto a 200% continuam na suíte.
- Tema: paleta escura de baixa luminância permanece dominante. Alto contraste e
  reduzir movimento são lidos do `MediaQuery`. A troca para uma paleta clara
  não foi introduzida para não reduzir a previsibilidade de contraste da janela
  transparente always-on-top.

## Tokens e decisões

`lib/ui/design_tokens.dart` concentra:

- cores semânticas originadas em OKLCH e convertidas para sRGB do Flutter;
- um único acento funcional azul, com verde, âmbar e coral restritos a estado;
- escala espacial de 4/8 pt e raios por função;
- escala tipográfica modular 1,25 com base 12;
- `RobotoMono`, `tabular-nums` e tracking negativo no contador;
- motion funcional de 220, 320 e 400 ms;
- profundidade apenas para superfícies realmente flutuantes;
- dimensões de controles e alvos, incluindo mínimo de 44 px.

## Diff incremental por componente

1. Tema e tokens: o tema passou a consumir os tokens e a reforçar contorno e
   superfície quando `highContrast` está ativo.
2. Vidro: `LiquidGlass` ficou mais opaco e sem reflexos decorativos; blur e
   sombra comunicam apenas camada flutuante.
3. Overlay: removeu olho piscante e respiração em loop, reduziu a paleta a um
   acento e preservou a live region do estado.
4. Pausa suave: título, instrução e contador foram reorganizados em uma leitura
   horizontal curta, com anel contínuo.
5. Bolinha: a íris passou a lente tonal estática; hover, pressão, lembrete e
   transição do ciclo são feedbacks finitos.
6. Progresso: o anel deixou de aquecer e pulsar perto do prazo; a extensão do
   arco continua representando exatamente o progresso.
7. Tipografia e componentes comuns: tamanhos, cores, espaçamentos, raios e
   ícones migraram para tokens semânticos.

## Checklist validado

Contraste:

- texto principal/contador sobre canvas e superfície: WCAG AAA, gate >= 7:1;
- texto secundário e muted: WCAG AA, gate >= 4,5:1;
- acento funcional: gate >= 4,5:1; foco: gate >= 3:1;
- alto contraste reforça superfície e contorno.

Motion:

- nenhuma superfície ativa contém `.repeat(`;
- apenas transform e opacity nas microinterações;
- durações entre 220 e 400 ms;
- `disableAnimations` zera transições e não deixa callbacks contínuos.

Acessibilidade:

- alvos do orbe, botões e linhas permanecem >= 44 px;
- Enter, Espaço, Escape e foco visível continuam cobertos;
- transições do ciclo e aviso “Pisque” permanecem em live regions;
- o progresso expõe rótulo e valor sem depender somente de cor;
- escala de texto a 200% continua coberta pela suíte existente.

Limites manuais:

- VoiceOver/NVDA precisam ser ouvidos em hardware real; teste de semantics não
  substitui validação auditiva.
- O frame pacing e o comportamento da janela devem ser repetidos em Windows.
- O harness visual gera baselines coloridas de depuração sob texto; os PNGs
  servem para composição/layout, não para aprovar rasterização tipográfica.

## Evidência

- `flutter test`: 320 testes aprovados.
- `flutter analyze`: nenhuma ocorrência.
- `flutter build macos --release -t lib/main.dart`: app gerado com 59,4 MB.
- `tool/calm_cycle_capture_test.dart`: cinco capturas reproduzíveis.
- `test/ui/design_tokens_test.dart`: contraste, escala, tabular-nums e motion.
- `test/ui/calm_motion_contract_test.dart`: bloqueio de loops decorativos.
- `test/glass_overlay_test.dart`: live region do ciclo.
- `test/floating_ball_test.dart`: progresso, teclado, semântica, 44 px e reduzir
  movimento.

## Próximas ações

1. Ouvir as quatro transições com VoiceOver no macOS.
2. Inspecionar o Release sem o overlay de baseline do harness de testes.
3. Repetir contraste, teclado, reduzir movimento e frame pacing no Windows.
