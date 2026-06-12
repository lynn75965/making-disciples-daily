# Claude Code Kickoff Prompt -- Making Disciples Daily, Session 1

# HOW TO USE THIS FILE
# Open Claude Code in C:\Users\Lynn\making-disciples-daily and paste the block
# below (everything under the line) as your first message. It tells Claude Code
# what to build first and where to stop. Place CLAUDE.md and PROJECT_MASTER.md
# in the repo root and the two .cjs files in scripts/ BEFORE you start, so
# Claude Code auto-reads them. The deploy.ps1 goes in the repo root.

# -------------------------------------------------------------------------

You are starting work on Making Disciples Daily (MDD). Before doing anything,
read CLAUDE.md and PROJECT_MASTER.md in full and confirm you understand the
locked decisions and the workflow rules. Both files are in the repo root.

Two decisions are already locked -- do not relitigate them:
- Path A: replace the existing TanStack Start / Cloudflare Workers scaffold with
  a plain Vite + React 18 + TypeScript + Tailwind SPA. No SSR.
- A NEW Supabase project will be used (not provisioned yet -- that is Phase 1).

Your job THIS SESSION is Phase 0 only -- the governance scaffold, commit one.
Do not build any features. Do not provision Supabase. Stop at the gate.

Phase 0 tasks, in order:

1. Replace the TanStack Start scaffold with a Vite + React 18 + TS + Tailwind
   SPA. Single main branch. package.json has "type": "module". Wire these npm
   scripts: "build", "dev", "sync-constants" (-> node scripts/sync-constants.cjs),
   and "audit-ssot" (-> node scripts/audit-ssot.cjs).

2. Confirm the governance files are in place and correct: CLAUDE.md and
   PROJECT_MASTER.md in root; scripts/ascii-guard.cjs and
   scripts/sync-constants.cjs in scripts/; deploy.ps1 in root. Install the
   ASCII guard as a git pre-commit hook per the instructions at the bottom of
   ascii-guard.cjs.

3. Create the SSOT skeleton from the CLAUDE.md SSOT File Map. Every file gets a
   header comment and stub exports so all imports resolve from commit one:
     src/constants/contracts.ts, routes.ts, accessControl.ts, validation.ts,
     growthSigns.ts, apprenticeStages.ts, questionTypes.ts, prayerVisibility.ts,
     reminderPolicy.ts, invitationConfig.ts, bibleVersions.ts,
     scriptureGuardrail.ts, audienceConfig.ts
     src/config/branding.ts, featureFlags.ts
   Reserve EMPTY: src/constants/theologyProfiles.ts, src/constants/pricingConfig.ts
   (header comment only, no entries -- the SSOT slot exists for later).

4. Build scripts/audit-ssot.cjs as a READ-ONLY diagnostic that scans src/ for
   duplicated constants and hardcoded values, verifies every route in routes.ts
   also appears in App.tsx (Rule #3), and writes findings to
   SSOT_AUDIT_REPORT.md. It makes no code changes.

5. Run npm run sync-constants and confirm it succeeds (or reports cleanly which
   reserved stubs are intentionally absent from FILES_TO_SYNC). Then run
   npm run build and confirm it is clean -- zero errors.

GATE -- STOP HERE:
Start the dev server (npm run dev) and HOLD. Do not run deploy.ps1. Tell Lynn
exactly what to check on localhost. Wait for her explicit approval. Only after
she approves do you run:
  .\deploy.ps1 "FEATURE: Phase 0 governance scaffold + SSOT skeleton"

Then complete the session-end protocol: update PROJECT_MASTER.md with a session
log, and remind Lynn to re-upload PROJECT_MASTER.md to the Claude.ai project.

Constraints that apply the whole time:
- Complete files only, no diffs (Rule #2). ASCII-only source; JS escapes for any
  non-ASCII (Rule #12). Routes go in routes.ts AND App.tsx together (Rule #3).
  No participant strings hardcoded -- route through audienceConfig.ts (Rule #13).
  If you are unsure where something lives, say so rather than guess (Rule #10).
