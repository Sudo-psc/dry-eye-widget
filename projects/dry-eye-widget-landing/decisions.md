# Decisions

## 2026-06-09

- Use `landing/` as a separate Astro static site inside the existing Flutter repository.
- Generate bilingual routes under `app/pt` and `app/en` so the build output maps directly to the requested URLs.
- Keep download links on GitHub Releases for open-source transparency and simple update behavior.
- Treat deployment, DNS, and separate GitHub repo creation as post-local-build tasks because they need external access/confirmation.

