# Plano de UX da bolinha flutuante

Data: 2026-07-17
Status: proposta executável; nenhuma mudança funcional implementada por este plano
Escopo: bolinha compacta, docking, menu acionado pela bolinha, feedback de estado,
acessibilidade, onboarding contextual e validação macOS/Windows

## Resultado esperado

A bolinha deve continuar discreta e visualmente distinta, mas sua operação precisa
ser óbvia, previsível e reversível. O usuário deve conseguir abrir o menu com uma
única ativação, mover ou encaixar sem disparar ações por engano, entender o próximo
evento do ciclo, silenciar sinais sem procurar em Configurações e usar um caminho
equivalente por teclado e tecnologia assistiva.

O trabalho preserva a identidade liquid-glass, a execução local, as preferências
existentes e a estabilidade recente de posição, menu e múltiplos monitores.

## Baseline observado

- O visual, o anel de progresso, o hover, a pressão, a soltura e o docking já foram
  refinados. Não há justificativa para outro redesign cosmético no primeiro ciclo.
- A bolinha e o menu usam a mesma janela nativa transparente. Expansões temporárias
  devem continuar usando `CompactWindowAnchor` e a fila serial de layout; nenhuma
  coordenada temporária pode substituir a posição compacta persistida.
- Quando encaixada, a ativação primária apenas solta a bolinha; uma segunda ativação
  é necessária para abrir o menu.
- O cursor permanece com aparência de arraste mesmo quando o orbe não é arrastável,
  como dentro do menu aberto.
- O rótulo semântico sempre promete abrir o menu, inclusive quando a ativação solta
  a bolinha ou fecha o menu. O nó semântico não expõe uma ação de ativação própria.
- O componente não possui foco, atalhos ou ações de teclado. O menu aceita parte da
  navegação por teclado, mas não oferece Escape nem retorno de foco certificado.
- Uma configuração suportada pode ocultar Dock/taskbar e item da barra/tray, deixando
  a bolinha pointer-only como única entrada prática.
- A área de gesto acompanha o visual, o anel ou a pílula; nos tamanhos pequenos e
  no docking, a porção útil pode ficar abaixo da meta de 44 x 44 px.
- O progresso acessível é apenas uma porcentagem, sem dizer que se refere à próxima
  pausa nem informar tempo aproximado.
- Reduzir movimento desliga a íris ambiente e a animação contínua do anel, mas não
  elimina todas as transições de hover, pressão, alerta e lembrete.
- O lembrete visual vem ligado, fica visível por 1,8 s e, no padrão, repete a cada
  7,5 s. Isso equivale a presença visual em cerca de 24% do tempo; no modo frequente,
  o valor chega a 40%. O formato e a pausa temporária do sinal merecem validação.
- O onboarding ensina o clique, mas não demonstra anel, arraste, docking ou estados.
  A prévia de Configurações é uma aproximação, não o `FloatingBall` real.
- Quarenta e oito testes focados de bolinha, menu, docking, movimento e layout passam,
  mas não existe teste de integração do shell/janela nativa.
- A prévia golden da bolinha não participa do CI e já diverge do renderer atual; ela
  não pode ser usada como certificação visual até ser reconciliada.

## Guardrails

- Não reintroduzir inclinação, deformação ou aceleração interna guiada por velocidade.
- Não adicionar animação contínua nova no estado ocioso.
- Não roubar foco do aplicativo em uso apenas para tornar a bolinha navegável.
- Nunca permitir que todas as entradas acessíveis por teclado sejam ocultadas ao mesmo
  tempo sem oferecer uma alternativa equivalente.
- Não misturar os controles visual e sonoro dos lembretes; ambos continuam independentes.
- Não adicionar telemetria. Métricas de uso só entram em pesquisa consentida ou em
  contadores locais explicitamente exportados pelo participante.
- Não alterar timer, conteúdo clínico, DVRS, HealthKit ou landing fora da paridade
  visual/documental necessária após uma futura release.
- Não iniciar implementação sobre o worktree atual sem antes integrar ou isolar as
  mudanças pendentes em `main.dart`, `floating_ball.dart` e `window_layout.dart`.
- Usar WCAG 2.2 AA como referência adaptada ao desktop: texto 4,5:1; foco e componentes
  3:1; conteúdo utilizável a 200%; foco visível; alvo interno de 44 x 44 px; nenhuma
  animação contínua não essencial com Reduzir movimento.

## Marco 0 — Baseline focado e contrato de interação

Objetivo: medir as falhas reais e congelar um contrato antes de mudar comportamento.

Tarefas:

- Cronometrar tarefas formativas com cinco participantes no macOS: abrir o menu solta;
  abrir encaixada; mover; encaixar; retirar da borda; explicar o anel; silenciar o aviso.
- Repetir a matriz no Windows 10/11 quando houver ambiente real, em 100%, 150% e 200%
  de escala e, se possível, com dois monitores.
- Registrar primeira tentativa, tempo, cliques, arrastes acidentais, hesitações e
  interpretação dos estados. Reusar as sessões humanas UX-02/UX-40/UX-41 já pendentes.
- Prototipar duas affordances em captura ou build local: cursor de clique em repouso
  com estado de agarrar durante arraste, e cursor de arraste com dica contextual.
- Aprovar este contrato: ativação primária abre/fecha; arraste move; arrastar da borda
  solta; ativação secundária segue uma convenção desktop explícita.

Definição de pronto:

- Baseline e gravações/observações salvos em `projects/dry-eye-widget-app/runs/`.
- Uma única tabela de estados descreve idle, hover, pressionada, arrastando, encaixada,
  menu aberto, pausa próxima, pausa ativa, ciclo pausado e ciclo estendido.
- Não há comportamento oculto sem rótulo, dica ou alternativa encontrável.

O Marco 0 é formativo e roda em paralelo. Ele não bloqueia correções já demonstradas:
semântica incorreta, alvo mínimo, Escape, movimento reduzido e suspensão em background.

## Marco 1 — Interação previsível e acessível

Prioridade: P0, antes de novo polish visual.

Tarefas:

- Fazer a ativação primária abrir o menu tanto solta quanto encaixada. No estado
  encaixado, o menu abre preservando a âncora; arrastar para dentro solta a bolinha.
  Oferecer uma ação explícita de “Soltar da borda” apenas se o teste mostrar necessidade.
- Separar tamanho visual e alvo de interação. Manter no mínimo 44 x 44 px utilizáveis
  dentro da tela em todos os tamanhos, sem aumentar obrigatoriamente o círculo.
- Calcular docking pelo retângulo interativo, não por 62% fixos da janela. A área de
  44 x 44 px pode ser assimétrica e avançar para dentro da tela enquanto o círculo
  continua meia-lua; se o gerenciador nativo não preservar esse hit-test, tamanhos
  pequenos ficam totalmente dentro da tela em vez de sacrificar acesso.
- Corrigir o cursor por estado: clicável em repouso/menu; agarrando apenas durante
  arraste; neutro em superfícies puramente visuais.
- Criar rótulo, valor e dica semânticos dinâmicos. Exemplos: “Próxima pausa em 6 min”,
  “Encaixada à direita; ativar para abrir o menu” e “Menu aberto; ativar para fechar”.
- Expor a ação semântica de ativação. Testar Enter e Espaço somente se a janela puder
  receber foco sem interromper o trabalho; caso contrário, certificar o menu da barra
  do sistema como caminho equivalente para abrir menu, iniciar/pausar/retomar pausa,
  abrir Saúde visual/Configurações e sair; documentar qualquer limitação nativa.
- Fazer um spike de foco antes da implementação: opção A torna o orbe focável sem
  autofocus e usa `FocusNode`/Actions; opção B mantém o orbe fora da tabulação e torna
  tray/barra uma entrada obrigatória. Escolher por evidência macOS/Windows, não assumir
  que `Semantics` sozinho fornece Enter, Espaço ou restauração de foco.
- Oferecer alternativa sem arraste para posição/docking, por exemplo borda esquerda,
  borda direita, posição padrão e solta, em uma superfície acessível por teclado.
- Impedir ou explicar a combinação que oculta Dock/taskbar, tray/barra e deixa somente
  a bolinha sem um caminho equivalente de teclado.
- Adicionar Escape para fechar o menu e retornar o foco ao ponto anterior quando houver
  foco, sem focar a janela automaticamente.
- Substituir o atalho invisível de botão direito por um menu contextual convencional,
  ou torná-lo explicitamente descobrível. A decisão final depende do teste do Marco 0.
- Extrair somente a política de intenção necessária para testes; evitar reescrever o
  shell. Criar um `OrbWindowPort` injetável para tamanho, posição, foco e visibilidade,
  além de `WindowListener` para eventos nativos; o fake verifica ordem e persistência.

Definição de pronto:

- Menu abre com uma ativação em qualquer estado compacto.
- Arrastar nunca dispara o clique subsequente e clicar nunca inicia movimento da janela.
- Alvo útil mínimo certificado nos tamanhos 18, 32 e 96 px e nos dois lados do docking.
- VoiceOver e Narrator encontram nome, estado e ação coerentes; nenhum anúncio periódico
  intrusivo é criado para o lembrete de piscar.
- Escape, fechamento pela bolinha e fechamento pelo fundo restauram estado e posição.
- Teste de shell com janela falsa cobre abrir, fechar, docking, restauração, persistência
  e duas solicitações rápidas de layout.

## Marco 2 — Controle de interrupções e movimento

Prioridade: P0; executar no mesmo primeiro incremento do Marco 1.

Tarefas:

- Separar formato do lembrete de sua frequência: brilho ambiente, brilho com texto e
  som opcional continuam escolhas independentes.
- Testar brilho ambiente como padrão de menor interrupção antes de substituir a pílula
  textual. Não mudar o default apenas por preferência interna da equipe.
- Incluir “Silenciar lembretes por 15 min” e “Silenciar por 1 h” em no máximo duas ações,
  com estado e horário de retomada visíveis. O silêncio temporário suspende visual e
  som; as preferências permanentes continuam independentes. Não acoplar a “Estender ciclo”.
- Apresentar a escolha de intensidade/formato no onboarding ou na primeira dica, com
  default seguro e possibilidade de alterar depois.
- Fazer Reduzir movimento zerar ou encurtar também hover, pressão, burst, reminder e
  piscar de alerta, preservando mudança estática de cor/estado.
- Suspender o relógio da íris e qualquer repaint quando a janela estiver oculta; o
  widget desabilitado não deve continuar consumindo ciclos em background.
- Não usar live region a cada 4,5–12 s. Qualquer anúncio de piscada deve ser opt-in e
  avaliado com usuários de leitor de tela.

Definição de pronto:

- Silêncio temporário é encontrado em até duas ações e termina automaticamente.
- O usuário sempre sabe se sinais visuais e sonoros estão ativos, silenciados ou opt-out.
- Com Reduzir movimento, não existe animação contínua não essencial nem transição longa.
- O preset/default escolhido obtém nota de incômodo de no máximo 2/5 para pelo menos
  80% da amostra após três dias de uso.

## Marco 3 — Estado, descoberta e docking legível

Prioridade: P1.

Tarefas:

- Exibir uma dica contextual local nas primeiras utilizações: “Clique para abrir ·
  arraste para mover”. Encerrar a dica assim que ambas as ações forem demonstradas e
  nunca repeti-la indefinidamente.
- Experimentar, somente se a dica simples não resolver descoberta, um resumo após hover
  intencional de aproximadamente 500 ms. Ele deve ancorar para dentro da tela, reutilizar
  a âncora compacta e nunca persistir a geometria expandida.
- Representar pausado e ciclo estendido com sinal redundante a cor: pequeno glifo e
  texto acessível. O anel continua representando somente progresso.
- Experimentar uma prévia discreta de docking apenas se os testes registrarem encaixe
  acidental ou falta de previsibilidade e houver evento nativo de movimento. Não usar
  polling contínuo para contornar o contrato atual de `windowManager.startDragging()`.
- No modo encaixado, manter a calma visual, mas revelar estado/progresso no hover ou
  foco. Calcular a fração visível pelo círculo ou garantir um alvo interno constante,
  não apenas por porcentagem da janela.
- Confirmar pausar, retomar, reiniciar e estender com feedback curto. Avaliar desfazer
  para reset apenas se ocorrerem resets acidentais; não adicionar diálogo modal.

Definição de pronto:

- Novos usuários identificam clique, arraste e significado do anel sem ajuda em pelo
  menos quatro de cinco sessões moderadas.
- Estado de pausa, extensão e silêncio é reconhecido sem depender somente de cor.
- Hover/dica não desloca a posição compacta, não aparece durante alertas e não rouba foco.
- A previsão de docking corresponde ao lado realmente persistido em todos os monitores.

## Marco 4 — Personalização simples e alta visibilidade

Prioridade: P2, condicionada ao resultado dos Marcos 0–3.

Tarefas:

- Avaliar presets “Calmo”, “Padrão” e “Alta visibilidade” como atalhos sobre as opções
  atuais; manter controles avançados e nunca sobrescrever personalização sem confirmação.
- Usar o `FloatingBall` real na prévia de Configurações e no exercício do onboarding,
  cobrindo 18–96 px, anel, opacidade, hover, movimento reduzido e docking.
- Adicionar modo de alto contraste ou adaptação à preferência do sistema. Validar preto,
  branco, opacidade mínima, efeito desligado e fundos claros/escuros.
- Combinar corretamente a escala de texto do sistema com a preferência local e elevar
  a matriz certificada de 160% para 200%, sem cortar o menu fixo.
- Aumentar textos muito pequenos do menu e preservar o painel de 300 px sem perda de
  rótulo a 200% de escala.

Definição de pronto:

- A prévia corresponde ao componente real e não mantém um segundo renderer divergente.
- Todas as combinações suportadas mantêm contorno/estado perceptível sobre fundo claro
  e escuro.
- Presets reduzem o tempo de configuração sem remover granularidade existente.

## Marco 5 — Verificação e gate de release

Automação:

- Testes de estado e gestos: ativação, pan, supressão de clique, docking em ambos os lados,
  menu aberto e ações durante alerta.
- Testes semânticos: flag de botão, ação tap, nome, hint, valor por estado e ausência de
  anúncios periódicos não solicitados.
- Testes de teclado: Enter, Espaço, Escape, ordem completa de Tab, foco visível e retorno.
- Testes geométricos: alvo mínimo, limites exatos do threshold, snap desligado, DPI,
  taskbar, origem negativa, tamanhos 18/32/96 e menu nos quatro cantos.
- Testes de ciclo de vida: janela oculta suspende timers/repaints; alternar Reduzir
  movimento durante alerta, hover e lembrete interrompe controladores já ativos.
- Teste de shell com `window_manager` falso e um driver nativo display-aware quando o
  harness estiver estável.
- Goldens de seis estados canônicos: idle solta, encaixada, lembrete, progresso urgente,
  menu abaixo e menu acima. Cobrir hover, pressão, pausa, extensão, tamanhos e idiomas
  por testes determinísticos ou uma matriz visual amostrada, sem explosão combinatória.
- Atualizar o baseline visual somente após aprovação e executar os goldens no CI; apertar
  os limites de fase para que aumentos relevantes de frequência não passem despercebidos.
- `flutter analyze`, testes focados, suíte completa e builds macOS/Windows em série.

QA manual:

- macOS com VoiceOver e Windows com Narrator.
- Mouse e touchpad; 100%, 125%, 150% e 200% de escala; um e dois monitores.
- Bordas esquerda/direita, taskbar/dock, fullscreen, Spaces e reinício do app.
- Reduzir movimento, alto contraste, fundos claros/escuros e tamanhos mínimo/máximo.
- Medição de CPU e frame pacing no mesmo hardware/baseline; nenhuma regressão superior
  a 15% no idle e nenhum novo timer/repaint contínuo.

Gate de produto:

- Uma ativação para abrir o menu, solta ou encaixada; mediana menor que 2 s.
- Na validação somativa com pelo menos dez participantes, pelo menos 90% descobrem o
  menu em até 10 s.
- Pelo menos 80% explicam o anel, movem e encaixam sem ajuda, avaliados como três tarefas.
- Cem por cento das ações essenciais têm caminho de teclado/tecnologia assistiva.
- Zero saltos de posição, persistência de coordenada transitória ou janela inalcançável.
- Zero regressões críticas de foco, contraste, movimento reduzido e desempenho.
- Capturas Windows e macOS, README e landing reconciliados somente após o comportamento
  final estar validado em cada plataforma.
- A captura pública Windows antiga e seu claim DVRS obsoleto devem ser substituídos ou
  retirados antes da próxima release, sem esperar por todo o roadmap da bolinha.

## Mapa de implementação

- `lib/widgets/floating_ball.dart`: alvo, cursor, foco, Semantics, estados visuais e
  respeito integral a Reduzir movimento.
- `lib/main.dart`: contrato de ativação/docking, dica/status ancorado, silêncio temporário,
  foco e coordenação da janela.
- `lib/app/window_layout.dart`: layouts transitórios e testes de âncora.
- `lib/utils/edge_snap.dart` e `lib/utils/orb_motion.dart`: alvo visível, previsão de
  docking e matemática determinística, sem reintroduzir deformação por velocidade.
- `lib/models/widget_settings.dart`, `lib/widgets/settings_dialog.dart` e
  `lib/widgets/onboarding/onboarding_flow.dart`: preferências, prévia real e descoberta.
- `lib/l10n/app_strings.dart`: rótulos, hints e feedback PT-BR/EN.
- `test/floating_ball_test.dart`, `test/floating_menu_test.dart`,
  `test/edge_snap_test.dart`, `test/orb_motion_test.dart`,
  `test/window_layout_test.dart` e novo teste de shell/integração: contrato verificável.

## Ordem recomendada

Primeiro integrar ou isolar o worktree atual. A entrega P0 reúne Marcos 1 e 2, com o
Marco 0 formativo em paralelo: interação, alvo, semântica, teclado, silêncio, movimento
e teste do shell. A entrega P1 reúne o núcleo do Marco 3 e contraste/escala do Marco 4:
feedback, onboarding e alta visibilidade. A entrega P2 contém presets condicionais,
validação multiplataforma e gate de release. Cada entrega deve ser implementada por um
executor e certificada por revisão separada antes da seguinte.

O gate implementável localmente termina com análise, testes, fake de janela, build e QA
macOS. A release multiplataforma permanece explicitamente bloqueada até o mesmo contrato
de foco, hit-test, docking e janela passar em Windows real; não inferir essa paridade a
partir de testes geométricos Dart.
