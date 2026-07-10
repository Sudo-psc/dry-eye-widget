# Science Page Evidence

Date: 2026-07-10

## Delivered

- Canonical scientific page: `https://olhossecos.com.br/app/science/`
- Source: `web/science/`
- Static output: `site/science/`
- Main landing navigation: header and footer link to `science/`
- Stack: React, TypeScript, Tailwind CSS, Framer Motion, Lucide React, Vite SSR prerender
- Scientific sections: relevance, mechanism, longitudinal monitoring, app principles, OVPP, references, related book, research vision and ecosystem
- SEO: canonical, meta description, keywords, Open Graph, Twitter card, MedicalWebPage JSON-LD and breadcrumb schema
- Social preview: `site/science/og-science.png`, 1200×630

## Scientific provenance

The public page exposes 12 DOI-linked records. The core evidence set includes:

- TFOS DEWS III Executive Summary — `10.1016/j.ajo.2025.09.035`
- AAO Dry Eye Syndrome Preferred Practice Pattern — `10.1016/j.ophtha.2023.12.041`
- TFOS DEWS II Definition and Classification — `10.1016/j.jtos.2017.05.008`
- TFOS DEWS II Tear Film Report — `10.1016/j.jtos.2017.03.006`
- Uchino et al., Osaka Study — `10.1016/j.ajo.2013.05.040`
- Courtin et al., VDT meta-analysis — `10.1136/bmjopen-2015-009675`
- Portello et al., blink behavior — `10.1097/OPX.0b013e31828f09a7`
- Nichols et al., work productivity — `10.1167/iovs.16-19419`
- Kawashima et al., Moriguchi Study — `10.1539/joh.14-0243-OA`
- Karakus et al., prolonged reading — `10.1097/OPX.0000000000001303`
- Talens-Estarelles et al., 20-20-20 study — `10.1016/j.clae.2022.101744`
- Ashwini et al., blink-software RCT — `10.4103/ijo.IJO_3405_20`

## Verification

- `npm run build --prefix web/science`: passed
- `node site/scripts/smoke-check.mjs`: passed
- Browser QA at 1440×1000: passed
- Browser QA at 390×844: passed
- Dark-mode toggle changed `data-theme` and accessible label: passed
- Lazy book-cover request resolved to 960 px natural width after scroll: passed
- DOI links present in browser DOM: 12

### Lighthouse mobile

- Performance: 100
- Accessibility: 100
- Best Practices: 100
- SEO: 100
- FCP: 1.3 s
- LCP: 1.3 s
- TBT: 0 ms
- CLS: 0

### Lighthouse desktop

- Performance: 100
- Accessibility: 100
- Best Practices: 100
- SEO: 100
- FCP: 0.4 s
- LCP: 0.6 s
- TBT: 0 ms
- CLS: 0

## Evidence boundaries

- The page does not describe the app as a diagnostic or therapeutic medical device.
- OVPP export, digital biomarkers, AI, multicenter studies and public datasets are labeled as future research directions.
- Production Lighthouse must be repeated after deployment because cache and compression headers are host-dependent.
