# Dry Eye Widget Science

Source application for the public scientific foundation page.

## Runtime contract

- Canonical URL: `https://olhossecos.com.br/app/science/`
- Source: `web/science/`
- Deploy artifact: `site/science/`
- Framework: React + TypeScript + Tailwind CSS + Framer Motion + Lucide React
- Rendering: Vite client build plus React server rendering and static prerender

The page is authored as reusable React components but shipped as semantic HTML. The generated Tailwind CSS is inlined and hydration is scheduled after the first paint. This preserves SEO and no-JavaScript readability while keeping theme controls and Framer Motion interactions.

## Commands

From the repository root:

```bash
npm ci --prefix web/science
npm run build --prefix web/science
node site/scripts/smoke-check.mjs
```

Local preview:

```bash
cd site
python3 -m http.server 8080
```

Open `http://127.0.0.1:8080/science/`.

## Structure

- `src/App.tsx`: semantic page composition and scientific copy
- `src/components/`: reusable navigation, cards, diagrams and reveal primitives
- `src/data/references.ts`: curated DOI-backed reference metadata
- `src/styles.css`: Tailwind entrypoint, design tokens and responsive component layers
- `scripts/prerender.mjs`: SSR injection, portable asset normalization and critical-path optimization
- `public/`: social preview and lightweight favicon

## Scientific boundary

The page describes evidence, observation and research direction. It must not present Dry Eye Widget as a diagnostic or therapeutic medical device. OVPP export, biomarkers, AI and multicenter studies remain explicitly labeled as future work until validated and governed.
