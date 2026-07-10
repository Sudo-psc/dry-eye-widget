# Decisions

## 2026-06-09

- Keep download links on GitHub Releases for open-source transparency and simple update behavior.
- Treat deployment, DNS, and separate GitHub repo creation as post-local-build tasks because they need external access/confirmation.

## 2026-06-19

- Use `site/` as the official static landing implementation inside the existing Flutter repository.
- Use `olhossecos.com.br/app/` as the single canonical landing route.
- Keep PT/EN support as a client-side language toggle instead of separate landing routes.
- Keep GitHub Pages publishing from `site/` as the current deployment path.

## 2026-07-10 — Science page

- Keep the main landing static and isolated; author the more complex Science page in `web/science/` and prerender it into the same `site/` deployment artifact.
- Use relative generated assets so the artifact works at both GitHub Pages `/science/` and the canonical custom-domain `/app/science/`.
- Treat `/app/science/` as an English scientific subpage rather than a second language variant of the main landing.
- Prioritize TFOS DEWS III as current consensus while retaining foundational TFOS DEWS II citations.
- Label OVPP export, biomarkers, AI and multicenter studies as research roadmap items, not current product functionality.
- Inline the generated Tailwind stylesheet and defer React/Framer hydration until idle because the page is already fully prerendered; this preserves interactivity while keeping Lighthouse at 100.
