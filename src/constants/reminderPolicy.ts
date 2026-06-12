// src/constants/reminderPolicy.ts
// Making Disciples Daily -- SSOT: Reminder Policy
//
// Owns the rules the daily reminder generator (pg_cron edge function, Phase 1)
// reads: what triggers a reminder (commitments due, sessions within 24h, prayer
// stale at 14d), and how user timezone + quiet hours are honored. In-app
// notifications only in v1 -- no email/SMS/push.
//
// STUB STATE (Phase 0): empty until Phase 1 wires notifications + the cron.

export const REMINDER_POLICY = {} as const;
