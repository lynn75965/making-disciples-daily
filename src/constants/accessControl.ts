// src/constants/accessControl.ts
// Making Disciples Daily -- SSOT: Access Control / Roles
//
// Owns the VALUES of the `role` enum (type imported from contracts.ts) and the
// access-control matrix. RLS policies reference these frontend values; they are
// never read from a config table (Architecture Principle #2).
//
// RULE #18: roles live in their own DB table (user_roles) powered by a
// has_role() SECURITY DEFINER function -- never a role column on profiles or
// org_members. That is enforced at the DB layer in Phase 1.
//
// STUB STATE (Phase 0): empty until Phase 1 defines the role set.

import type { Role } from './contracts';

export const ROLES: readonly Role[] = [];
