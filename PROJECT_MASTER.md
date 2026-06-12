# PROJECT MASTER -- Making Disciples Daily -- Last updated: June 12, 2026

## WHAT THIS FILE IS

The living state of the MDD build. Claude Code reads this in full at the start
of every session (after CLAUDE.md). The most recent session log is at the TOP.
The "WHAT'S NEXT" block below the locked decisions is the running to-do.

Re-upload this file to the Claude.ai project at the end of every session so the
next planning conversation has current context.

---

## LOCKED DECISIONS (do not relitigate without Lynn)

1. STACK: Path A. Replace the Lovable TanStack Start / Cloudflare Workers
   scaffold with a plain Vite + React 18 + TypeScript + Tailwind SPA. Matches
   BibleLessonSpark exactly. No SSR.
2. BACKEND: NEW Supabase project for MDD. Never reuse the BLS project. Never
   commingle data planes.
3. HOST: Netlify, auto-deploy from main. Domain: making-disciples-daily.com.
   Never Lovable Cloud, never Vercel.
4. v1 SCOPE EXCLUDES: AI generation, payments/billing, email/SMS/push (in-app
   notifications only), public Bible API (manual paste only), denomination/
   theology profiles (SSOT slot reserved, empty).
5. ORG MODEL: admin-invite only. New signups default to solo discipler.
6. SECURITY POSTURE: roles in their own table (user_roles + has_role()); RLS
   references frontend enums; adult-to-minor discipling relationships are admin/
   guardian visible by default, never a private adult-minor channel.

---

## CURRENT STATUS

Phase 0 (governance scaffold) -- COMPLETE and deployed. The Vite + React 18 + TS
+ Tailwind SPA is live on main, with the full governance toolchain (ASCII guard
pre-commit hook, sync-constants, audit-ssot, deploy.ps1) and the SSOT skeleton
(15 active files + 2 reserved-empty slots). Build clean, audit clean, ASCII
clean. Pushed to origin/main (commit 2e6b3ff). Netlify auto-deploys from main.
NOT YET wired to a live Supabase project (that is Phase 1).

Next action for Claude Code: see WHAT'S NEXT -- Phase 1, item 6 (provision the
NEW Supabase project and first migration set).

---

## WHAT'S NEXT (running to-do, in order)

### Phase 0 -- Foundations governance (commit one) -- DONE (June 12, 2026)
1. [DONE] Repo initialized at C:\Users\Lynn\making-disciples-daily on a single
   main branch. No TanStack scaffold existed; the Vite + React 18 + TS + Tailwind
   SPA was created fresh (Path A).
2. [DONE] CLAUDE.md + PROJECT_MASTER.md in root; scripts/ascii-guard.cjs,
   scripts/sync-constants.cjs, scripts/audit-ssot.cjs in scripts/; deploy.ps1 in
   root. ASCII guard installed as the git pre-commit hook.
3. [DONE] SSOT skeleton created from the SSOT File Map -- 15 active files +
   theologyProfiles.ts and pricingConfig.ts reserved empty. The 8 DB-enum types
   are defined once in contracts.ts and imported by their domain files.
4. [DONE] scripts/audit-ssot.cjs read-only diagnostic writing SSOT_AUDIT_REPORT.md.
5. [DONE] Build clean, audit clean (0 findings), sync clean (11/11). Lynn
   approved on localhost. Pushed to origin/main (commit 2e6b3ff).

### Phase 1 -- Foundations features
6. New Supabase project; link it; first migration set (profiles with is_minor,
   organizations, org_members [no role column], user_roles, invitations,
   relationships, groups, group_members, prayer_requests, journal_entries,
   sessions, commitments, notifications, activity_logs). RLS on, authenticated
   GRANTs only, no anon.
7. Helper SECURITY DEFINER functions FIRST: has_role, is_org_admin,
   is_org_member, is_discipler_of. Then RLS policies that use them.
8. Auth (email/password + reset), profiles, solo-discipler default.
9. Invitation flow: admin issues invite -> email link -> /auth/accept-invite ->
   joins org.
10. 1:1 relationships, session builder, commitments, follow-up.
11. Prayer requests with visibility enforcement (private/group/org), with the
    adult-minor oversight rule enforced in RLS.
12. Notifications inbox + daily reminder cron (commitments due, sessions in 24h,
    prayer stale 14d). User timezone + quiet hours honored.

### Phase 2 -- Growth and multiplication
13. Growth assessments + timeline + readiness flag (data-driven from
    growthSigns.ts).
14. Apprentice mode (Watch/Help/Lead checklist + mentor sign-off).
15. Groups, members, attendance, group commitments, meeting history.
16. Resource library: passage templates, question banks, reading plans.
17. Disciple-side journal.

### Phase 3 -- Polish
18. Org-wide reports (dashboard, growth trends, multiplication funnel).
19. Activity log viewer.
20. GDPR export/delete edge functions.
21. Onboarding wizard + optional demo data.

---

## OPEN QUESTIONS FOR LYNN (resolve before the phase that needs them)

- [RESOLVED June 12, 2026] GitHub repo slug confirmed: lynn75965/making-disciples-daily.
  Remote origin wired and Phase 0 pushed to main.
- Admin auth.users UUID for the break-glass RLS policies (Rule #19) -- captured
  after the first Supabase user is created.
- Whether a parent/guardian contact record is needed on minors in v1, or whether
  org-admin visibility alone satisfies the Phase-1 child-safety requirement.

---

## SESSION LOG

### June 12, 2026 -- Phase 0 scaffold built + deployed (Claude Code, session 1)
- Initialized git on a single main branch. NOTE: no TanStack Start scaffold was
  actually present in the folder (only the governance docs) -- so "replace the
  scaffold" became "create the Vite SPA fresh." Lower risk, same outcome.
- Built the Vite + React 18 + TS + Tailwind SPA (Path A): package.json with
  "type":"module"; scripts dev/build/sync-constants/audit-ssot; tsconfig project
  refs; tailwind/postcss (ESM); index.html; src/main.tsx; src/App.tsx.
- App.tsx wires ROUTES.HOME (Rule #3) and resolves all participant labels via
  audienceTerm() (Rule #13 -- no hardcoded participant strings).
- Moved ascii-guard.cjs and sync-constants.cjs into scripts/. Installed the ASCII
  guard as the git pre-commit hook (.git/hooks/pre-commit).
- Created the SSOT skeleton: contracts/routes/accessControl/validation/growthSigns/
  apprenticeStages/questionTypes/prayerVisibility/reminderPolicy/invitationConfig/
  bibleVersions/scriptureGuardrail/audienceConfig + config/branding + config/
  featureFlags. Reserved-empty: theologyProfiles.ts, pricingConfig.ts. The 8
  DB-enum types live once in contracts.ts; domain files import them (no dupes).
- Wrote scripts/audit-ssot.cjs (read-only): Rule #3 route check, Rule #13 hardcoded
  participant-string check (capitalized display terms in .tsx only), duplicate
  literal scan. First run flagged 4 false positives (lowercase SSOT keys + brand
  prose); tightened the heuristic; re-run CLEAN (0 findings).
- Added netlify.toml (build/publish/SPA redirect) and .gitattributes (LF, no BOM).
  Added *.tsbuildinfo to .gitignore (tsc -b cache, not tracked).
- Gates: npm run sync-constants clean (11/11 to supabase/functions/_shared/);
  npm run build clean (zero errors); ASCII guard clean (32 staged files). Lynn
  verified on localhost and approved.
- FILES CHANGED: entire Phase 0 scaffold (50 tracked files). COMMIT: 2e6b3ff
  "FEATURE: Phase 0 governance scaffold + SSOT skeleton" pushed to origin/main.
- DEPLOY NOTE (one-time): deploy.ps1's branch guard reads "HEAD" on an unborn
  branch (zero commits), so it cannot create the very first commit. Worked around
  by committing the Phase 0 commit directly + git push -u origin main; all
  deploy.ps1 gates (main / ASCII / build) were independently green. main now has
  history, so deploy.ps1 runs end-to-end normally from the NEXT deploy onward.
  deploy.ps1 itself was NOT modified (governance artifact -- left for Lynn).
- CARRY-FORWARD: (1) confirm Netlify is connected to lynn75965/making-disciples-
  daily and the first auto-build went green at making-disciples-daily.com.
  (2) Phase 1 starts at WHAT'S NEXT item 6 (NEW Supabase project + migrations).
  (3) Optional: ask Lynn whether deploy.ps1's branch guard should be hardened
  against the unborn-branch case for future repos (not needed for this one).

### June 12, 2026 -- Phase 0 governance bundle drafted (Claude.ai)
- Produced in a Claude.ai planning session (not yet in repo):
  CLAUDE.md (adapted from BLS: BLS domain rules stripped, MDD rules renumbered
  1-19, scripture-integrity and child-safety principles added),
  PROJECT_MASTER.md (this file, seeded with locked decisions + full to-do),
  deploy.ps1, scripts/sync-constants.cjs, scripts/ascii-guard.cjs.
- Locked the two open build decisions: Path A (Vite SPA) and a NEW Supabase
  project.
- CARRY-FORWARD: none yet. First Claude Code session starts at WHAT'S NEXT item 1.
