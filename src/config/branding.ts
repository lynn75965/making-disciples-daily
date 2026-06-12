// src/config/branding.ts
// Making Disciples Daily -- SSOT: Branding
//
// Single source for brand-facing identity (app name, domain, tagline). Tailwind
// and components read brand values from here -- never duplicate them in CSS or
// markup.

export const BRANDING = {
  appName: 'Making Disciples Daily',
  domain: 'making-disciples-daily.com',
  tagline: 'Equipping disciple-makers for relationships that multiply.',
} as const;
