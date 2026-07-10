# Operating Summary

## Default Architecture

- Local-first harness-wrapper mode around the current Codex runtime.
- Project files are the durable state surface.
- The official landing output is static under `site/`, separate from the Flutter app.
- The main `/app/` page is authored as plain HTML/CSS/JS; `/app/science/` is authored in `web/science/` with React/TypeScript/Tailwind and prerendered into `site/science/`.
- Canonical control objects live in `projects/dry-eye-widget-landing/`.

## First Milestone

Prove a closed loop for the landing page:

goal -> task graph -> implementation -> static smoke check -> browser/performance check -> evidence log -> learning/update.

## Key Guardrails

- Do not mutate unrelated Flutter app behavior while building the landing page.
- Keep downloads, GitHub links, medical authorship, legal disclaimer, and references visible.
- Maintain `/app/` as the canonical product route, with PT/EN handled by the client-side language toggle; `/app/science/` is the canonical English scientific subpage.
- Optimize for static HTML, small CSS, minimal JavaScript, and high Core Web Vitals.
- Medical content must be educational and must not claim diagnosis or treatment.

## Runtime Constraints

- Runtime: Codex desktop coding agent with shell, filesystem, git, tool calling, and local browser/testing options.
- Repository: Flutter desktop app already exists.
- Web target: static deploy artifact in `site/`, including the prerendered Science build, deployed by GitHub Pages.
- Deployment, DNS, VPS, and remote GitHub repo creation are out of local control until credentials/access details are provided.
