# Operating Summary

## Default Architecture

- Local-first harness-wrapper mode around the current Codex runtime.
- Project files are the durable state surface.
- The landing page is an Astro static site under `landing/`, separate from the Flutter app.
- Canonical control objects live in `projects/dry-eye-widget-landing/`.

## First Milestone

Prove a closed loop for the landing page:

goal -> task graph -> implementation -> Astro build -> browser/performance check -> evidence log -> learning/update.

## Key Guardrails

- Do not mutate unrelated Flutter app behavior while building the landing page.
- Keep downloads, GitHub links, medical authorship, legal disclaimer, and references visible.
- Maintain bilingual routes at `/app/pt` and `/app/en`.
- Optimize for static HTML, small CSS, minimal JavaScript, and high Core Web Vitals.
- Medical content must be educational and must not claim diagnosis or treatment.

## Runtime Constraints

- Runtime: Codex desktop coding agent with shell, filesystem, git, tool calling, and local browser/testing options.
- Repository: Flutter desktop app already exists.
- Web framework target: Astro.
- Deployment, DNS, VPS, and remote GitHub repo creation are out of local control until credentials/access details are provided.

