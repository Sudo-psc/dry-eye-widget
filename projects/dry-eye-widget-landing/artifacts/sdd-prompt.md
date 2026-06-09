# SDD Prompt - Dry Eye Widget Landing

Use this prompt for future design/development iterations:

Build a professional, bilingual Astro landing page for Dry Eye Widget, a free open-source desktop app for macOS and Windows created by Dr. Philipe Saraiva Cruz, ophthalmologist. The site must serve `/app/pt` and `/app/en` on `olhossecos.com.br`, with a modern Liquid Glass visual style, high PageSpeed/Core Web Vitals, light and dark mode, strong medical credibility, clear GitHub transparency, direct download CTAs, screenshots carousel, scientific references, and blog authored by the doctor.

Requirements:

- Static Astro site with minimal JavaScript.
- Header with GitHub icon, blog link, language switch and theme toggle.
- Hero with app identity, clinical motivation, 20-20-20 value proposition and professional authorship above the fold.
- Download section below the fold with very clear macOS and Windows buttons.
- Bilingual content in Portuguese and English.
- Blog index and authored articles accessible from the header.
- Scientific references at the end of the landing page and in relevant articles.
- Footer crediting Dr. Philipe Saraiva Cruz.
- SEO: canonical URLs, hreflang, Open Graph, Twitter card, structured data, sitemap, robots.
- Performance: no external font dependency, no third-party script, optimized images, CSS-first animation, accessible contrast.
- Medical safety: educational/prophylactic support only, not diagnosis or treatment.

Verification:

- `npm run build`
- route smoke check for `/app/pt`, `/app/en`, blog pages and article pages
- local browser inspection
- Lighthouse/PageSpeed after deployment

