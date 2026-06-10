# Mídia do README

- `app-demo.gif` / `app-demo.mp4` — simulação animada do app (ciclo → pausa
  20-20-20 com piscar guiado → retomada), usada no topo do README.
- `app-demo.html` — fonte da simulação: render determinístico via
  `window.renderAt(segundos)`.
- `carousel-dark.webp` / `carousel-light.webp` — carrossel animado das **telas
  reais** (WebP animado), nas variantes escura e clara; embutidos via `<picture>`
  com `prefers-color-scheme` (acompanha o tema do GitHub do leitor).
- `carousel-dark.mp4` / `carousel-light.mp4` — mesma animação em vídeo (links).
- `carousel.html` — fonte do carrossel: `window.setTheme('dark'|'light')` +
  `window.renderAt(segundos)` sobre as telas reais de `site/assets/shots/`.

## Regenerar

Captura por headless browser (Playwright) + montagem com ffmpeg:

```bash
# 1) frames determinísticos (24 fps, 2x) a partir de app-demo.html
#    (um script Node chama page.evaluate(renderAt(t)) e screenshota cada frame)
# 2) MP4
ffmpeg -y -framerate 25 -i frames/f_%04d.png \
  -vf "scale=880:-2,format=yuv420p" -c:v libx264 -crf 20 -movflags +faststart app-demo.mp4
# 3) GIF (palette 2-pass)
ffmpeg -y -framerate 25 -i frames/f_%04d.png -vf "fps=14,scale=620:-1:flags=lanczos,palettegen=stats_mode=diff" palette.png
ffmpeg -y -framerate 25 -i frames/f_%04d.png -i palette.png \
  -lavfi "fps=14,scale=620:-1:flags=lanczos[x];[x][1:v]paletteuse" app-demo.gif
```
