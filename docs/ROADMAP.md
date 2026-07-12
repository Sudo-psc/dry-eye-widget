# Roadmap — Dry Eye Widget

Atualizado: 2026-07-11 · Versão atual: **1.24.0**

Documento vivo de prioridades. Itens feitos ficam no CHANGELOG; aqui só o que ainda importa.

## Princípios

1. Privacidade local primeiro — sem telemetria por padrão.
2. Linguagem educativa, nunca diagnóstico.
3. macOS e Windows em paridade de UX crítica.
4. Landing estática rápida (Core Web Vitals) em `/app/`.
5. CI barato e confiável: analyze + test + smoke em todo PR.

## Now (próximas 2–4 semanas)

| # | Item | Área | Impacto | Esforço |
|---|------|------|---------|---------|
| 1 | **Ativar** assinatura com secrets (Apple Developer ID + SignPath) | Distribuição | Alto | Conta/custo |
| 2b | Executar checklist QA-WINDOWS em máquina Win10/11 (humano) | App | Alto | 30–60 min |
| 3 | Validação HealthKit em build assinado | App | Médio | Médio |

### Concluído recentemente (Now)

| # | Item | Evidência |
|---|------|-----------|
| 1a | Pipeline de assinatura macOS + Windows no CI | `docs/CODE_SIGNING.md`, `scripts/macos_*.sh`, workflows condicionais |
| 2a | Protocolo + testes Windows docking/micronotificação | `docs/QA-WINDOWS.md`, `test/edge_snap_test.dart` (cenários Win), run 2026-07-10 |
| 4 | Screenshots Windows na landing | Filtro macOS/Windows + 5 slides Win em `site/assets/shots/windows-*.jpg` |
| 5 | Lighthouse produção pós-deploy | `docs/lighthouse/LATEST.md` — mobile Perf 93 / a11y 90 / BP 100 / SEO 100 |

> **#2a vs #2b:** lógica e checklist prontos; falta carimbo humano em hardware
> Windows real (este ambiente é macOS).

> **#1a vs #1:** o código e o CI estão prontos; falta cadastrar certificado Apple
> e aprovação SignPath (checklist em `docs/CODE_SIGNING.md`). Sem isso as
> releases seguem unsigned com orientação xattr/SmartScreen.

## Next (1–2 meses)

| # | Item | Área | Notas |
|---|------|------|--------|
| 6 | ~~PDF narrativo~~ **feito em 1.23** | App | `NarrativeSummary` no PDF |
| 7 | ~~Unificar hub~~ **feito em 1.23** | App | `HealthHubScreen` |
| 8 | i18n ARB (Flutter gen-l10n) | App | Scaffold ARB em `lib/l10n/arb/` — migração gradual |
| 9 | ~~Fatiar layouts~~ **parcial em 1.23** | App | `lib/app/window_layout.dart` |
| 10 | Decidir se landing fica neste repo ou repo próprio | Site | Bloqueado por decisão |
| 11 | Ativar secrets de assinatura (contas) | Distribuição | Script `check_signing_readiness.sh` |
| 12 | QA-WINDOWS humano em hardware real | App | Checklist em `docs/QA-WINDOWS.md` |

## Later

- Insight semanal opt-in (notificação local)
- Light mode completo no widget
- Exportação agregada de métricas locais (opt-in)
- Monitoramento de SPM warnings dos plugins macOS

## Automação CI

- `ci.yml` — Flutter analyze/test + smoke + version sync + job summary
- `pages.yml` — deploy GitHub Pages + smoke
- `site-scheduled-smoke.yml` — smoke semanal
- `changelog-guard.yml` — bump de versão exige menção no CHANGELOG
- `label-paths.yml` + `labeler.yml` — labels por pasta tocada
- `stale.yml` — higiene de issues/PRs inativos
- `dependabot.yml` — Actions e pub semanalmente
- `ISSUE_TEMPLATE/roadmap-item.yml` + `PULL_REQUEST_TEMPLATE.md`
- Detalhes: `docs/IMPROVEMENT-AUTOMATION.md`

## Ciclos recentes

### Landing round 1 (2026-07-10)

1. Badge de versão 1.22.7 + JSON-LD `softwareVersion`
2. Skip link e `:focus-visible` (a11y)
3. Recursos “Resumo do dia” e “Modo reunião / piscada”
4. FAQ DVRS + novidades 1.22 (HTML + schema)
5. Sitemap `lastmod` + smoke de sync com `pubspec.yaml`

### Workflows round 1 (2026-07-10)

1. Workflow unificado `CI`
2. Dependabot (Actions + pub)
3. Smoke agendado da landing
4. Template de issue de roadmap
5. `docs/ROADMAP.md` + contratos de projeto

### Landing round 2 (2026-07-10)

1. `site.webmanifest` + apple-touch-icon + preload CSS
2. SEO: `og:locale`, hreflang, meta robots
3. Faixa “Novidades 1.22” no hero + CSS
4. FAQ #7 instalação macOS/Windows + schema FAQPage
5. Nav Recursos/FAQ, footer Roadmap, smoke de assets críticos

### Workflows round 2 (2026-07-10)

1. PR template com checklist de qualidade
2. Labeler por path (`site` / `flutter` / `ci` / `docs`)
3. Stale hygiene semanal
4. Changelog guard em bump de versão
5. CI summary job + `docs/IMPROVEMENT-AUTOMATION.md`

## Como contribuir com o roadmap

Abra uma issue com o template **Item de roadmap** ou envie PR atualizando esta tabela com evidência (teste, Lighthouse, screenshot).
