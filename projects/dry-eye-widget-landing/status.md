# Status

Updated: 2026-06-19

Current phase: priority fixes applied and verified for the static `/app/` landing.

Completed:

- Repository inspected.
- README, release links, authorship, and existing visual assets identified.
- Local operating summary, implementation contract, capability matrix, queues, and milestones created.
- Static landing maintained in `site/`.
- Single `/app/` landing route, language toggle, blog, SEO metadata, sitemap, robots, downloads, GitHub link, references and footer created.
- Local verification passed: check, build, smoke, production audit and Lighthouse.
- Professional photo of Dr. Philipe added to the medical authority card and article byline.
- Real app screenshots added to the carousel for floating widget, menu, break timer, settings, guidance and OSDI.

In progress:

- Priority fixes completed: JS safety, FAQ i18n coverage, legal docs, static smoke test, Pages smoke gate, and release workflow guardrails.
- Verification passed on 2026-06-19: `node site/scripts/smoke-check.mjs`, Flutter analysis, and Flutter tests.

Risks:

- Windows-specific screenshots are still useful for final launch polish.
- Production deployment and DNS require external credentials if moving away from GitHub Pages.
