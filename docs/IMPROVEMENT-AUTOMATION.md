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

## Lighthouse em produção

```bash
# GitHub Pages (deploy do site/)
node site/scripts/lighthouse-prod.mjs https://sudo-psc.github.io/dry-eye-widget/

# Domínio canônico (quando o reverse-proxy estiver no artefato mais recente)
node site/scripts/lighthouse-prod.mjs https://olhossecos.com.br/app/
```

Saída em `docs/lighthouse/` (`LATEST.md` + JSON/HTML datados).

## Code signing (condicional)

- Doc mestre: `docs/CODE_SIGNING.md`
- Windows (SignPath): `win_version/CODE_SIGNING.md` + `windows-build.yml`
- macOS: `scripts/macos_import_cert.sh` + `scripts/macos_sign_and_notarize.sh` + `macos-build.yml`
- Sem secrets o build não falha — só publica unsigned

## Próximas automações (candidatas)

- Lighthouse CI agendado (reusa `lighthouse-prod.mjs`)
- Capturas nativas Windows em runner Windows (substituir composite)
- SBOM / dependency review em PRs de Dependabot
- Após secrets Apple: staple + validar em máquina limpa (checklist CODE_SIGNING)
