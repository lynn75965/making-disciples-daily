// src/constants/contracts.ts
// Making Disciples Daily -- SSOT: Types / Interfaces
//
// Authoritative IMPORT SURFACE for the shared TypeScript types and for the eight
// string-union enum types that the MDD Supabase database enums MUST mirror
// EXACTLY (Architecture Principle #2: Frontend Drives Backend).
//
// To keep ONE literal source per enum (no cross-file duplication), the VALUES of
// each enum live in exactly one place and the TYPE is DERIVED from them:
//   - role:       values in accessControl.ts        -> Role re-exported here
//   - visibility: values in prayerVisibility.ts     -> Visibility re-exported here
//   - commitment_status / prayer_status: no domain file in the SSOT map, so
//     their values AND derived types live HERE.
// Consumers import every enum type from this file regardless of where the values
// physically live.
//
// PHASE STATE:
//   Phase 1 (defined now): role, visibility, commitment_status, prayer_status.
//   Phase 2 (still `never`): growth_sign, question_type, apprentice_stage,
//   group_type. A Postgres enum requires >= 1 label, so these get NO database
//   enum until their phase populates them. "Mirror exactly" holds: empty here,
//   absent in SQL.
//
// DB enums that must mirror these exactly:
//   role, growth_sign, question_type, visibility, apprentice_stage,
//   group_type, commitment_status, prayer_status

// --- Phase 1 enum types whose values live in a domain file (re-exported) -----
export type { Role } from './accessControl';
export type { Visibility } from './prayerVisibility';

// --- Phase 1 enum types with no domain file (values owned HERE) --------------
export const COMMITMENT_STATUSES = [
  'open',
  'completed',
  'missed',
  'cancelled',
] as const;
export type CommitmentStatus = (typeof COMMITMENT_STATUSES)[number];

export const PRAYER_STATUSES = [
  'active',
  'answered',
  'archived',
] as const;
export type PrayerStatus = (typeof PRAYER_STATUSES)[number];

// --- Phase 2 enum types (intentionally empty until their phase) --------------
export type GrowthSign = never;       // growthSigns.ts          -- Phase 2
export type QuestionType = never;     // questionTypes.ts        -- Phase 2
export type ApprenticeStage = never;  // apprenticeStages.ts     -- Phase 2
export type GroupType = never;        // (groups)                -- Phase 2

// --- Shared identifier aliases ----------------------------------------------
export type Uuid = string;
export type IsoTimestamp = string;
