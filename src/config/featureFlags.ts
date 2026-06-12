// src/config/featureFlags.ts
// Making Disciples Daily -- SSOT: Feature Flags
//
// Single source for build-time feature toggles. The v1 exclusions (locked
// decision #4) are encoded as OFF flags so any code path that would touch an
// excluded capability can guard against it from commit one.

export const FEATURE_FLAGS = {
  aiGeneration: false,    // v1 excludes AI generation
  payments: false,        // v1 excludes payments/billing (Stripe deferred)
  emailSmsPush: false,    // v1 is in-app notifications only
  publicBibleApi: false,  // v1 is manual paste only
} as const;

export type FeatureFlag = keyof typeof FEATURE_FLAGS;
