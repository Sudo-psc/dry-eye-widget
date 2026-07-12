# Handoff

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
