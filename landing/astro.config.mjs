import { defineConfig } from 'astro/config';

export default defineConfig({
  site: 'https://olhossecos.com.br',
  output: 'static',
  trailingSlash: 'always',
  build: {
    format: 'directory'
  },
  vite: {
    build: {
      cssMinify: true,
      rollupOptions: {
        output: {
          assetFileNames: 'assets/[name].[hash][extname]',
          chunkFileNames: 'assets/[name].[hash].js',
          entryFileNames: 'assets/[name].[hash].js'
        }
      }
    }
  }
});

