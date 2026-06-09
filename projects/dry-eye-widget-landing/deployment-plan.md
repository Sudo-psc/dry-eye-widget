# Deployment Plan

## Current Build Output

Static files are generated in:

- `landing/dist/`

The generated tree already contains:

- `app/pt/index.html`
- `app/en/index.html`
- blog routes
- assets
- `sitemap.xml`
- `robots.txt`

## VPS Deployment Shape

Preferred deployment:

1. Build locally or in CI with `cd landing && npm ci && npm run build`.
2. Upload the contents of `landing/dist/` to the web root that serves `olhossecos.com.br`.
3. Ensure the server serves `landing/dist/app/pt/index.html` at `https://olhossecos.com.br/app/pt/`.
4. Ensure the server serves `landing/dist/app/en/index.html` at `https://olhossecos.com.br/app/en/`.
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

