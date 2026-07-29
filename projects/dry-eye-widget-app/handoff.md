# Handoff

## Release multiplataforma 1.26.0 — 2026-07-29

A versão local permanece em 1.26.0+76 / MSIX 1.26.0.0. O DVRS mantém campos
agregados somente para compatibilidade estrutural interna;
`educationalMessage` e `safetyAlertMessage` foram removidos do modelo
serializado. No primeiro carregamento, o storage remove ambos de payloads
antigos. UI, narrativa e relatórios derivam texto atual e localizado por chave
semântica e `safetyAlertLevel`; o PDF deriva texto PT atual somente do nível.
Progresso, instruções, títulos, enunciados, opções, acessibilidade e alertas das
16 perguntas são resolvidos por ids estáveis em PT/EN.

Os workflows de plataforma têm `contents: read`, não recebem secrets e apenas
produzem artefatos internos. O `release-fan-in.yml` é carregado da default
branch, valida source/tag/ancestralidade em job somente leitura, consulta os três
runs pelo mesmo source SHA e preserva o bundle validado como evidência. Não
existe job de publicação, `contents: write`, environment de release ou chamada
a `gh release` nos Actions. O publicador é exclusivamente manual e falha antes
de consultar o remoto sem
`RELEASE_MANUAL_APPROVAL=publish:<tag>@<commit>#<bundle-digest>`, onde o digest
canônico cobre os quatro artefatos e três manifestos revisados.

O DVRS removeu `compareDvrsTrend`, `DvrsTrend` e os rótulos agregados de
melhora/estabilidade/piora. As superfícies usam deltas neutros por domínio e
rótulos localizados. A landing reconstrói os dots após troca PT/EN. Os marcadores
ativos de versão estão em 1.26.0 e o gate rejeita regressão editorial. A
reconciliação pós-publicação escolhe a maior SemVer estável, inclusive quando
duas versões são processadas em ordens opostas.

Gates locais aprovados: 77 testes focados, `flutter analyze`, 356 testes,
smoke da landing,
build Science, actionlint 1.7.12, readiness 1.26.0, testes do pipeline, build
macOS Release universal 1.26.0+76, codesign deep/strict e DMG válido. O segundo
build exigiu renovação do selo ad hoc externo e passou a verificação
deep/strict preservando identificador, entitlements e flags. O DMG tem
29.177.791 bytes, SHA-256
`b6b69044374316c6cd7632bfb4266e190f23e424c3deeaa0f2c9f794baf5854f`
e o app tem CDHash `d6464c6e03b47adda7a2b4efeba946cf01a22c18`.

Base do diff: `71296726616d5c67d47204c8474ca519bcbd2de7`; o estado revisável é
essa base contra o worktree atual, incluindo arquivos novos não rastreados do
pipeline e excluindo
`/Users/philipecruz/app_dry_eye_widget/gemini_generated_video_B3916D35.mp4`.
O vídeo foi preservado com SHA-256
`72f74a1f3ded76933117b3fbc8c8694235853633936f4e54e879278a82c4f385`.

A quarta revisão independente somente leitura foi concluída com
`P0=0 / P1=0 / P2=0` e nenhum achado confirmado. O freeze revisado registrou
49 rastreados modificados, 13 não rastreados, staging vazio, fingerprint
rastreado
`814ac7d3339a3c039b0c712c15ddc5ba297f4265b301945cdf4e1f3846006c2e`
e inventário dos 12 não rastreados do patch
`8e7974a3e7567ab3b86c0e289a92e27bac4afc40c7a6ec93df535f5e03f4ec0b`.
O revisor confirmou ausência de mutação local ou remota.

Próxima ação: solicitar autorização explícita separada para commit, push e tag
`v1.26.0`. Depois que os runners macOS/Windows/MSIX e o fan-in read-only
produzirem o bundle, revisar os quatro artefatos e três manifestos e solicitar
outra aprovação explícita vinculada a `tag+commit+digest` antes de executar o
publicador manual. Não fazer commit, push, tag, upload ou publicação sem a
autorização correspondente. A integração HealthKit citada abaixo é contexto
histórico de uma branch anterior e não está presente na `main` atual.

## Release multiplataforma 1.25.1 — 2026-07-25

O app, MSIX, landing, README e changelog estão alinhados em 1.25.1+74 /
1.25.1.0. Os gates locais passaram: análise limpa, 320 testes, smoke da landing,
captura visual, build macOS Release e DMG. O bundle informa 1.25.1 (build 74);
o DMG local tem SHA-256
`d5c95dc8c271342a1fa75b8e371d23ab52444abe31243803f254c1240209a0a3`.

A `main`, a tag `v1.25.1` e a GitHub Release foram publicadas. CI, Pages, macOS,
Windows e MSIX concluíram com sucesso. Os quatro ativos foram baixados; hashes
coincidem com os digests do GitHub, ZIP/MSIX estão íntegros, MSIX informa
1.25.1.0 e o bundle do DMG informa 1.25.1+74. O DMG usa assinatura ad hoc, sem
Developer ID/notarização; o instalador Windows não tem Authenticode porque o
SignPath não está configurado. Evidência:
`runs/2026-07-25-v1.25.1-multiplatform-release.md`.

## Redesign calmo do ciclo — 2026-07-25

O fluxo `idle -> alerta -> fase1 -> conclusão` e seus timers não mudaram. A
camada visual passou a usar `design_tokens.dart`: paleta escura OKLCH, um único
acento funcional, escala espacial 4/8 pt, tipografia modular 1,25, contador
Roboto Mono tabular e motion de 220–400 ms. Overlay e orbe não mantêm animações
decorativas em loop; progresso, hover, pressão, lembrete e transição continuam
com feedback finito.

Os componentes de pausa, menu e cartões comuns usam superfícies mais opacas e
hierarquia de uma decisão. Contraste AA/AAA, alto contraste, live regions,
teclado, alvo mínimo de 44 px e reduzir movimento têm testes de regressão.
Análise, 320 testes e build macOS Release de 59,4 MB passaram. Evidência em
`runs/2026-07-25-calm-cycle-redesign.md`.

Próximo gate externo: ouvir as transições com VoiceOver e repetir a matriz de
acessibilidade e frame pacing no Windows real.

## Quick win de legibilidade UI/UX — 2026-07-25

O menu flutuante e o Resumo do dia agora usam mínimos explícitos de 11 px para
microtextos e 12 px para conteúdo auxiliar por meio de `AppTypography`. O menu
mantém os quatro atalhos e a largura atual; o Resumo ganhou contraste maior em
rótulos, dicas e aviso educativo. Testes impedem retorno aos tamanhos e
opacidades anteriores. Doze testes focados, análise estática, suíte completa e
`git diff --check` passaram. A evidência está em
`runs/2026-07-25-ui-ux-quick-win-legibility.md`.

## Movimento e magnetismo lateral — 2026-07-16

`FloatingBall.smoothMotionVector` amortece o vetor interno com resposta padrão
de 0,22 e magnitude máxima de 0,82. Na soltura, o vetor filtrado é combinado com
a velocidade final. Em `orb_motion.dart`, docking usa
`magneticDockProgress`: aceleração até 72% e desaceleração final curta. A duração
é proporcional à distância lateral, limitada a 125–220 ms; trajetórias sem
docking preservam a curva e duração anteriores.

Passaram análise, 19 testes focados, 254 testes totais, build macOS Release e
codesign deep/strict. O Release novo está aberto e desencaixado em posição
visível. Evidência em
`runs/2026-07-16-smooth-orb-magnetic-acceleration.md`. Próximo gate externo:
sentir o arraste com mouse no macOS e repetir docking em Windows real.

## Íris aurora e runtime local — 2026-07-16

`FloatingBall` agora desenha uma composição interna de íris/lente com fitas em
paralaxe, halo, cáustica e gota orbital. A animação não mantém mais um ticker de
60 Hz: um timer atualiza 32 fases em 3,2 s no idle e 30 fases em 1,8 s no alerta.
O guardrail em `floating_ball_test.dart` verifica que não há callback transitório
contínuo. Reduzir movimento continua zerando a animação.

O app macOS Release foi aberto e inspecionado encaixado e solto; as preferências
originais foram restauradas. Análise, suíte completa, 12 testes focados e build
Release passaram. A CPU estabilizada observada caiu para 2,3–3,6%, ante
11,9–19,7% antes da troca do relógio. Evidência completa em
`runs/2026-07-16-iris-aurora-local-test.md`. Próxima validação externa: repetir
frame pacing e docking em Windows real. O build final exigiu renovar somente o
selo ad hoc externo após o `App.framework` mudar; a verificação deep/strict
passou depois disso. Automatizar esse gate se a condição reaparecer.

## Performance pós-UI/UX e build — 2026-07-16

O onboarding não persiste mais a cada atualização de slider: mantém um rascunho
local e chama `_finishOnboarding` uma vez com o estado final. O provider descarta
updates semanticamente idênticos antes de `notifyListeners` e da escrita. Testes
de regressão cobrem persistência única, update idêntico e montagem preguiçosa do
DVRS.

Passaram análise, 249 testes, build Science, smoke, captura visual e build macOS
universal. O DMG em `dist/DryEyeWidget.dmg` foi validado; o app está em 1.24.2+72,
com assinatura ad hoc. O host macOS não compila Windows. Para concluir a evidência
multiplataforma real, enviar o commit e executar `Windows Build` e `Windows MSIX
(Store)` via GitHub Actions, ou usar um host Windows.

Detalhes: `runs/2026-07-16-ui-ux-performance-build.md`.

## UI/UX vNext implementado — 2026-07-16

O plano canônico em `docs/superpowers/plans/2026-07-16-ui-ux-vnext.md` foi
executado até o limite verificável no ambiente local. A arquitetura de informação
do Hub foi achatada; o Resumo ganhou CTA contextual; Configurações foram divididas
por intenção; onboarding passou a configurar o app; e o DVRS agora recupera a
primeira pergunta ausente. O gate de claims impede a volta de linguagem clínica
obsoleta no app e na landing.

Validação: análise limpa, 246 testes aprovados, site smoke aprovado, 32 capturas
PT-BR/EN antes/depois revisadas e build macOS release de 59,4 MB concluído. A
evidência e os comandos estão em
`runs/2026-07-16-ui-ux-vnext-implementation.md`.

Próxima ação: executar as cinco tarefas de referência com participantes no macOS
e comparar tempos/cliques; depois repetir build, escala e comportamento da janela
em Windows 125%, 150% e 200%. Não inferir resultados humanos a partir dos testes.

## Release 1.24.2 publicada — 2026-07-12

A bolinha limita o repaint contínuo a fases perceptíveis e o anel só anima a
partir de 90%. Em `main.dart`, o `TimerProvider` saiu da observação do build
raiz e passou a ser consumido apenas no ramo dinâmico; configurações, DVRS,
relatórios, Hub e outros painéis não reconstroem mais a cada segundo. O painel
de tempo de tela usa um consumidor localizado para atividade. Metadados estão
em 1.24.2+72. Análise, 238 testes, Science build, smoke da landing, app macOS
Release e DMG passaram. O commit `b7765b6` e a tag `v1.24.2` foram enviados.
A release pública contém DMG, instalador EXE, ZIP portátil e MSIX; os cinco
workflows passaram e os artefatos baixados tiveram hash, estrutura e versão
verificados. GitHub Pages serve 1.24.2. O nginx externo ainda serve 1.23.0.

## Release 1.24.1 publicada — 2026-07-12

A release patch 1.24.1+71 reúne o anel contínuo adaptativo, as melhorias de
acessibilidade do menu rápido e a recuperação de erro do Resumo do dia. Os
metadados estão alinhados entre Flutter, AppInfo, MSIX, landing, README,
roadmap e changelog. O app macOS universal e `dist/DryEyeWidget.dmg` foram
gerados e o commit `03be377` foi publicado com a tag `v1.24.1`. A release está
pública em `https://github.com/Sudo-psc/dry-eye-widget/releases/tag/v1.24.1`
com DMG, instalador, ZIP portátil e MSIX. CI e todos os workflows de plataforma
passaram; os artefatos publicados foram baixados e verificados. GitHub Pages
serve 1.24.1, enquanto o nginx de `olhossecos.com.br/app/` ainda serve 1.23.0.

Próxima ação externa: sincronizar o deploy do nginx/VPS com o conteúdo já
publicado no GitHub Pages. Próxima melhoria interna: migrar as GitHub Actions
que ainda emitem aviso de runtime Node.js 20.

## Anel de progresso contínuo — 2026-07-12

O `FloatingBall` calcula espessura e folga do anel a partir do diâmetro, com
limites para manter leitura entre 18 e 96 px. `_ProgressRingPainter` usa agora
um arco contínuo com trilha, sombra, halo, gradiente, reflexo e ponta luminosa,
substituindo o loop de até 48 segmentos por poucas operações de pintura. A
urgência aquece suavemente o gradiente após 75%, sem mudar a extensão do arco.
Reduzir movimento mantém o desenho estático e sem callbacks transitórios.

Validação: teste focado aprovado, suíte completa aprovada, análise sem erros,
golden revisado em 32/56/96 px e build macOS release concluído. Evidência em
`runs/2026-07-12-progress-ring-refinement.md`. Próxima verificação recomendada:
frame pacing em hardware Windows de entrada.

## Rodada de UI/UX e bugs — 2026-07-12

O primeiro nível do menu preserva quatro ações compactas, agora com rótulos
PT/EN, foco visível e ativação por Enter/Espaço. Linhas e ações rápidas anulam
transições quando reduzir movimento está ativo. O cartão DVRS do Resumo do dia
é um `InkWell` semântico e a falha do adiamento usa `try/catch/finally`, snackbar
localizado e desbloqueio garantido.

Validação final: 235 testes, análise limpa, golden antes/depois em três estados
e build macOS release aprovado. Evidência completa em
`runs/2026-07-12-ui-ux-audit-and-fixes.md`. Próxima melhoria recomendada:
integração nativa para foco/posição de janela e QA manual no Windows.

## Interação líquida da bolinha — 2026-07-11

A v1.24.0 substitui o retorno elástico por uma soltura mais previsível: a
velocidade é limitada, projetada por uma janela curta e interpolada com curva
monotônica. Se o destino estiver perto da borda, a mesma curva conclui o
docking sem salto ou overshoot.

O componente visual reage à pressão e ao arraste com deformação limitada. O
anel preserva o progresso exato e acompanha o material sem comprometer sua
semântica. Com reduzir movimento, inércia e efeitos transitórios são suprimidos.
Validação em `runs/2026-07-11-liquid-orb-qa.md`. A tag v1.24.0 foi publicada e
os quatro artefatos passaram nas verificações de checksum e integridade. A
próxima ação externa é sincronizar o nginx de `olhossecos.com.br/app/`, ainda em
1.23.0, com o GitHub Pages, que já exibe 1.24.0.

## Auditoria crítica em três ciclos — 2026-07-11

O fluxo LGPD foi endurecido em dois pontos: `clearHealthHistory` agora chama o
serviço vivo de atividade para zerar memória e armazenamento, e o mapa exportado
usa `activity.data`, incluindo amostras ainda dentro da janela de persistência.
O histórico DVRS agora mostra confirmação localizada antes de excluir uma
avaliação. Os testes de regressão estão em `test/health_data_service_test.dart`
e `test/dvrs_history_view_test.dart`. Validação final: 224 testes, análise
estática e build macOS release aprovados.

## UX em três momentos — 2026-07-10

Trabalho ativo em `/Users/philipecruz/app_dry_eye_widget-ux-three-moments`,
branch `codex/ux-three-moments`. O primeiro recorte está implementado: painel
principal enxuto, segunda página Sistema, janela menor e retorno contextual
Hub → DVRS → Relatório. A aba ativa do Hub é preservada. DVRS e Relatórios agora
rodam dentro do Hub; Evolução alterna entre Hábitos e Indicadores. Estados vazio,
indisponível, erro e sucesso foram unificados. O design aprovado está
em `docs/superpowers/specs/2026-07-10-ux-three-moments-design.md`; a evidência
está em `projects/dry-eye-widget-app/runs/2026-07-10-ux-three-moments-menu-evidence.md`.

Validação final: 215 testes aprovados, análise limpa, QA automatizado em escala
de 160% e build macOS release aprovado. Próxima ação recomendada: inspeção manual
no macOS e Windows antes de uma release pública.

## Current State

Version target: **1.22.0** — P0 product loop for discovery and retention.

### Day Summary hub
New screen (`lib/widgets/summary/day_summary_screen.dart`) opened from the floating menu as the first Health item. Shows today’s completed/prompted breaks, streak, 7-day adherence, last DVRS, a proactive insight, optional DVRS recheck banner, and CTAs for start break / DVRS / progress / dashboard.

### Insight engine
`lib/services/daily_insight.dart` builds a single local narrative prioritized as: DVRS due/never → streak → 7-day adherence → today → total consistency → start. Shared by Day Summary and My Progress.

### DVRS recheck nudge
- Interval: 14 days (`AppDefaults.dvrsReminderDays`).
- If never taken: after ≥3 completed breaks.
- Surfaces: banner in Day Summary + system notification at most once per day (requires notifications + `dvrsReminderEnabled`).
- Snooze: 7 days via “Lembrar depois”.
- Opt-out: Settings → Geral → “Lembrar reavaliação do DVRS”.

Previous work (still current): DVRS single-page questionnaire, compact widget visual refresh, partial edge docking (meia-lua), hover animation, HealthKit branch notes elsewhere.

## Verification

- `flutter analyze lib test`: passed on 2026-07-09.
- Focused tests: `daily_insight_test`, `day_summary_screen_test`, `floating_menu_test`, `widget_settings_test`: passed on 2026-07-09.
- Full `flutter test`: 197 tests passed on 2026-07-09.

## Next Actions

1. Manually open Day Summary on macOS: insight text, DVRS banner, snooze, CTAs.
2. With notifications on and a stale/missing DVRS, confirm at most one nudge notification per day.
3. Manually inspect DVRS single-page scroll at narrow widths.
4. Inspect edge docking + blink micronotification on Windows before next Windows package.
5. Signing / Gatekeeper / SmartScreen remains the main distribution P0 outside product code.
# Handoff 1.26.1

Data: 2026-07-29

A candidata local 1.26.1+77 corrige a regressão de inatividade e a transição das
páginas do menu. O retorno natural após uma ausência não alimenta mais o modelo
adaptativo; somente a retomada manual e a confirmação opcional por câmera são
sinais de presença parada. O estado persistido v1 é removido no primeiro
carregamento para recuperar instalações afetadas pela 1.26.0.

O menu usa fade-through curto, ancorado no topo e compatível com reduzir
movimento. A captura visual foi revisada e os 361 testes, análise, smoke,
readiness, testes do pipeline, build macOS universal, assinatura deep/strict e
DMG passaram.

Artefato local: `dist/DryEyeWidget.dmg`, 29.179.098 bytes, SHA-256
`0c8cd63af10e5762206e834d761b83ffdf474f21c7db0ae80d1bc97926925682`.
O arquivo `gemini_generated_video_B3916D35.mp4` não pertence ao patch e deve
permanecer fora de staging, commit e release.

Próxima ação: revisar o commit, enviar `main` e a tag `v1.26.1`, acompanhar os
três builds e o fan-in. A publicação da GitHub Release continua bloqueada até
revisar os sete arquivos do bundle e obter a aprovação exata
`publish:<tag>@<commit>#<bundle-digest>`.

---
