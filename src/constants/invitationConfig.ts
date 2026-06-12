// src/constants/invitationConfig.ts
// Making Disciples Daily -- SSOT: Invitation Config
//
// Owns invite-token rules (expiry, length) for the admin-invite-only org model.
// A new signup defaults to solo discipler; joining an org requires an invite
// token issued by an org admin. The invite-email edge function (Phase 1) reads
// these values.
//
// STUB STATE (Phase 0): empty until Phase 1 builds the invitation flow.

export const INVITATION_CONFIG = {} as const;
