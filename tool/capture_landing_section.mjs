import { writeFile } from 'node:fs/promises';

const [, , output, width = '1440', height = '1000'] = process.argv;
if (!output) {
  throw new Error('Uso: node tool/capture_landing_section.mjs <saida.png> [largura] [altura]');
}

const targets = await fetch('http://127.0.0.1:9223/json/list').then((response) =>
  response.json(),
);
const page = targets.find((target) => target.type === 'page');
if (!page) throw new Error('Nenhuma página do Chrome disponível na porta 9223.');

const socket = new WebSocket(page.webSocketDebuggerUrl);
await new Promise((resolve, reject) => {
  socket.addEventListener('open', resolve, { once: true });
  socket.addEventListener('error', reject, { once: true });
});

let sequence = 0;
const pending = new Map();
socket.addEventListener('message', ({ data }) => {
  const message = JSON.parse(data);
  if (!message.id) return;
  const handler = pending.get(message.id);
  if (!handler) return;
  pending.delete(message.id);
  if (message.error) handler.reject(new Error(message.error.message));
  else handler.resolve(message.result);
});

function send(method, params = {}) {
  const id = ++sequence;
  socket.send(JSON.stringify({ id, method, params }));
  return new Promise((resolve, reject) => pending.set(id, { resolve, reject }));
}

await send('Page.enable');
await send('Emulation.setDeviceMetricsOverride', {
  width: Number(width),
  height: Number(height),
  deviceScaleFactor: 1,
  mobile: Number(width) <= 600,
});
await send('Page.navigate', { url: 'http://127.0.0.1:8765/site/' });
await new Promise((resolve) => setTimeout(resolve, 2200));
const scrollResult = await send('Runtime.evaluate', {
  expression:
    "(() => { document.documentElement.style.scrollBehavior = 'auto'; const section = document.querySelector('#capturas'); section.scrollIntoView({block:'start'}); window.scrollBy(0, -72); return {scrollY: window.scrollY, top: section.getBoundingClientRect().top}; })()",
  returnByValue: true,
});
if (scrollResult.result.value.scrollY < 100) {
  throw new Error('A seção de capturas não foi posicionada na viewport.');
}
await new Promise((resolve) => setTimeout(resolve, 800));
const { data } = await send('Page.captureScreenshot', {
  format: 'png',
  fromSurface: true,
});
await writeFile(output, Buffer.from(data, 'base64'));
socket.close();
