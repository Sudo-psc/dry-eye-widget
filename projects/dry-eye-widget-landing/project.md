# Dry Eye Widget Landing Page

## Mission

Create a professional bilingual landing page for Dry Eye Widget at:

- `olhossecos.com.br/app/`

The page presents the app, the clinical motivation, download links for Windows and macOS, the open-source GitHub project, screenshots, scientific references, and a blog authored by Dr. Philipe Saraiva Cruz. The official route is a single `/app/` landing, with Portuguese and English handled by the language toggle.

## Runtime Profile

- Local-first development.
- Static HTML/CSS/JS site under `site/`.
- Flutter app repository remains the source for README content, iconography, and release links.
- Build output can be deployed later to the VPS under `/app`.

## First Milestone

Build and verify V1 locally:

- single `/app/` landing with bilingual toggle
- GitHub and download calls to action
- Liquid Glass visual style with light/dark mode
- carousel section
- SEO metadata
- blog index and initial articles
- scientific references
- local build and performance smoke test

## Non-goals For V1

- VPS deployment
- DNS changes
- remote GitHub repository creation
- signed release binaries
- production analytics

## Safety Posture

The page can describe preventive ergonomic guidance and cite evidence. It must not present the app as a diagnostic or curative medical device.
