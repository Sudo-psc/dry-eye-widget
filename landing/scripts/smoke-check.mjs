import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

const dist = new URL('../dist/', import.meta.url).pathname;

const requiredFiles = [
  'app/pt/index.html',
  'app/en/index.html',
  'app/pt/blog/index.html',
  'app/en/blog/index.html',
  'app/pt/blog/regra-20-20-20/index.html',
  'app/pt/blog/olho-seco-telas/index.html',
  'app/en/blog/20-20-20-rule/index.html',
  'app/en/blog/dry-eye-screens/index.html',
  'sitemap.xml',
  'robots.txt'
];

const requiredSnippets = [
  ['app/pt/index.html', 'olhossecos.com.br/app/pt/'],
  ['app/pt/index.html', 'Dry Eye Widget'],
  ['app/pt/index.html', 'Baixar para macOS'],
  ['app/pt/index.html', 'Baixar para Windows'],
  ['app/pt/index.html', 'github.com/Sudo-psc/dry-eye-widget'],
  ['app/en/index.html', 'olhossecos.com.br/app/en/'],
  ['app/en/index.html', 'Download for macOS'],
  ['app/en/index.html', 'Download for Windows'],
  ['app/en/index.html', 'Scientific references']
];

const failures = [];

for (const file of requiredFiles) {
  if (!existsSync(join(dist, file))) {
    failures.push(`Missing ${file}`);
  }
}

for (const [file, snippet] of requiredSnippets) {
  const path = join(dist, file);
  if (!existsSync(path)) continue;
  const html = readFileSync(path, 'utf8');
  if (!html.includes(snippet)) {
    failures.push(`Missing snippet "${snippet}" in ${file}`);
  }
}

if (failures.length) {
  console.error(failures.join('\n'));
  process.exit(1);
}

console.log('Smoke check passed: routes, CTAs, SEO canonicals and references are present.');

