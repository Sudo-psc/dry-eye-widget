# Implementation Contract

## Mission

Ship a lightweight, bilingual Astro landing page that gives Dry Eye Widget credible medical authority, clear downloads, open-source transparency, and enough supporting evidence for a V1 launch.

## Constraints

- Use `olhossecos.com.br/app/pt` and `olhossecos.com.br/app/en` as canonical public URLs.
- Keep site lightweight and Core Web Vitals friendly.
- Use existing GitHub release assets for download links.
- Use existing README scientific framing as the source of truth.
- Preserve professional authorship: Dr. Philipe Saraiva Cruz, ophthalmologist, CRM-MG 69.870, CRM-SP 204.923, RQE 71.903.

## Proof-of-Progress Metrics

- Astro build passes.
- Bilingual pages render.
- Blog routes render.
- SEO tags and canonical URLs exist.
- Download links and GitHub link are present.
- Evidence from local checks is recorded.

## Verification Strategy

- Static build: `npm run build` in `landing/`.
- Preview/dev server smoke test.
- HTML route existence checks for `/app/pt`, `/app/en`, and blog pages.
- Local Lighthouse or equivalent performance smoke test when feasible.

