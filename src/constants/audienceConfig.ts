// src/constants/audienceConfig.ts
// Making Disciples Daily -- SSOT: Audience / Role Terms
//
// RULE #13: NEVER hardcode "disciple", "discipler", "apprentice", or
// "group member" as display strings in components. Always resolve the display
// term through this file. This is the single source for participant-facing
// vocabulary so the hybrid audience (solo discipler / org / groups / apprentice)
// can be re-labeled in ONE place.

export type ParticipantRole =
  | 'discipler'
  | 'disciple'
  | 'apprentice'
  | 'groupMember';

// Default display terms. Re-label here only -- never in components.
export const AUDIENCE_TERMS: Record<ParticipantRole, string> = {
  discipler: 'Discipler',
  disciple: 'Disciple',
  apprentice: 'Apprentice',
  groupMember: 'Group Member',
};

export function audienceTerm(role: ParticipantRole): string {
  return AUDIENCE_TERMS[role];
}
