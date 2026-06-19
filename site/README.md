# Dry Eye Widget — Landing page

Landing estática (HTML/CSS/JS puro, sem build) para `olhossecos.com.br/app/`.

- **Bilíngue:** PT padrão, toggle PT/EN persistido em `localStorage` e cookie. A rota oficial continua sendo `/app/`.
- **Dark/light mode:** segue o sistema, toggle manual persistido.
- **Sem dependências externas** além do Google Fonts. Sem React, sem framework.

## Publicar (VPS + git)

```bash
cd site
git init && git add -A && git commit -m "feat: landing page Dry Eye Widget v1"
git remote add origin git@github.com:Sudo-psc/dry-eye-widget-landing.git
git branch -M main && git push -u origin main

# No VPS (exemplo nginx):
#   location /app/ { alias /var/www/dry-eye-widget-landing/; try_files $uri $uri/ /app/index.html; }
```

## Verificar

```bash
node site/scripts/smoke-check.mjs
```

## Checklist de performance já aplicado

- CSS/JS mínimos e separados, imagens redimensionadas (≤1000px), `loading="lazy"` no carrossel
- `preconnect` para Google Fonts, `display=swap`
- Animações só em `transform`/`opacity`, gated por `prefers-reduced-motion`
- SEO: canonical, `hreflang` pt-BR/en, Open Graph, JSON-LD (`SoftwareApplication` + `Physician`)

## Pendências sugeridas antes da V1

- Substituir o avatar "PS" pela foto profissional real (`.doctor-avatar`)
- Gerar OG image 1200×630 dedicada
- favicon .ico/multi-size + manifest
