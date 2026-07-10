# Automação de melhorias — Dry Eye Widget

Atualizado: 2026-07-10

Este documento descreve o que roda sozinho no GitHub e como alimentar o roadmap.

## Pipelines

| Workflow | Quando | Função |
|----------|--------|--------|
| `CI` | push/PR em `main` | Flutter analyze/test + smoke da landing + sync de versão + summary |
| `Deploy Pages (site)` | push em `site/**` | Smoke + deploy GitHub Pages |
| `site-scheduled-smoke` | semanal | Smoke da landing sem deploy |
| `Changelog guard` | PR que toca versão | Exige menção no `CHANGELOG.md` quando sobe `x.y.z` |
| `Label PR paths` | PR | Labels `site` / `flutter` / `ci` / `docs` |
| `Stale hygiene` | semanal | Marca/fecha issues e PRs inativos |
| `Dependabot` | semanal (seg) | PRs de Actions e `pub` |
| Builds macOS / Windows / MSIX | tags `v*` | Artefatos de release |

## Roadmap

1. Prioridades vivas em `docs/ROADMAP.md` (Now / Next / Later).
2. Captura estruturada: issue template **Item de roadmap**.
3. Tracking de progresso: issue #43 + página Notion do projeto.

## Como sugerir uma melhoria

1. Abra issue com o template de roadmap (impacto + esforço).
2. Ou envie PR com o `PULL_REQUEST_TEMPLATE` preenchido.
3. Se for landing: rode `node site/scripts/smoke-check.mjs` antes do push.
4. Se for app: `flutter analyze` + `flutter test`.

## Próximas automações (candidatas)

- Code signing macOS/Windows no pipeline de release
- Lighthouse CI pós-deploy (Pages)
- Screenshot Windows na landing via job dedicado
- SBOM / dependency review em PRs de Dependabot
