# Handoff

## Interação líquida da bolinha — 2026-07-11

A v1.24.0 substitui o retorno elástico por uma soltura mais previsível: a
velocidade é limitada, projetada por uma janela curta e interpolada com curva
monotônica. Se o destino estiver perto da borda, a mesma curva conclui o
docking sem salto ou overshoot.

O componente visual reage à pressão e ao arraste com deformação limitada. O
anel preserva o progresso exato e acompanha o material sem comprometer sua
semântica. Com reduzir movimento, inércia e efeitos transitórios são suprimidos.
Validação em `runs/2026-07-11-liquid-orb-qa.md`. Próxima ação: publicar a tag
v1.24.0, acompanhar os workflows e verificar os quatro artefatos da release.

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
