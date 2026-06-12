import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'node:path';

// Making Disciples Daily -- Vite config (Path A: plain React 18 SPA, no SSR).
// Netlify builds from this. Do not add SSR or alternate hosts.
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    port: 5173,
  },
});
