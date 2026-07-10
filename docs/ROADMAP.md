# Roadmap — Dry Eye Widget

Atualizado: 2026-07-10 · Versão atual: **1.22.7**

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
| 1 | Assinatura de código macOS/Windows (Gatekeeper/SmartScreen) | Distribuição | Alto | Grande |
| 2 | QA manual Windows: docking meia-lua + micronotificação | App | Alto | Médio |
| 3 | Validação HealthKit em build assinado | App | Médio | Médio |
| 4 | Screenshots Windows na landing | Site | Médio | Quick win |
| 5 | Lighthouse produção pós-deploy | Site | Médio | Quick win |

## Next (1–2 meses)

| # | Item | Área | Notas |
|---|------|------|--------|
| 6 | PDF narrativo para o oftalmologista | App | Bloco 5–8 linhas a partir de dados locais |
| 7 | Unificar Painel + Progresso + Tempo de tela | App | Reduz densidade do menu |
| 8 | i18n ARB (Flutter gen-l10n) | App | Substituir app_strings manual |
| 9 | Fatiar `main.dart` (layouts de janela) | App | Manutenibilidade |
| 10 | Decidir se landing fica neste repo ou repo próprio | Site | Bloqueado por decisão |

## Later

- Insight semanal opt-in (notificação local)
- Light mode completo no widget
- Exportação agregada de métricas locais (opt-in)
- Monitoramento de SPM warnings dos plugins macOS

## Automação CI (implementada 2026-07-10)

- `ci.yml` — Flutter analyze/test + smoke da landing + sync de versão em todo push/PR
- `pages.yml` — deploy GitHub Pages + smoke
- `site-scheduled-smoke.yml` — smoke semanal
- `dependabot.yml` — Actions e pub semanalmente
- `ISSUE_TEMPLATE/roadmap-item.yml` — captura estruturada de ideias

## Ciclos recentes (landing + workflows)

### Landing (5 ciclos)

1. Badge de versão 1.22.7 + JSON-LD `softwareVersion`
2. Skip link e `:focus-visible` (a11y)
3. Recursos “Resumo do dia” e “Modo reunião / piscada”
4. FAQ DVRS + novidades 1.22 (HTML + schema)
5. Sitemap `lastmod` + smoke de sync com `pubspec.yaml`

### Workflows / roadmap (5 ciclos)

1. Workflow unificado `CI`
2. Dependabot (Actions + pub)
3. Smoke agendado da landing
4. Template de issue de roadmap
5. `docs/ROADMAP.md` + contratos de projeto atualizados

## Como contribuir com o roadmap

Abra uma issue com o template **Item de roadmap** ou envie PR atualizando esta tabela com evidência (teste, Lighthouse, screenshot).
