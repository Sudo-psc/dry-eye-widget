import { readFileSync, readdirSync, statSync } from "node:fs";
import { join, relative } from "node:path";

const root = new URL("..", import.meta.url).pathname;
const repoRoot = new URL("../..", import.meta.url).pathname;
const failures = [];

function walk(dir, predicate, out = []) {
  for (const name of readdirSync(dir)) {
    const path = join(dir, name);
    const stat = statSync(path);
    if (stat.isDirectory()) walk(path, predicate, out);
    else if (predicate(path)) out.push(path);
  }
  return out;
}

function read(path) {
  return readFileSync(path, "utf8");
}

function fail(message) {
  failures.push(message);
}

function extractKeys(block) {
  return new Set([...block.matchAll(/"([^"]+)":\s*"/g)].map((m) => m[1]));
}

const i18n = read(join(root, "scripts", "i18n.js"));
const ptBlock = i18n.match(/pt:\s*\{([\s\S]*?)\n\s*\},\n\s*en:\s*\{/);
const enBlock = i18n.match(/en:\s*\{([\s\S]*?)\n\s*\}\n\s*\};/);
if (!ptBlock || !enBlock) {
  fail("Could not parse PT/EN dictionaries in site/scripts/i18n.js.");
}

const ptKeys = ptBlock ? extractKeys(ptBlock[1]) : new Set();
const enKeys = enBlock ? extractKeys(enBlock[1]) : new Set();

for (const path of walk(root, (p) => p.endsWith(".html"))) {
  const rel = relative(root, path);
  const html = read(path);

  for (const match of html.matchAll(/data-i18n="([^"]+)"/g)) {
    const key = match[1];
    if (!ptKeys.has(key)) fail(`${rel}: missing PT i18n key ${key}`);
    if (!enKeys.has(key)) fail(`${rel}: missing EN i18n key ${key}`);
  }

  const i18nIndex = html.indexOf("scripts/i18n.js");
  const landingIndex = html.indexOf("scripts/landing.js");
  if (i18nIndex !== -1 && landingIndex !== -1 && i18nIndex > landingIndex) {
    fail(`${rel}: i18n.js must load before landing.js.`);
  }
}

const landingJs = read(join(root, "scripts", "landing.js"));
if (!landingJs.includes('typeof window.dewInitLang === "function"')) {
  fail("landing.js must guard dewInitLang so article pages without i18n do not break.");
}
if (!landingJs.includes('typeof window.dewSetLang === "function"')) {
  fail("landing.js must guard dewSetLang so article pages without i18n do not break.");
}

const indexHtml = read(join(root, "index.html"));
if (
  !indexHtml.includes(
    'rel="canonical" href="https://sudo-psc.github.io/dry-eye-widget/"',
  )
) {
  fail(
    "site/index.html must keep sudo-psc.github.io/dry-eye-widget/ as the canonical landing URL.",
  );
}

const sitemap = read(join(root, "sitemap.xml"));
if (/\/app\/(?:pt|en)(?:\/|<)/.test(sitemap)) {
  fail("site/sitemap.xml must not publish /app/pt or /app/en as official landing routes.");
}

const activeContractFiles = [
  ".agent/operating-summary.md",
  "site/README.md",
  "projects/dry-eye-widget-landing/project.md",
  "projects/dry-eye-widget-landing/plan.md",
  "projects/dry-eye-widget-landing/status.md",
  "projects/dry-eye-widget-landing/tasks.md",
  "projects/dry-eye-widget-landing/handoff.md",
  "projects/dry-eye-widget-landing/implementation-contract.md",
  "projects/dry-eye-widget-landing/decisions.md",
  "projects/dry-eye-widget-landing/deployment-plan.md",
  "projects/dry-eye-widget-landing/evals/landing-smoke-test.md",
];
for (const file of activeContractFiles) {
  const body = read(join(repoRoot, file));
  if (/\/app\/(?:pt|en)\b|app\/(?:pt|en)\b|(?:^|[` "'(])landing\//m.test(body)) {
    fail(`${file}: active landing contract still references obsolete landing/ or /app/pt|/app/en.`);
  }
}

if (failures.length) {
  console.error(failures.join("\n"));
  process.exit(1);
}

console.log("site smoke check passed");
