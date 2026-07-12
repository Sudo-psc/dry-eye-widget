# Dry Eye Widget — Landing (`site/`)

Landing com artefato estático servida em **[olhossecos.com.br/app/](https://olhossecos.com.br/app/)** e espelhada no GitHub Pages do repositório. A página principal continua em HTML/CSS/JS sem bundler; a subpágina Science é pré-renderizada a partir de React/TypeScript.

Alinhada ao app **1.24.2** e ao README raiz do projeto.

| | |
|---|---|
| **URL canônica** | `https://olhossecos.com.br/app/` |
| **Código** | pasta `site/` neste monorepo (`Sudo-psc/dry-eye-widget`) |
| **Deploy** | workflow `Deploy Pages (site)` em push de `site/**` ou `web/science/**` |
| **Produto** | [README do app](../README.md) · [Releases](https://github.com/Sudo-psc/dry-eye-widget/releases) |

---

## O que a página cobre

- Hero com download **macOS (.dmg)**, **Microsoft Store** e links Windows (.exe / .zip)
- Badge de versão (`#app-version`) + JSON-LD `softwareVersion` (devem bater com `pubspec.yaml`)
- Recursos 1.22: resumo do dia, DVRS, PDF, meia-lua, piscada, modo reunião
- Carrossel de capturas com filtro **Todas / macOS / Windows**
- FAQ (incl. instalação Gatekeeper/SmartScreen) + schema FAQPage
- Autoria médica, evidências, blog bilíngue, dark/light, PT/EN
- Subpágina científica em `/app/science/` com OVPP, livro, mecanismos, monitoramento longitudinal e referências DOI

**Compliance:** linguagem educativa — triagem/prevenção, **sem diagnóstico** nem promessa de cura.

---

## Estrutura

```
site/
├── index.html              # Landing principal
├── science/                # Build estático e pré-renderizado da página Science
├── site.webmanifest        # PWA-lite / ícone
├── robots.txt
├── sitemap.xml
├── assets/                 # ícones, OG, vídeo, shots (macOS + windows-*.jpg)
├── blog/                   # artigos PT + blog/en/
├── styles/
│   ├── landing.css
│   ├── widget-screens.css  # carrossel + filtro de plataforma
│   └── blog.css
├── scripts/
│   ├── i18n.js             # dicionários PT/EN
│   ├── landing.js          # tema, carrossel, reveal
│   ├── smoke-check.mjs     # CI / pré-deploy
│   └── lighthouse-prod.mjs # Lighthouse produção (opcional)
└── README.md               # este arquivo
```

Fonte da página Science:

```
web/science/
├── src/                    # React + TypeScript + Tailwind + Framer + Lucide
├── public/                 # favicon + social preview 1200×630
├── scripts/prerender.mjs   # SSR -> HTML estático em site/science/
├── package.json
└── vite.config.ts
```

---

## Verificar localmente

Na raiz do repositório:

```bash
npm ci --prefix web/science
npm run build --prefix web/science
node site/scripts/smoke-check.mjs
```

O smoke confere, entre outros:

- chaves i18n PT/EN usadas no HTML
- canonical `olhossecos.com.br/app/`
- versão `pubspec` = badge `#app-version` = JSON-LD `softwareVersion`
- assets críticos (ícone, OG, doctor, shots Windows, manifest)
- prerender Science, MedicalWebPage, DOI mínimo, assets relativos, social preview e orçamento JS
- `robots.txt` e link do manifest

Preview estático (qualquer servidor local na pasta `site/`):

```bash
cd site && python3 -m http.server 8080
# http://localhost:8080/
```

Lighthouse (produção / Pages), opcional:

```bash
node site/scripts/lighthouse-prod.mjs https://sudo-psc.github.io/dry-eye-widget/
# ou
node site/scripts/lighthouse-prod.mjs https://olhossecos.com.br/app/
```

Resumo recente: [`docs/lighthouse/LATEST.md`](../docs/lighthouse/LATEST.md).

---

## Deploy

1. Commit em `main` alterando `site/**`, `web/science/**` ou o workflow Pages.
2. GitHub Actions: **Deploy Pages (site)** → build Science + smoke + `upload-pages-artifact` + deploy.
3. Produção canônica: reverse-proxy / host apontando `olhossecos.com.br/app/` para o artefato publicado (ou espelho do Pages).

Não use mais o fluxo antigo de repositório separado `dry-eye-widget-landing` como fonte da verdade — a landing vive **neste** repo.

---

## Performance e segurança (já aplicados)

- **Fontes:** só Hanken Grotesk + Roboto Mono (sem famílias não usadas no CSS)  
- **Vídeo:** sem `autoplay`/`source` no HTML — carrega sob demanda (IntersectionObserver)  
- **CSS:** `preload` do critical; `widget-screens.css` não-bloqueante  
- **JS:** `defer` em i18n + landing  
- **CSP** + `referrer-policy` no `<head>`; links externos `noopener noreferrer`  
- Animações em `transform`/`opacity`, `prefers-reduced-motion`  
- Canonical, hreflang, Open Graph, JSON-LD, skip link, manifest  
- Science: HTML pré-renderizado, CSS Tailwind inline, hidratação React/Framer no idle e Lighthouse local 100/100/100/100


---

## Ao subir a versão do app

Atualizar em conjunto:

1. `pubspec.yaml` / `lib/utils/constants.dart`  
2. Badge e `"softwareVersion"` em `site/index.html`  
3. (Opcional) faixa “Novidades” / FAQ se houver features públicas  
4. `node site/scripts/smoke-check.mjs`  
5. `docs/ROADMAP.md` / CHANGELOG se for release  

O job CI **Versão app ↔ landing** falha se (1) e (2) divergirem.

---

## Documentação relacionada

| Doc | Uso |
|-----|-----|
| [README.md](../README.md) | Produto e download |
| [docs/ROADMAP.md](../docs/ROADMAP.md) | Prioridades |
| [docs/QA-WINDOWS.md](../docs/QA-WINDOWS.md) | QA docking / piscada no Windows |
| [docs/CODE_SIGNING.md](../docs/CODE_SIGNING.md) | Assinatura de releases |
| [docs/IMPROVEMENT-AUTOMATION.md](../docs/IMPROVEMENT-AUTOMATION.md) | Workflows |

---

## Licença e autoria

Mesmo projeto open source **MIT**. Conteúdo clínico sob autoria do **Dr. Philipe Saraiva Cruz** (CRM-MG 69.870 · CRM-SP 204.923 · RQE 71.903).
