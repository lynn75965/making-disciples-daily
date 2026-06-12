// src/constants/scriptureGuardrail.ts
// Making Disciples Daily -- SSOT: Scripture Guardrail (Rule 5 equivalent)
//
// ARCHITECTURE PRINCIPLE #3 (scripture integrity): any verse text pasted into a
// session, journal entry, or passage template is checked for a valid reference
// format and a fair-use length cap (from bibleVersions.ts). In any FUTURE
// AI-assisted path, fabricated verse text is hard-prohibited. v1 has no AI
// generation, but the guardrail is built now so paste-in fields are protected
// from day one and any future feature inherits it.
//
// STUB STATE (Phase 0): a lightweight reference-format check is provided as a
// starting point; the fair-use cap is wired to bibleVersions.ts in Phase 1.

// Permissive starting pattern (book chapter:verse style). Tightened in Phase 1.
export const SCRIPTURE_REFERENCE_PATTERN = /^[A-Za-z0-9][A-Za-z0-9 .,:;-]*$/;

export function isValidReference(reference: string): boolean {
  return SCRIPTURE_REFERENCE_PATTERN.test(reference.trim());
}
