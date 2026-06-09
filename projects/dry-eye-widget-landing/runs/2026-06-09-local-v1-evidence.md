# Local V1 Evidence

Date: 2026-06-09

## Build

- `npm run check`: passed with 0 errors, 0 warnings, 0 hints.
- `npm run build`: passed, 9 static pages generated.
- `npm run smoke`: passed.
- `npm audit --omit=dev`: 0 vulnerabilities.

## Routes Generated

- `/app/pt/`
- `/app/en/`
- `/app/pt/blog/`
- `/app/en/blog/`
- `/app/pt/blog/regra-20-20-20/`
- `/app/pt/blog/olho-seco-telas/`
- `/app/en/blog/20-20-20-rule/`
- `/app/en/blog/dry-eye-screens/`

## Package Size

- `dist`: 468 KB.
- `dist/assets`: 376 KB.
- Portuguese landing HTML: 16 KB.
- English landing HTML: 16 KB.

## Lighthouse Local

Report: `projects/dry-eye-widget-landing/runs/lighthouse-pt.json`

- Performance: 99
- Accessibility: 100
- Best practices: 100
- SEO: 100
- LCP: 1.9 s
- CLS: 0
- TBT: 0 ms

## Browser Evidence

- Desktop screenshot: `projects/dry-eye-widget-landing/runs/dry-eye-landing-pt-desktop.png`
- Mobile screenshot: `projects/dry-eye-widget-landing/runs/dry-eye-landing-mobile.png`
- Medical author photo screenshot: `projects/dry-eye-widget-landing/runs/dry-eye-dr-philipe-photo.png`
- Real app screenshots carousel: `projects/dry-eye-widget-landing/runs/dry-eye-real-screenshots-carousel.png`

## Learning

The original hero banner contained text that visually competed with the landing H1. The fix was to keep the image as context while using a stronger responsive mask and lower mobile image opacity. This should become a design guardrail for future hero assets: do not place marketing text inside background images that sit behind live page headings.
