// src/constants/contracts.ts
// Making Disciples Daily -- SSOT: Types / Interfaces
//
// Authoritative home for shared TypeScript types and for the eight string-union
// enum types that the MDD Supabase database enums MUST mirror EXACTLY
// (Architecture Principle #2: Frontend Drives Backend). The VALUES for each
// enum are owned by the matching domain SSOT file (growthSigns.ts,
// questionTypes.ts, apprenticeStages.ts, prayerVisibility.ts, accessControl.ts),
// which import the type from here so there is ONE definition of each.
//
// STUB STATE (Phase 0): the unions are intentionally empty (`never`) until the
// owning domain file is populated in its phase. Nothing is invented here.
//
// DB enums that must mirror these exactly:
//   role, growth_sign, question_type, visibility, apprentice_stage,
//   group_type, commitment_status, prayer_status

// --- DB-mirrored enum types (values added in the noted phase) ---------------
export type Role = never;             // accessControl.ts        -- Phase 1
export type GrowthSign = never;       // growthSigns.ts          -- Phase 2
export type QuestionType = never;     // questionTypes.ts        -- Phase 2
export type Visibility = never;       // prayerVisibility.ts     -- Phase 1
export type ApprenticeStage = never;  // apprenticeStages.ts     -- Phase 2
export type GroupType = never;        // (groups)                -- Phase 2
export type CommitmentStatus = never; // (commitments)           -- Phase 1
export type PrayerStatus = never;     // (prayer requests)       -- Phase 1

// --- Shared identifier aliases ----------------------------------------------
export type Uuid = string;
export type IsoTimestamp = string;
