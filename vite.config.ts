import { defineConfig } from 'vite';
import { fileURLToPath, URL } from 'node:url';

// https://vitejs.dev/config/
export default defineConfig({
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
    },
  },
  build: {
    rollupOptions: {
      input: {
        main: fileURLToPath(new URL('./index.html', import.meta.url)),
        vendre: fileURLToPath(new URL('./vendre.html', import.meta.url)),
        auth: fileURLToPath(new URL('./auth.html', import.meta.url)),
      },
    },
  },
});
