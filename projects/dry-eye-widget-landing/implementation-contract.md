# Implementation Contract

## Mission

Ship a lightweight, bilingual static landing page that gives Dry Eye Widget credible medical authority, clear downloads, open-source transparency, and enough supporting evidence for a V1 launch.

## Constraints

- Use `olhossecos.com.br/app/` as the single canonical public landing URL.
- Keep site lightweight and Core Web Vitals friendly.
- Use existing GitHub release assets for download links.
- Use existing README scientific framing as the source of truth.
- Preserve professional authorship: Dr. Philipe Saraiva Cruz, ophthalmologist, CRM-MG 69.870, CRM-SP 204.923, RQE 71.903.

## Proof-of-Progress Metrics

- Static site smoke check passes.
- Bilingual language toggle works on the single landing route.
- Blog routes render.
- SEO tags and canonical URLs exist.
- Download links and GitHub link are present.
- Evidence from local checks is recorded.

## Verification Strategy

- Static smoke test: `node site/scripts/smoke-check.mjs`.
- HTML contract checks for `/app/`, blog pages, script safety, and i18n key coverage.
- Local Lighthouse or equivalent performance smoke test when feasible.
