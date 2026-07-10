import { readFile, rm, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const projectRoot = resolve(fileURLToPath(new URL("..", import.meta.url)));
const outputHtml = resolve(projectRoot, "../../site/science/index.html");
const serverEntry = resolve(projectRoot, ".ssr/entry-server.js");

const [{ render }, originalTemplate] = await Promise.all([
  import(pathToFileURL(serverEntry).href),
  readFile(outputHtml, "utf8"),
]);

const marker = "<!--app-html-->";
if (!originalTemplate.includes(marker)) {
  throw new Error(`Prerender marker not found in ${outputHtml}`);
}

// Vite's SSR renderer emits root-absolute asset URLs even when the client build
// uses a relative base. Normalize them so the same artifact works both at
// /science/ (GitHub Pages) and /app/science/ (canonical domain).
const appHtml = render().replaceAll('="/assets/', '="./assets/');
if (!appHtml.includes("The Science Behind")) {
  throw new Error("SSR output is missing the expected science-page heading.");
}

let template = originalTemplate;

// The page is fully prerendered, so hydration can wait until the browser has
// painted the document. This keeps React/Framer Motion from competing with the
// critical rendering path while retaining interactive motion and theme state.
const moduleTag = template.match(
  /<script type="module" crossorigin src="([^"]+)"><\/script>/,
);
if (!moduleTag) {
  throw new Error("Client module tag was not found in the Vite output.");
}
const moduleSrc = JSON.stringify(moduleTag[1]);
template = template.replace(
  moduleTag[0],
  `<script>(function(){var src=${moduleSrc};function boot(){var s=document.createElement("script");s.type="module";s.src=src;document.head.appendChild(s)}window.addEventListener("load",function(){if("requestIdleCallback" in window)requestIdleCallback(boot,{timeout:2000});else setTimeout(boot,250)},{once:true})})();</script>`,
);

// Inline the generated Tailwind stylesheet. For this one-page static build it
// removes a render-blocking dependency and is smaller over gzip than a second
// request plus headers. The hashed CSS artifact is removed after inlining.
const styleTag = template.match(
  /<link rel="stylesheet"[^>]*href="([^"]+\.css)"[^>]*>/,
);
if (!styleTag) {
  throw new Error("Generated stylesheet tag was not found in the Vite output.");
}
const cssPath = resolve(dirname(outputHtml), styleTag[1]);
const css = await readFile(cssPath, "utf8");
template = template.replace(styleTag[0], `<style data-science-css>${css}</style>`);

await writeFile(outputHtml, template.replace(marker, appHtml), "utf8");
await rm(cssPath, { force: true });
await rm(resolve(projectRoot, ".ssr"), { recursive: true, force: true });

console.log(`Science page prerendered: ${outputHtml}`);
