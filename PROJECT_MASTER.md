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

Phase 0 (governance scaffold) -- governance documents drafted in Claude.ai
(this file, CLAUDE.md, deploy.ps1, sync-constants.cjs, the ASCII guard).
NOT YET committed to a repo. NOT YET wired to a live Supabase project.

Next action for Claude Code: see WHAT'S NEXT, item 1.

---

## WHAT'S NEXT (running to-do, in order)

### Phase 0 -- Foundations governance (commit one)
1. Initialize the repo at C:\Users\Lynn\making-disciples-daily. Replace the
   TanStack Start scaffold with a Vite + React 18 + TS + Tailwind SPA. Keep a
   single main branch.
2. Place CLAUDE.md, PROJECT_MASTER.md, deploy.ps1, scripts/sync-constants.cjs,
   and the ASCII pre-commit guard. Install the git hook from the guard.
3. Create the SSOT skeleton files from the CLAUDE.md SSOT File Map -- each with a
   header comment and stub exports so all imports resolve from commit one.
   Reserve (empty) theologyProfiles.ts and pricingConfig.ts.
4. Implement /audit-ssot as a read-only script writing SSOT_AUDIT_REPORT.md.
5. GATE: npm run build clean on the empty-but-wired scaffold. Lynn approves on
   localhost. Deploy. Nothing else in this commit.

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

- Exact GitHub repo slug to confirm in CLAUDE.md REPOSITORY block.
- Admin auth.users UUID for the break-glass RLS policies (Rule #19) -- captured
  after the first Supabase user is created.
- Whether a parent/guardian contact record is needed on minors in v1, or whether
  org-admin visibility alone satisfies the Phase-1 child-safety requirement.

---

## SESSION LOG

### June 12, 2026 -- Phase 0 governance bundle drafted (Claude.ai)
- Produced in a Claude.ai planning session (not yet in repo):
  CLAUDE.md (adapted from BLS: BLS domain rules stripped, MDD rules renumbered
  1-19, scripture-integrity and child-safety principles added),
  PROJECT_MASTER.md (this file, seeded with locked decisions + full to-do),
  deploy.ps1, scripts/sync-constants.cjs, scripts/ascii-guard.cjs.
- Locked the two open build decisions: Path A (Vite SPA) and a NEW Supabase
  project.
- CARRY-FORWARD: none yet. First Claude Code session starts at WHAT'S NEXT item 1.
