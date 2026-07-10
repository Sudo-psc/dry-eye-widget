# Lighthouse — produção

- **URL:** https://sudo-psc.github.io/dry-eye-widget/
- **Data:** 2026-07-10
- **Ferramenta:** Lighthouse via npx

## Scores

| Form factor | Performance | Accessibility | Best Practices | SEO |
|-------------|-------------|---------------|----------------|-----|
| Mobile | 93 | 90 | 100 | 100 |
| Desktop | 99 | 90 | 100 | 100 |

## Core Web Vitals (mobile)

| Métrica | Valor |
|---------|-------|
| FCP | 1.9 s |
| LCP | 3.0 s |
| CLS | 0.002 |
| TBT | 0 ms |
| Speed Index | 3.1 s |

## Core Web Vitals (desktop)

| Métrica | Valor |
|---------|-------|
| FCP | 0.6 s |
| LCP | 0.9 s |
| CLS | 0.004 |
| TBT | 0 ms |
| Speed Index | 0.6 s |

## Artefatos

- Mobile JSON/HTML: `docs/lighthouse/2026-07-10-mobile.report.json` / `docs/lighthouse/2026-07-10-mobile.report.html`
- Desktop JSON/HTML: `docs/lighthouse/2026-07-10-desktop.report.json` / `docs/lighthouse/2026-07-10-desktop.report.html`

## Notas

- Rodar de novo após deploy Pages: `node site/scripts/lighthouse-prod.mjs`
- URL alternativa GitHub Pages: `node site/scripts/lighthouse-prod.mjs https://sudo-psc.github.io/dry-eye-widget/`
