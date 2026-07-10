import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  plugins: [react(), tailwindcss()],
  // Relative assets keep the page portable between /science/ on GitHub Pages
  // and the canonical /app/science/ route on olhossecos.com.br.
  base: "./",
  build: {
    outDir: "../../site/science",
    emptyOutDir: true,
    assetsDir: "assets",
    sourcemap: false,
    target: "es2022",
  },
});
