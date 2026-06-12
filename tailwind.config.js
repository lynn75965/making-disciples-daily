// Tailwind config (ESM -- package.json has "type": "module").
// Making Disciples Daily -- v1 uses Tailwind defaults; brand tokens are sourced
// from src/config/branding.ts as the SSOT, not duplicated here.
/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {},
  },
  plugins: [],
};
