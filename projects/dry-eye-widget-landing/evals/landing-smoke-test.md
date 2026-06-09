# Landing Smoke Test

The V1 smoke test lives at:

- `landing/scripts/smoke-check.mjs`

It verifies:

- required static routes exist in `dist/`
- Portuguese and English canonical URLs are present
- macOS and Windows CTAs are present
- GitHub project link is present
- scientific references are present

Run:

```bash
cd landing
npm run build
npm run smoke
```

This is the first eval ratchet for the landing page. Future improvements should add:

- link integrity checks
- Lighthouse budget thresholds
- screenshot regression for desktop and mobile
- real download availability checks

