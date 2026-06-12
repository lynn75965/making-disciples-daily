// src/constants/apprenticeStages.ts
// Making Disciples Daily -- SSOT: Apprentice Stages
//
// Owns the VALUES of the `apprentice_stage` enum (type imported from
// contracts.ts). Apprentice mode (Watch / Help / Lead checklist + mentor
// sign-off) is data-driven from this list (Phase 2). The DB enum mirrors these
// exactly.
//
// STUB STATE (Phase 0): empty until Phase 2 populates the stages.

import type { ApprenticeStage } from './contracts';

export const APPRENTICE_STAGES: readonly ApprenticeStage[] = [];
