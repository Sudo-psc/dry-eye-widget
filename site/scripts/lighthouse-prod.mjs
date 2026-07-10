#!/usr/bin/env node
/**
 * Lighthouse em produção (mobile + desktop) e grava JSON + resumo Markdown.
 * Uso: node site/scripts/lighthouse-prod.mjs [url]
 * Default: https://olhossecos.com.br/app/
 */
import { spawnSync } from "node:child_process";
import { mkdirSync, writeFileSync, readFileSync, existsSync, readdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { homedir } from "node:os";

const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = join(__dirname, "../..");
const outDir = join(repoRoot, "docs/lighthouse");
const url = process.argv[2] || "https://olhossecos.com.br/app/";
const stamp = new Date().toISOString().slice(0, 10);

mkdirSync(outDir, { recursive: true });

function findChrome() {
  if (process.env.CHROME_PATH && existsSync(process.env.CHROME_PATH)) {
    return process.env.CHROME_PATH;
  }
  const fixed = [
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/opt/homebrew/lib/node_modules/chromium/lib/chromium/chrome-mac/Chromium.app/Contents/MacOS/Chromium",
    "/opt/homebrew/bin/chromium",
  ];
  for (const p of fixed) if (existsSync(p)) return p;
  // Puppeteer "Chrome for Testing" cache (latest folder wins).
  const puppeteerRoot = join(homedir(), ".cache/puppeteer/chrome");
  if (existsSync(puppeteerRoot)) {
    const dirs = readdirSync(puppeteerRoot).sort().reverse();
    for (const d of dirs) {
      const p = join(
        puppeteerRoot,
        d,
        "chrome-mac-arm64/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing",
      );
      if (existsSync(p)) return p;
    }
  }
  return undefined;
}

function runLighthouse(formFactor) {
  const chromePath = findChrome();
  const jsonPath = join(outDir, `${stamp}-${formFactor}.json`);
  const htmlPath = join(outDir, `${stamp}-${formFactor}.html`);
  const args = [
    "lighthouse",
    url,
    "--output=json",
    "--output=html",
    `--output-path=${join(outDir, `${stamp}-${formFactor}`)}`,
    "--quiet",
    "--chrome-flags=--headless --no-sandbox --disable-gpu",
  ];
  if (formFactor === "desktop") {
    args.push("--preset=desktop");
  } else {
    args.push("--form-factor=mobile");
  }
  const env = { ...process.env };
  if (chromePath) env.CHROME_PATH = chromePath;

  console.log(`Running Lighthouse (${formFactor}) → ${url}`);
  const res = spawnSync("npx", ["--yes", ...args], {
    env,
    encoding: "utf8",
    cwd: repoRoot,
    timeout: 180000,
  });
  if (res.status !== 0) {
    console.error(res.stdout || "");
    console.error(res.stderr || "");
    throw new Error(`Lighthouse ${formFactor} failed with code ${res.status}`);
  }
  // lighthouse names files with the output-path prefix
  const producedJson = existsSync(jsonPath)
    ? jsonPath
    : join(outDir, `${stamp}-${formFactor}.report.json`);
  const producedHtml = existsSync(htmlPath)
    ? htmlPath
    : join(outDir, `${stamp}-${formFactor}.report.html`);
  // Normalize names if lighthouse used .report.*
  if (!existsSync(jsonPath) && existsSync(producedJson)) {
    // keep .report.json as-is; read from producedJson
  }
  return { jsonPath: existsSync(jsonPath) ? jsonPath : producedJson, htmlPath: existsSync(htmlPath) ? htmlPath : producedHtml };
}

function scoreOf(report, cat) {
  const c = report.categories?.[cat]?.score;
  return c == null ? null : Math.round(c * 100);
}

function metric(report, id) {
  const a = report.audits?.[id];
  if (!a) return "—";
  return a.displayValue || String(a.numericValue ?? "—");
}

const results = {};
for (const form of ["mobile", "desktop"]) {
  const paths = runLighthouse(form);
  const report = JSON.parse(readFileSync(paths.jsonPath, "utf8"));
  results[form] = {
    paths,
    scores: {
      performance: scoreOf(report, "performance"),
      accessibility: scoreOf(report, "accessibility"),
      bestPractices: scoreOf(report, "best-practices"),
      seo: scoreOf(report, "seo"),
    },
    metrics: {
      fcp: metric(report, "first-contentful-paint"),
      lcp: metric(report, "largest-contentful-paint"),
      cls: metric(report, "cumulative-layout-shift"),
      tbt: metric(report, "total-blocking-time"),
      si: metric(report, "speed-index"),
    },
  };
}

const md = `# Lighthouse — produção

- **URL:** ${url}
- **Data:** ${stamp}
- **Ferramenta:** Lighthouse via npx

## Scores

| Form factor | Performance | Accessibility | Best Practices | SEO |
|-------------|-------------|---------------|----------------|-----|
| Mobile | ${results.mobile.scores.performance} | ${results.mobile.scores.accessibility} | ${results.mobile.scores.bestPractices} | ${results.mobile.scores.seo} |
| Desktop | ${results.desktop.scores.performance} | ${results.desktop.scores.accessibility} | ${results.desktop.scores.bestPractices} | ${results.desktop.scores.seo} |

## Core Web Vitals (mobile)

| Métrica | Valor |
|---------|-------|
| FCP | ${results.mobile.metrics.fcp} |
| LCP | ${results.mobile.metrics.lcp} |
| CLS | ${results.mobile.metrics.cls} |
| TBT | ${results.mobile.metrics.tbt} |
| Speed Index | ${results.mobile.metrics.si} |

## Core Web Vitals (desktop)

| Métrica | Valor |
|---------|-------|
| FCP | ${results.desktop.metrics.fcp} |
| LCP | ${results.desktop.metrics.lcp} |
| CLS | ${results.desktop.metrics.cls} |
| TBT | ${results.desktop.metrics.tbt} |
| Speed Index | ${results.desktop.metrics.si} |

## Artefatos

- Mobile JSON/HTML: \`${results.mobile.paths.jsonPath.replace(repoRoot + "/", "")}\` / \`${results.mobile.paths.htmlPath.replace(repoRoot + "/", "")}\`
- Desktop JSON/HTML: \`${results.desktop.paths.jsonPath.replace(repoRoot + "/", "")}\` / \`${results.desktop.paths.htmlPath.replace(repoRoot + "/", "")}\`

## Notas

- Rodar de novo após deploy Pages: \`node site/scripts/lighthouse-prod.mjs\`
- URL alternativa GitHub Pages: \`node site/scripts/lighthouse-prod.mjs https://sudo-psc.github.io/dry-eye-widget/\`
`;

const summaryPath = join(outDir, `${stamp}-summary.md`);
writeFileSync(summaryPath, md, "utf8");
writeFileSync(join(outDir, "LATEST.md"), md, "utf8");
console.log(md);
console.log(`Wrote ${summaryPath}`);
