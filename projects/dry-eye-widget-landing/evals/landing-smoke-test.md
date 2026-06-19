# Landing Smoke Test

The V1 smoke test lives at:

- `site/scripts/smoke-check.mjs`

It verifies:

- `/app/` remains the single canonical landing URL
- `data-i18n` keys used by HTML exist in both PT and EN dictionaries
- `i18n.js` loads before `landing.js` when both are present
- `landing.js` safely handles article pages that do not load i18n
- active project contract files do not point back to obsolete route or build paths

Run:

`node site/scripts/smoke-check.mjs`

This is the first eval ratchet for the landing page. Future improvements should add:

- link integrity checks
- Lighthouse budget thresholds
- screenshot regression for desktop and mobile
- real download availability checks
