# Decisions

## 2026-06-09

- Keep download links on GitHub Releases for open-source transparency and simple update behavior.
- Treat deployment, DNS, and separate GitHub repo creation as post-local-build tasks because they need external access/confirmation.

## 2026-06-19

- Use `site/` as the official static landing implementation inside the existing Flutter repository.
- Use `olhossecos.com.br/app/` as the single canonical landing route.
- Keep PT/EN support as a client-side language toggle instead of separate landing routes.
- Keep GitHub Pages publishing from `site/` as the current deployment path.
