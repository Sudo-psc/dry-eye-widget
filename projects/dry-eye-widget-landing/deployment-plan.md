# Deployment Plan

## Current Build Output

Static files are generated in:

- `site/`

The tree already contains:

- `index.html`, served publicly at `/app/`
- blog routes
- assets
- `sitemap.xml`
- `robots.txt`

## VPS Deployment Shape

Preferred deployment:

1. Validate locally with `node site/scripts/smoke-check.mjs`.
2. Publish the contents of `site/` through the existing GitHub Pages workflow.
3. Ensure the server serves `site/index.html` at `https://olhossecos.com.br/app/`.
4. Ensure blog files remain available under `https://olhossecos.com.br/app/blog/`.
5. Add compression and cache headers:
   - HTML: short cache.
   - CSS, images, SVG: long cache.
   - gzip or brotli enabled.
6. Run production PageSpeed after DNS and HTTPS are live.

## Blocked Inputs

- VPS host, user, deploy path and auth method.
- Web server type: Nginx, Apache, Caddy or other.
- DNS provider access.
- Decision: keep landing in this app repo or create a separate GitHub repo.
