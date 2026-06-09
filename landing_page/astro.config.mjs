// @ts-check
import { defineConfig } from 'astro/config';

import tailwindcss from '@tailwindcss/vite';
import react from '@astrojs/react';

// https://astro.build/config
export default defineConfig({
  site: 'https://olhossecos.com.br',
  base: '/app',
  i18n: {
    defaultLocale: 'pt',
    locales: ['pt', 'en'],
    routing: {
      prefixDefaultLocale: true,
    }
  },
  vite: {
    plugins: [tailwindcss()]
  },

  integrations: [react()]
});