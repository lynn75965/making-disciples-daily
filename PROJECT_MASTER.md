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
7. MINORS IN v1 (locked June 13, 2026): a minor uses org-admin visibility AND a
   parent/guardian contact record (guardian_contacts table). Adult-to-minor
   discipling must be visible to BOTH an org admin and the linked guardian.
   Enforced structurally: a minor's relationship / prayer / journal MUST carry an
   org_id (so an org admin always oversees) -- there is no private adult-minor
   channel. CONFIRMED CONSEQUENCE (locked v1 behavior): a SOLO discipler with no
   org CANNOT take on a minor in v1. A minor must be in an org. Shipped as
   written in migration 20260613225603.
8. GUARDIAN LOGIN DEFERRED (June 13, 2026): guardians get NO login accounts in
   v1 -- oversight of adult-minor records is ORG-ADMIN-MEDIATED only. The
   guardian_contacts record (name/email/relationship) is kept, and the
   is_guardian_of() / guardian-read-by-email RLS path stays in the schema
   (harmless with no guardian accounts, ready for later), but a guardian PORTAL /
   login is explicitly a LATER PHASE pending the paid-model design. Do NOT treat
   guardian login as an active v1 feature.

---

## CURRENT STATUS

Phase 0 (governance scaffold) -- COMPLETE and deployed (commit 2e6b3ff).

Phase 1 items 6-7 (Supabase backend foundation) -- COMPLETE and APPLIED to the
remote. The NEW Supabase project is provisioned and linked (ref
uprfupgiuruseobvhxce, us-east-2). One atomic migration applied cleanly:
supabase/migrations/20260613225603_initial_schema.sql -- 15 tables, 4 enums
(role/visibility/commitment_status/prayer_status mirroring contracts.ts), RLS
ENABLE on every table (NOT force -- so the SECURITY DEFINER helpers avoid policy
recursion), authenticated-only grants (no anon), the four helper functions
(has_role, is_org_admin, is_org_member, is_discipler_of) plus is_minor /
is_guardian_of / can_oversee_minor, and 54 RLS policies with the locked
minor-oversight rule encoded. Verified by `supabase migration list --linked`
(version 20260613225603 recorded on both Local and Remote; migrations apply
transactionally, so the recorded version means every statement committed).
Phase-1 enum VALUES live in the SSOT (contracts.ts re-exports Role/Visibility;
values derive from accessControl.ts / prayerVisibility.ts; commitment/prayer
statuses owned in contracts.ts). Gates: sync-constants 11/11, audit-ssot 0
findings, npm run build clean.

Next action for Claude Code: WHAT'S NEXT item 8 (auth: email/password + reset,
profiles, solo-discipler default). After Lynn's first signup, capture her
auth.users UUID here (Rule #19).

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
- Admin auth.users UUID for the break-glass RLS policies (Rule #19) -- STILL
  PENDING: no Supabase user exists yet. The initial schema does NOT include the
  hardcoded-UUID break-glass policies; platform-admin access currently runs
  through has_role(auth.uid(), null, 'admin'). Capture Lynn's auth.users id after
  her first signup and record it here; add break-glass policies only if/when
  needed (Rule #19).
- [RESOLVED June 13, 2026] Parent/guardian record on minors -- YES (Locked
  Decision #7). guardian_contacts table added; org-admin AND guardian oversight
  both enforced in RLS. See FLAG FOR LYNN in the June 13 session log for the
  solo-discipler-cannot-take-a-minor consequence to confirm.
- [RESOLVED June 13, 2026] Guardian portal access: DEFERRED to a later phase
  (Locked Decision #8). No guardian login accounts in v1; oversight is
  org-admin-mediated. is_guardian_of() stays in the schema, dormant until
  guardians get accounts. Enum values for role/commitment_status/prayer_status/
  visibility APPROVED as proposed and shipped in migration 20260613225603.

---

## SESSION LOG

### June 13, 2026 -- Phase 1 items 6-7: Supabase backend foundation (Claude Code, session 2)
- Ran /audit-ssot first (Rule #15): CLEAN (0 findings) before any change.
- PROVISIONED + LINKED the NEW Supabase project. Lynn had already created it in
  the dashboard. CLI was authenticated; confirmed the right one: name
  "making-disciples-daily", ref uprfupgiuruseobvhxce, us-east-2, created
  2026-06-13. Verified SEPARATE from BLS (LessonSparkUSA, ref hphebzdftpjbiudpfcrs)
  -- Locked Decision #2 honored. `supabase init` + `supabase link --project-ref
  uprfupgiuruseobvhxce`. Confirmed empty: `supabase migration list --linked`
  shows no remote migrations. Recorded ref in CLAUDE.md SUPABASE PROJECT block.
- DEFINED Phase-1 enum VALUES in the SSOT (had been empty `never` stubs):
  role = admin/org_admin/org_member/discipler (accessControl.ts);
  visibility = private/group/org (prayerVisibility.ts);
  commitment_status = open/completed/missed/cancelled (contracts.ts);
  prayer_status = active/answered/archived (contracts.ts).
  Refactored so each literal has ONE source: value arrays are `as const`, types
  DERIVED via typeof[number]; contracts.ts re-exports Role/Visibility as the
  import surface. Phase-2 enums (growth_sign, question_type, apprentice_stage,
  group_type) intentionally left `never` -- no DB enum created for them yet
  (a Postgres enum needs >= 1 label; "mirror exactly" = empty here, absent in SQL).
- WROTE one atomic migration: supabase/migrations/20260613225603_initial_schema.sql
  -- 15 tables (profiles w/ is_minor, guardian_contacts, organizations,
  org_members [no role col, Rule #18], user_roles [roles live here only],
  invitations, relationships, groups, group_members, sessions, commitments,
  prayer_requests [visibility+status], journal_entries, notifications,
  activity_logs); 4 enums; RLS ENABLE + FORCE on all; revoke from anon + grant
  select/insert/update/delete to authenticated. Helper SECURITY DEFINER funcs
  created BEFORE policies (Rule #18): has_role, is_org_admin, is_org_member,
  is_discipler_of, plus is_minor / is_guardian_of / can_oversee_minor for the
  child-safety rule. Full RLS policy set. user_roles INSERT policy blocks
  self-escalation (a user may only self-grant the solo 'discipler' default).
- MINOR-OVERSIGHT (Locked Decision #7 / Principle #4) encoded in RLS:
  relationships/prayer_requests/journal_entries WITH CHECK require org_id when a
  minor is involved (so an org admin always oversees); SELECT policies grant the
  org admin AND linked guardian read access regardless of 'private' visibility.
- DECISIONS SETTLED BY LYNN (this session): (a) minors require an org -- ship as
  written; a solo discipler with no org cannot disciple a minor in v1 (Locked
  Decision #7). (b) guardians get no login in v1; org-admin-mediated oversight
  only; guardian portal deferred (Locked Decision #8). (c) enum values approved
  exactly as proposed. No migration changes were needed.
- Updated scripts/audit-ssot.cjs: added a tight, documented CROSS_DOMAIN_LITERALS
  allowlist for 'discipler' (an authz Role value AND an audienceConfig
  ParticipantRole key -- two distinct SSOTs by design, must not import each
  other). This is a governance-tool tweak (same class as the Phase-0 heuristic
  tightening); noted here for transparency.
- GATES: sync-constants 11/11; audit-ssot 0 findings; npm run build clean.
- PUSHED: `npx supabase db push --linked` applied 20260613225603 cleanly (only a
  harmless NOTICE that pgcrypto already existed). The CLI connected via a
  temporary login role provisioned from the access token -- no DB password was
  needed or entered. Verified with `supabase migration list --linked`: version
  20260613225603 on both Local and Remote. (Object-by-object `supabase db dump`
  was unavailable -- it requires Docker, not installed -- but the transactional
  apply + recorded version confirms all 4 enums, 15 tables, RLS, 7 functions, and
  54 policies committed.)
- COMMITTED via deploy.ps1 "FEATURE: Phase 1 initial Supabase schema + RLS".
- CARRY-FORWARD: (1) Capture Lynn's auth.users UUID after her first signup
  (Rule #19) -- the only remaining backend-foundation open item. (2) WHAT'S NEXT
  item 8 (auth + profiles + solo-discipler default). (3) Guardian portal/login
  is a deferred later-phase feature (Locked Decision #8) -- do not build in v1.

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
- CARRY-FORWARD:deploy.ps1 branch guard cannot create the first commit on an unborn branch (zero-commit repo). Worked around manually for MDD. Before the first white-label tenant provision, harden the branch check to handle the unborn-branch case — Claude Code offered the fix; it's a standalone governance-artifact commit.