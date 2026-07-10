import { readFileSync, readdirSync, statSync, existsSync } from "node:fs";
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
    'rel="canonical" href="https://olhossecos.com.br/app/"',
  )
) {
  fail(
    "site/index.html must keep olhossecos.com.br/app/ as the canonical landing URL.",
  );
}

const sitemap = read(join(root, "sitemap.xml"));
if (/\/app\/(?:pt|en)(?:\/|<)/.test(sitemap)) {
  fail("site/sitemap.xml must not publish /app/pt or /app/en as official landing routes.");
}
if (!sitemap.includes("https://olhossecos.com.br/app/science/")) {
  fail("site/sitemap.xml must publish the canonical /app/science/ route.");
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


// Version on landing must track pubspec (major.minor.patch).
const pubspec = read(join(repoRoot, "pubspec.yaml"));
const pubVer = pubspec.match(/^version:\s*([0-9]+\.[0-9]+\.[0-9]+)/m);
const indexVer = indexHtml.match(/"softwareVersion":\s*"([0-9]+\.[0-9]+\.[0-9]+)"/);
const badgeVer = indexHtml.match(/id="app-version">\s*([0-9]+\.[0-9]+\.[0-9]+)\s*</);
if (!pubVer) fail("pubspec.yaml: missing version line.");
if (!indexVer) fail('site/index.html: missing JSON-LD softwareVersion (x.y.z).');
if (!badgeVer) fail('site/index.html: missing #app-version badge (x.y.z).');
if (pubVer[1] !== indexVer[1] || pubVer[1] !== badgeVer[1]) {
  fail(
    `Version mismatch: pubspec=${pubVer[1]} schema=${indexVer?.[1]} badge=${badgeVer?.[1]}`,
  );
}

// Artefatos críticos da landing (SEO, PWA-lite, robots).
const requiredAssets = [
  "site.webmanifest",
  "robots.txt",
  "sitemap.xml",
  ".well-known/security.txt",
  "assets/icon-256.png",
  "assets/og-hero.jpg",
  "assets/doctor.png",
  "assets/shots/windows-ball-menu.jpg",
  "assets/shots/windows-break-card.jpg",
  "assets/shots/windows-settings.jpg",
  "assets/shots/windows-dashboard.jpg",
  "assets/shots/windows-store-poster.jpg",
  "science/index.html",
  "science/og-science.png",
];
for (const rel of requiredAssets) {
  if (!existsSync(join(root, rel))) {
    fail(`Missing required site asset: ${rel}`);
  }
}

if (!indexHtml.includes('id="shots-platform"') || !indexHtml.includes('data-platform="windows"')) {
  fail("site/index.html must expose Windows screenshot slides and platform filter.");
}

const manifest = read(join(root, "site.webmanifest"));
if (!manifest.includes('"name"') || !manifest.includes("icon-256.png")) {
  fail("site.webmanifest must declare name and icon-256.png.");
}

const robots = read(join(root, "robots.txt"));
if (!robots.includes("Sitemap: https://olhossecos.com.br/app/sitemap.xml")) {
  fail("robots.txt must declare the production sitemap URL.");
}

if (!indexHtml.includes('rel="manifest" href="site.webmanifest"')) {
  fail("site/index.html must link site.webmanifest.");
}
if (!indexHtml.includes('rel="apple-touch-icon"')) {
  fail("site/index.html must declare apple-touch-icon.");
}
if (!indexHtml.includes("og:locale")) {
  fail("site/index.html must declare og:locale for social SEO.");
}
if (!indexHtml.includes('name="referrer"') || !indexHtml.includes("Content-Security-Policy")) {
  fail("site/index.html must declare referrer-policy and Content-Security-Policy.");
}
if (!indexHtml.includes("Permissions-Policy")) {
  fail("site/index.html must declare Permissions-Policy (camera/mic/geo disabled).");
}
const securityTxt = read(join(root, ".well-known/security.txt"));
if (!securityTxt.includes("Contact:") || !securityTxt.includes("SECURITY.md")) {
  fail(".well-known/security.txt must declare Contact and Policy.");
}
// Vídeo não deve puxar 2MB+ no first paint (sem autoplay + sem source estático).
if (/id="demo-video"[\s\S]*?\bautoplay\b/i.test(indexHtml)) {
  fail("demo-video must not use autoplay (perf: defers multi-MB download).");
}
if (/id="demo-video"[\s\S]*?<source\s+src=/i.test(indexHtml)) {
  fail("demo-video must not embed <source src> in HTML; load lazily via JS.");
}
if (
  indexHtml.includes("Schibsted+Grotesk") ||
  indexHtml.includes("family=Sora:")
) {
  fail("Unused Google Font families (Schibsted/Sora) must not be loaded.");
}
if (!indexHtml.includes('name="color-scheme"')) {
  fail("site/index.html must declare color-scheme for light/dark UI.");
}
if (!indexHtml.includes('id="main"') || !indexHtml.includes('href="#main"')) {
  fail("site/index.html must expose <main id=\"main\"> and skip-link to #main.");
}
if (/aggregateRating/i.test(indexHtml)) {
  fail("Do not publish AggregateRating without a verified review corpus.");
}
if (!indexHtml.includes('href="science/"') || !indexHtml.includes('data-i18n="nav.science"')) {
  fail("site/index.html must expose the Science page in the primary navigation.");
}

// Science page: prerendered semantic content, medical SEO and portable assets.
const scienceHtml = read(join(root, "science", "index.html"));
if (!scienceHtml.includes('<h1 id="hero-title">The Science Behind')) {
  fail("site/science/index.html must contain prerendered hero content, not an empty React root.");
}
if (!scienceHtml.includes('rel="canonical" href="https://olhossecos.com.br/app/science/"')) {
  fail("Science page must keep /app/science/ as its canonical URL.");
}
if (!scienceHtml.includes('"@type": "MedicalWebPage"')) {
  fail("Science page must declare MedicalWebPage structured data.");
}
const scienceLdMatch = scienceHtml.match(
  /<script type="application\/ld\+json">([\s\S]*?)<\/script>/,
);
if (!scienceLdMatch) {
  fail("Science page is missing JSON-LD content.");
} else {
  try {
    JSON.parse(scienceLdMatch[1]);
  } catch (error) {
    fail(`Science JSON-LD is invalid: ${error.message}`);
  }
}
for (const marker of ["og:title", "og:description", "og:image", 'name="keywords"']) {
  if (!scienceHtml.includes(marker)) fail(`Science SEO is missing ${marker}.`);
}
if (!scienceHtml.includes("TFOS DEWS III") || !scienceHtml.includes("AAO PPP")) {
  fail("Science page must retain current TFOS DEWS III and AAO guideline references.");
}
const doiLinks = [...scienceHtml.matchAll(/href="https:\/\/doi\.org\//g)].length;
if (doiLinks < 10) {
  fail(`Science page must expose at least 10 DOI links; found ${doiLinks}.`);
}
if (scienceHtml.includes('src="/assets/') || scienceHtml.includes('href="/assets/')) {
  fail("Science prerender must use portable relative asset URLs, not root-absolute /assets paths.");
}
if (/\b(?:diagnoses|prevents|treats) dry eye\b/i.test(scienceHtml)) {
  fail("Science page contains an unqualified diagnosis/prevention/treatment claim.");
}
const scienceBlank = [...scienceHtml.matchAll(/target="_blank"/g)].length;
const scienceSafeBlank = [...scienceHtml.matchAll(/rel="noopener noreferrer"/g)].length;
if (scienceSafeBlank < scienceBlank) {
  fail("Science page external new-tab links must use noopener noreferrer.");
}

const scienceScripts = walk(join(root, "science", "assets"), (p) => p.endsWith(".js"));
for (const path of scienceScripts) {
  if (statSync(path).size > 400_000) {
    fail(`Science JavaScript bundle exceeds 400 KB performance budget: ${relative(root, path)}.`);
  }
}
const socialPng = readFileSync(join(root, "science", "og-science.png"));
if (
  socialPng.toString("ascii", 1, 4) !== "PNG" ||
  socialPng.readUInt32BE(16) !== 1200 ||
  socialPng.readUInt32BE(20) !== 630
) {
  fail("Science social preview must be a 1200x630 PNG.");
}

// Blog: links externos com target=_blank precisam de noreferrer (tabnabbing).
for (const path of walk(root, (p) => p.endsWith(".html"))) {
  const rel = relative(root, path);
  if (!rel.startsWith("blog")) continue;
  const html = read(path);
  const blank = [...html.matchAll(/target="_blank"/g)].length;
  const noref = [...html.matchAll(/rel="noopener noreferrer"/g)].length;
  if (blank > 0 && noref < blank) {
    fail(
      `${rel}: ${blank} target=_blank but only ${noref} rel="noopener noreferrer"`,
    );
  }
  if (html.includes("Schibsted+Grotesk") || html.includes("family=Sora:")) {
    fail(`${rel}: unused Google Font families must not be loaded.`);
  }
}

if (failures.length) {
  console.error(failures.join("\n"));
  process.exit(1);
}

console.log("site smoke check passed");
