// src/constants/prayerVisibility.ts
// Making Disciples Daily -- SSOT: Prayer Visibility
//
// OWNS the `visibility` enum: PRAYER_VISIBILITY_OPTIONS is the single literal
// source and the Visibility type is DERIVED from it; contracts.ts re-exports
// Visibility as the import surface. Covers prayer requests and messages
// (private / group / org), plus the structural child-safety rule.
//
// ARCHITECTURE PRINCIPLE #4 (care for people): adult-to-minor discipling
// relationships are admin/guardian visible by DEFAULT -- never a private
// adult-minor channel. This default is locked and encoded from commit one; the
// RLS policies in Phase 1 must enforce it. When in doubt, default to MORE
// oversight, not less.
//
// PHASE 1 visibility values (mirror the public.visibility Postgres enum exactly):
//   private -- author-only by default...
//   group   -- visible to members of the linked group
//   org     -- visible to the linked organization
//
// IMPORTANT: 'private' is the author's intent, NOT an oversight bypass. The RLS
// policies on prayer_requests / journal_entries / relationships override
// 'private' for adult-minor contexts so an org admin (and a linked guardian)
// can always see them (ADULT_MINOR_REQUIRES_OVERSIGHT below, Principle #4).

export const PRAYER_VISIBILITY_OPTIONS = [
  'private',
  'group',
  'org',
] as const;

export type Visibility = (typeof PRAYER_VISIBILITY_OPTIONS)[number];

// Locked safety default (Principle #4). Do not weaken without Lynn's review.
export const ADULT_MINOR_REQUIRES_OVERSIGHT = true as const;
