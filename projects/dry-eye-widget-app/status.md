# Status

Updated: 2026-07-12

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
