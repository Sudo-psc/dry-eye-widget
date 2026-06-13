# Auditoria de limpeza do repositorio

Data: 2026-06-10

Escopo: sugerir arquivos e diretorios obsoletos ou gerados que podem ser removidos. Nenhuma delecao foi executada.

## Evidencias usadas

- `git status --short`: sem alteracoes rastreadas pendentes.
- `git status --short --ignored`: encontrou caches e artefatos ignorados.
- `du -sh`: `build/` ocupa 2.1 GB; `landing/node_modules/` 182 MB; `landing_page/node_modules/` 154 MB; `.dart_tool/` 210 MB; `dist/` 24 MB.
- `AGENTS.md` e arquivos de estado indicam que a landing atual vive em `landing/`.
- `.github/workflows/pages.yml` ainda publica `site/`, que parece ser uma landing estatica antiga.

## Pode deletar agora, com baixo risco

Arquivos e diretorios ignorados pelo Git, gerados localmente:

- `build/`
- `dist/`
- `.dart_tool/`
- `.idea/`
- `.DS_Store`
- `.flutter-plugins-dependencies`
- `dry_eye_widget.iml`
- `landing/node_modules/`
- `landing/.astro/`
- `landing/dist/`
- `landing_page/node_modules/`
- `landing_page/.astro/`
- `landing_page/dist/`
- `macos/Pods/`
- `macos/Flutter/ephemeral/`
- `windows/flutter/ephemeral/`
- `.omc/`
- `.claude/`
- `projects/dry-eye-widget-landing/.omc/`

Observacao: `dist/DryEyeWidget.dmg` e um binario de distribuicao gerado localmente. O proprio projeto ja ignora `dist/`, entao deve ser recriado pelo script quando necessario.

## Candidatos obsoletos rastreados

### `site/`

Risco: medio.

Motivo: e uma landing estatica antiga, enquanto o estado atual do projeto e o `AGENTS.md` apontam para `landing/` como a landing vigente. Os assets e codigo de `site/` nao sao iguais aos de `landing/public/assets`, e o site atual ja tem Astro, rotas bilingues, blog e smoke test.

Antes de deletar:

- Atualizar ou remover `.github/workflows/pages.yml`, pois ele ainda publica `site/`.
- Confirmar se GitHub Pages antigo ainda e usado em `https://sudo-psc.github.io/dry-eye-widget/`.

Arquivos envolvidos:

- `site/README.md`
- `site/index.html`
- `site/scripts/i18n.js`
- `site/scripts/landing.js`
- `site/styles/landing.css`
- `site/styles/widget-screens.css`
- `site/assets/**`

### `landing_page/`

Risco: baixo a medio.

Motivo: e outro projeto Astro antigo com React/Tailwind, enquanto `landing/` e o projeto Astro atual, mais leve, com verificacao e artefatos registrados. Nao encontrei referencias operacionais atuais apontando para `landing_page/`.

Antes de deletar:

- Confirmar que nenhum deploy externo aponta para `landing_page/dist`.
- Se houver interesse historico, preservar em uma tag ou branch antes de remover.

Arquivos envolvidos:

- `landing_page/package.json`
- `landing_page/package-lock.json`
- `landing_page/astro.config.mjs`
- `landing_page/tsconfig.json`
- `landing_page/src/**`
- `landing_page/public/**`
- `landing_page/.vscode/**`

## Candidatos a consolidacao, nao deletar sem ajuste

### Stubs legais antigos

- `docs/PRIVACIDADE.md`: contem apenas titulo e `(Pendente / Draft)`.
- `docs/TERMOS.md`: contem apenas titulo e `(Pendente / Draft)`.
- `docs/TERMS.md`: contem apenas titulo e `(Pendente / Draft)`.

Risco: medio, porque `README.en.md` ainda aponta para `docs/TERMS.md` e `docs/PRIVACY.md`, enquanto `README.md` aponta para `docs/legal/termos-de-uso.md` e `docs/legal/politica-de-privacidade.md`.

Sugestao:

- Remover os stubs depois de corrigir links.
- Para ingles, decidir entre manter `docs/PRIVACY.md` e criar termos em ingles completos, ou apontar explicitamente para documentos PT enquanto a traducao nao existe.

### `banner.png`, `banner_v2.png`, `icon.png`

Risco: medio.

Motivo: os assets atuais da landing foram otimizados para `landing/public/assets/`, mas os arquivos raiz ainda podem ser fontes originais ou usados em README/release.

Sugestao: manter por enquanto ou mover para `assets/source/` se forem fontes mestres.

## Ordem recomendada

1. Apagar caches e artefatos ignorados listados em "Pode deletar agora".
2. Decidir o destino de GitHub Pages e atualizar `.github/workflows/pages.yml`.
3. Remover `site/` se o deploy antigo for encerrado.
4. Remover `landing_page/` se nao houver deploy externo dependendo dele.
5. Consolidar documentos legais e corrigir links dos READMEs.

