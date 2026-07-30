# Status

Updated: 2026-07-29

## Release 1.26.1 — publicada em 2026-07-29

A correção 1.26.1+77 restaura a pausa por inatividade sem reaprender ausências
reais como presença parada. O aprendizado adaptativo agora recebe apenas sinais
explícitos de presença, e o estado v1 potencialmente contaminado pela 1.26.0 é
descartado uma vez no carregamento. A retomada natural do mouse ou teclado
continua removendo a pausa automaticamente.

As páginas do menu passaram a usar fade-through de 180 ms, ancorado no topo,
com escala sutil e sem dois conteúdos legíveis ao mesmo tempo. Reduzir movimento
continua zerando a transição. A captura revisada está em
`/Users/philipecruz/.codex/visualizations/2026/07/29/019fb032-c54f-7122-99d3-d1eeb74bb649/menu-transition-v1.26.1.png`.

Passaram análise estática, 361 testes, smoke da landing, readiness de metadados,
testes do pipeline, diff-check e build macOS Release universal. O app informa
1.26.1+77; a assinatura ad hoc deep/strict e o DMG passam nas verificações. O
DMG local tem 29.179.098 bytes e SHA-256
`0c8cd63af10e5762206e834d761b83ffdf474f21c7db0ae80d1bc97926925682`.

O commit `7bb922086b90d4f15a0a3647feab12eb0a2d7a8d`, a tag anotada
`v1.26.1` e a GitHub Release pública existem. CI, Pages, macOS, Windows, MSIX e
fan-in passaram. O bundle com quatro binários e três manifestos foi validado
contra o digest canônico
`87c17e22a6f16383f0b10c8e3a20d17be4265dea506137fff7d1807e1c9bdd40`
antes da aprovação e da publicação manual. Os quatro downloads públicos foram
baixados novamente e reproduziram os hashes dos manifestos. GitHub Pages serve
1.26.1; o domínio personalizado responde HTTP 200, mas sua página não expõe o
marcador de versão usado no gate.

O vídeo `gemini_generated_video_B3916D35.mp4` permanece não rastreado e ficou
fora do commit, tag e release. Evidência:
`runs/2026-07-29-v1.26.1-inactivity-menu-release.md`.

## Release multiplataforma 1.26.0 — quarta revisão concluída

Metadados estão sincronizados em 1.26.0+76 e MSIX 1.26.0.0. Análise estática,
356 testes, smoke da landing, gate de metadados, build macOS Release universal,
assinatura ad hoc deep/strict e integridade do DMG passaram. A release também
retira o total DVRS das superfícies educativas, corrige restauração em monitores
desconectados e melhora reduzir movimento e acessibilidade da landing.

Após o parecer independente, os workflows acionados por tag deixaram de receber
secrets. O fan-in usa a default branch confiável, valida tag, source SHA e
ancestralidade de `main` em um único job somente leitura e produz apenas um
bundle de evidência. Nenhum workflow possui `contents: write` ou chama o
publicador de GitHub Release. A publicação ficou como operação manual separada,
bloqueada por aprovação explícita vinculada à tag, ao commit e ao digest
canônico dos quatro artefatos e três manifestos revisados.

O DVRS não deriva mais melhora/estabilidade/piora do total legado. Dashboard e
histórico usam perfil e deltas neutros por domínio com rótulos PT/EN. Mensagens
educativas e alertas públicos são derivados por chave semântica localizada e
`safetyAlertLevel`; nenhum texto público integra o modelo serializado. O
carregamento remove `educationalMessage` e `safetyAlertMessage` legados antes
de expor o histórico. O PDF deriva texto PT atual apenas do nível. As 16
perguntas, opções, instruções, progresso, acessibilidade e alertas do DVRS são
cobertos em PT/EN. A landing reconstrói os `aria-labels` dos dots quando o
idioma muda. O vídeo
`gemini_generated_video_B3916D35.mp4` permanece não rastreado e é rejeitado pelo
gate caso apareça no bundle.

O build macOS da quarta remediação exigiu renovar o selo ad hoc externo após o
Xcode deixar `App.framework` posterior à assinatura. A verificação deep/strict
passou depois da resselagem, preservando identificador, entitlements e flags.
O DMG atual tem 29.177.791 bytes e SHA-256
`b6b69044374316c6cd7632bfb4266e190f23e424c3deeaa0f2c9f794baf5854f`.

O publicador manual agora falha localmente se a aprovação não corresponder aos
bytes exatos dos sete arquivos, inclusive quando todos os artefatos e manifests
são substituídos de forma internamente coerente. Após publicar, a reconciliação
converge `latest` para a maior SemVer estável em qualquer ordem testada.

A quarta revisão independente somente leitura terminou com
`P0=0 / P1=0 / P2=0` e nenhum achado confirmado. O snapshot revisado permaneceu
em `HEAD 71296726616d5c67d47204c8474ca519bcbd2de7`, com 49 rastreados
modificados, 13 não rastreados, staging vazio, fingerprint do diff rastreado
`814ac7d3339a3c039b0c712c15ddc5ba297f4265b301945cdf4e1f3846006c2e`
e inventário dos 12 não rastreados do patch
`8e7974a3e7567ab3b86c0e289a92e27bac4afc40c7a6ec93df535f5e03f4ec0b`.
O revisor confirmou que não alterou arquivos nem estado remoto.

Próximo passo: solicitar autorização explícita e separada para
commit/push/tag. Somente depois dos runners e do fan-in read-only produzirem o
bundle validado, revisar os sete arquivos e solicitar nova aprovação explícita
`tag+commit+digest` para a publicação manual. Commit, push, tag, upload e
publicação continuam proibidos até as respectivas autorizações. A integração
HealthKit descrita em registros antigos pertenceu a uma branch histórica e não
existe na `main` atual.

## Release multiplataforma 1.25.2 — publicada em 2026-07-29

A v1.25.2 foi preparada em worktree isolado para não misturar o patch local da
1.26.0. O commit `25bf6b04c582e59dd75fe95f18383f893c2bdf8f`, a tag anotada
`v1.25.2` e a GitHub Release pública existem com os quatro artefatos esperados.
Evidência: `runs/2026-07-29-v1.25.2-release.md`.

## Release multiplataforma 1.25.1 — publicada em 2026-07-25

Metadados sincronizados como 1.25.1+74 e MSIX 1.25.1.0. Análise estática,
320 testes, smoke da landing, captura determinística do ciclo, build macOS
Release e geração do DMG passaram. O commit `813afcf`, a tag `v1.25.1` e a
GitHub Release pública foram enviados. CI, Pages, macOS, Windows e MSIX passaram;
os quatro artefatos foram baixados e reconciliados por hash, integridade e
metadados. O DMG permanece sem Developer ID/notarização e o instalador sem
Authenticode porque os respectivos segredos não estão configurados. Evidência:
`runs/2026-07-25-v1.25.1-multiplatform-release.md`.

## Redesign calmo do ciclo 20-20-20 — concluído em 2026-07-25

O ciclo manteve estados, timers e ações, mas a camada visual agora usa tokens
semânticos, escala modular 1,25, contador tabular, uma única progressão ambiental
e motion finito. Overlay, pausa suave, orbe, menu e componentes comuns deixaram
de competir por atenção. Gates cobrem contraste AA/AAA, live regions, teclado,
44 px, alto contraste, reduzir movimento e ausência de loops decorativos.
Evidência: `runs/2026-07-25-calm-cycle-redesign.md`.

## Quick win de legibilidade UI/UX — concluído em 2026-07-25

Menu e Resumo do dia não usam mais rótulos visíveis menores que 11 px nos
pontos auditados. Um token tipográfico reutilizável fixa 11 px para microtextos
e 12 px para conteúdo auxiliar. O contraste do Resumo subiu de 62–72% para
74–82% nos textos secundários afetados. Doze testes focados, análise estática e
a suíte completa passaram. Evidência:
`runs/2026-07-25-ui-ux-quick-win-legibility.md`.

## Movimento suave e magnetismo acelerado — concluídos em 2026-07-16

A íris interna agora filtra amostras de arraste, limita energia e combina o
vetor suavizado com a soltura, evitando inversões e saltos visuais. O docking
lateral ganhou curva própria: acelera até 72% do percurso e conclui em 125–220
ms, com pouso curto sem overshoot. Análise, 19 testes focados, suíte completa com
254 testes, build macOS Release e execução local passaram. Evidência:
`runs/2026-07-16-smooth-orb-magnetic-acceleration.md`.

## Íris aurora e teste local — concluídos em 2026-07-16

O efeito interno da bolinha foi redesenhado como uma lente “íris aurora”, com
paralaxe aquática, halo, reflexo cáustico e gota orbital. O repaint contínuo de
60 Hz foi removido: o efeito usa relógio discreto de 10 Hz em repouso e cerca de
17 Hz no alerta, permanecendo estático com Reduzir movimento. Na amostra local,
o Release caiu de 11,9–19,7% para 2,3–3,6% de CPU estabilizada, com 44–45 MB de
memória. Análise, testes focados, suíte completa, build macOS Release e inspeção
visual real passaram. Evidência: `runs/2026-07-16-iris-aurora-local-test.md`.

## Revisão de performance e build — concluída localmente em 2026-07-16

A revisão pós-UI/UX eliminou amplificação de escrita no onboarding: sliders agora
alteram somente o rascunho local e as configurações são entregues uma vez ao
concluir ou pular. O `SettingsProvider` também ignora estados normalizados
idênticos, evitando persistência e reconstrução redundantes. O DVRS ganhou um
orçamento de regressão que mantém no máximo quatro cartões de pergunta montados
na vizinhança visível durante a rolagem.

Baseline: um único gesto no slider gerava duas atualizações antes da conclusão.
Estado final: zero atualizações durante a edição e exatamente uma ao concluir.
Configuração idêntica gera zero notificações do provider.

Validação local: análise limpa; 249 testes aprovados; build e prerender da página
Science aprovados; smoke da landing aprovado; goldens UI/UX PT/EN aprovados;
build macOS release universal x86_64/arm64 aprovado; DMG verificado com SHA-256
`e99ac90a31309837704904a93ee4f953f05a477f37e712b68df4f0997b38d4f5`.
O build Windows foi tentado e corretamente recusado pelo Flutter no host macOS.
Os workflows Windows Build e Windows MSIX permanecem configurados para runner
`windows-latest`, mas exigem push/dispatch ou um host Windows real.

Evidência: `runs/2026-07-16-ui-ux-performance-build.md`.

## UI/UX vNext — implementação automatizável concluída em 2026-07-16

Os recortes implementáveis localmente dos Marcos 0 a 4 foram concluídos. O Hub
mantém Hoje, Tendências, DVRS e Relatórios, e Tendências deixou de abrir uma
terceira barra de abas. O Resumo do dia tem uma ação primária contextual.
Configurações usa Geral, Lembretes, Aparência e Privacidade, com prévia viva da
bolinha. O onboarding caiu de cinco telas informativas para três etapas práticas
que aplicam ciclo, tamanho e notificações. O DVRS agrupa perguntas por domínio e,
se incompleto, informa quantas faltam e leva à primeira pendência.

O gate de linguagem cobre app e landing. Hub, Configurações e onboarding passam
em escala de texto de 200%. Foram geradas 16 capturas baseline e 16 finais em
PT-BR/EN. `flutter analyze` passou sem ocorrências, os 246 testes passaram, o
smoke da landing passou e o build macOS release gerou um app de 59,4 MB.
Evidência: `runs/2026-07-16-ui-ux-vnext-implementation.md`.

Permanecem externos: tarefas cronometradas e sessões moderadas com usuários,
leitor de tela/contraste em hardware real, build e QA Windows e frame pacing.

## Release 1.24.2 publicada — concluída em 2026-07-12

A segunda rodada de performance reduz trabalho contínuo em duas camadas. A
bolinha e o anel limitam atualizações visuais ao necessário, e o cronômetro
global agora reconstrói somente a superfície que exibe progresso ou contagem.
Painéis estáticos deixam de reconstruir a cada segundo; estatísticas de
atividade ficam isoladas no painel de tempo de tela. A versão foi sincronizada
como 1.24.2+72. Análise, 238 testes, Science build, smoke da landing, build
macOS e DMG passaram. Evidência:
`runs/2026-07-12-v1.24.2-performance-release.md`.
O commit `b7765b6`, a tag `v1.24.2` e a GitHub Release pública foram enviados.
CI, Pages, macOS, Windows e MSIX passaram; os quatro artefatos foram baixados
e reconciliados por hash e integridade. GitHub Pages serve 1.24.2; o nginx do
domínio personalizado permanece em 1.23.0.

## Release 1.24.1 publicada — concluída em 2026-07-12

A versão foi sincronizada como 1.24.1+71 no app, MSIX, landing, README,
roadmap e changelog. Análise, suíte completa e smoke da landing passaram. O
build macOS universal foi gerado e empacotado localmente. O commit `03be377`,
a tag `v1.24.1` e a GitHub Release pública foram enviados. CI, macOS Build,
Windows Build, Windows MSIX e Pages passaram; os quatro artefatos publicados
foram baixados e tiveram integridade e metadados verificados. O GitHub Pages já
mostra 1.24.1; `olhossecos.com.br/app/` ainda serve 1.23.0 pelo nginx externo.
Evidência: `runs/2026-07-12-v1.24.1-release-build.md`.

## Anel de progresso contínuo — concluído em 2026-07-12

O anel da bolinha agora usa um arco contínuo em camadas, com trilha profunda,
halo, gradiente, reflexo interno e ponta luminosa. Espessura e afastamento se
adaptam ao tamanho da bolinha, e a proximidade da pausa recebe um aquecimento
discreto sem alterar a leitura exata do progresso. O desenho deixou de pintar
até 48 segmentos por frame. Reduzir movimento continua removendo pulsação e
animações transitórias. Testes focados, suíte completa, análise estática,
prévia em 32/56/96 px e build macOS release passaram. Evidência:
`runs/2026-07-12-progress-ring-refinement.md`.

## Rodada de UI/UX e bugs — concluída em 2026-07-12

O menu rápido agora expõe rótulos curtos nas quatro ações de pausa, aceita
teclado com foco visível, respeita reduzir movimento e diferencia a ação de
saída. O Resumo do dia tornou o cartão DVRS acionável, elevou o contraste de
textos auxiliares e recupera corretamente quando o adiamento falha. A auditoria
antes/depois, 235 testes, análise estática e build macOS release passaram.
Evidência: `runs/2026-07-12-ui-ux-audit-and-fixes.md`.

## Interação líquida da bolinha — v1.24.0 publicada

Pressão imediata, deformação direcional, inércia curta e docking magnético
suave foram implementados. A trajetória de soltura é monotônica, sem quique ou
overshoot. O anel de progresso ganhou gradiente, profundidade e ponta luminosa,
respeitando reduzir movimento. Passaram 231 testes, análise estática, captura
visual determinística e build macOS release. A release pública contém DMG,
instalador EXE, ZIP portátil e MSIX, todos com integridade verificada após o
download. GitHub Pages exibe 1.24.0. O nginx de `olhossecos.com.br/app/` ainda
serve 1.23.0 e depende do deploy VPS externo. Evidência:
`runs/2026-07-11-liquid-orb-qa.md`.

## Auditoria crítica em três ciclos — concluída

Três falhas de prioridade crítica foram corrigidas: a exclusão LGPD agora
limpa também a atividade mantida em memória e não permite que um flush futuro
restaure dados apagados; a exclusão de resultados DVRS exige confirmação; e a
exportação JSON usa o snapshot vivo de atividade para não omitir amostras ainda
não persistidas. Foram adicionados três cenários de regressão. A suíte completa
com 224 testes, a análise estática e o build macOS release passaram. Evidência:
`runs/2026-07-11-critical-bugs-three-cycles.md`.

## UX em três momentos — implementação concluída

Concluída na branch `codex/ux-three-moments`. O painel rápido agora usa
divulgação progressiva: ações diárias e Hub ficam no primeiro nível; manutenção
e saída ficam numa segunda página Sistema. A altura nominal caiu de 560 para
350 px. O Hub agora preserva aba e contexto ao navegar por DVRS e Relatórios.
DVRS e Relatórios foram incorporados ao Hub, que agora oferece Hoje, Evolução,
DVRS e Relatórios; Evolução contém Hábitos e Indicadores. Estados do Hub foram
padronizados e a navegação foi validada em escala de 160%. Os 215 testes, a
análise e o build macOS release passaram. Evidência:
`runs/2026-07-10-ux-three-moments-menu-evidence.md`.

## 1.23.0 five improvements panel

Shipped: health hub, narrative PDF, My Data, DVRS 1.1, window_layout + ARB scaffold + signing readiness script.

Current phase: five quick-win cycles shipped through 1.22.7 (15 improvements).

Completed:

- Cycles 1.22.3–1.22.7: DVRS/report i18n, done notification with day count, blink frequency, RMB → day summary, stretch cycle 1h, tests.
- Quick wins 1.22.2: proactive insight on break completion (full + gentle); dashboard tabs and reports header localized.
- Quick wins: Day Summary in tray/menu bar; tray labels localized; Progress/Dashboard close tooltips and dashboard title localized; open Day Summary after onboarding.
- Added Day Summary hub (today’s breaks, streak, last DVRS, insight, CTAs).
- Unified local insight engine shared by Day Summary and My Progress.
- Soft DVRS re-evaluation nudge every 14 days (or after first breaks if never taken), with snooze and opt-out.
- Menu health section now leads with Day Summary; analyzer and focused/full tests verified on 2026-07-09.

Previously completed:

- Increased the default floating widget size from 24 px to 32 px and widened the allowed size range to 18-96 px.
- Lowered the default idle opacity to 82% and allowed user opacity down to 20%.
- Enabled the dynamic orb effect by default with lower intensity for a more modern but restrained idle animation.
- Reworked lateral docking so the compact window anchors partially outside the screen edge instead of only clipping the ball inside a fully visible window.
- Added stronger magnetic snap threshold, redock-on-startup behavior, stable redock after size changes, and clean undock when edge snapping is disabled.
- Replaced instant hover scale with a smooth hover animation controller, subtle live breathing, stronger glow on hover, and suppressed text pill while docked.
- Added focused tests for partial edge docking, docked clickability, docked reminder suppression, and updated settings normalization.
- Verified with focused tests, full test suite, static analysis, macOS debug build, and macOS release build.
- Reworked the DVRS questionnaire so all 16 questions appear in one scrollable page, with progress by answered count and a single calculation action after all responses are marked.
- Updated DVRS widget tests for the single-page flow, disabled calculation before completion, result calculation, and history persistence.
- Verified the DVRS change with focused widget tests, full Flutter tests, and static analysis.

Risks:

- The new partial off-screen docking should still be manually inspected on Windows because window managers can clamp off-screen positions differently.
- The dynamic orb effect is now enabled by default; monitor CPU/battery feedback during real use.
- Local Xcode reports CoreSimulator as out of date, but the macOS debug and release builds still completed successfully.
- The new DVRS page should still be manually checked in the real desktop window at narrow sizes to confirm the full-question scroll experience feels comfortable.
