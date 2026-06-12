# Making Disciples Daily -- Claude Code Instructions
# Last updated: June 12, 2026
# READ THIS ENTIRE FILE BEFORE TOUCHING ANY CODE

## AUTO-READ ON SESSION START
Read this file (CLAUDE.md) AND PROJECT_MASTER.md in full before responding to
any request. Confirm understanding of all workflow rules before proceeding.

---

## WHO OWNS THIS PROJECT

Lynn -- retired Baptist minister, PhD, 55 years ministry experience.
NON-PROGRAMMER solopreneur. Requires complete file replacements, not diffs or patches.
Every solution must be complete and working. No partial fixes. No assumptions.

This app is a sister product to BibleLessonSpark (BLS) and follows the same
build discipline. If you have worked on BLS, the workflow muscle memory carries
over. The DOMAIN is different: MDD is about discipler-to-disciple relationships
and multiplication, not lesson generation. Do not import BLS domain assumptions
(8-section lessons, theology profiles, pricing tiers, conversion copy) into MDD.

---

## WHAT THIS APP IS

Making Disciples Daily (MDD) equips disciple-makers for multiple discipler-to-
disciple relationships that multiply upon use. Audience is hybrid: a solo
discipler, a church/org, groups, and an apprentice (discipler-in-training) mode.

Org membership is ADMIN-INVITE ONLY. A new signup defaults to solo discipler.
Joining an org requires an invite token issued by an org admin.

v1 has NO AI generation, NO payments/billing, NO email/SMS/push (in-app
notifications only), and NO public Bible API (manual paste only, fair-use
capped, scripture-integrity guarded).

---

## REPOSITORY

Local:   C:\Users\Lynn\making-disciples-daily
GitHub:  https://github.com/lynn75965/making-disciples-daily   (confirm exact slug at setup)
Branch:  main (ONLY branch -- never create secondary branches)
Live:    making-disciples-daily.com (Netlify auto-deploys from main)

---

## STACK

Frontend:   React 18 + TypeScript + Vite + Tailwind CSS
Backend:    Supabase (PostgreSQL + Edge Functions)
Deploy:     Netlify (auto-deploy from GitHub main)
Payments:   NONE in v1 (Stripe deferred; when added, follows BLS webhook-from-SSOT pattern)
package.json has "type": "module" -- use .cjs for Node scripts

NEVER use Lovable Cloud, Vercel, or any other host. Netlify only.
The initial Lovable scaffold is TanStack Start on Cloudflare Workers. That is
REPLACED on day one with a plain Vite + React 18 SPA (Path A). Do not build on
the TanStack Start scaffold.

---

## DEPLOY SEQUENCE (NEVER SKIP STEPS)

1. npm run build           (must be clean -- zero errors)
2. Start dev server: npm run dev
3. HOLD -- Lynn must verify on localhost in a new browser tab
4. Do NOT run deploy.ps1 until Lynn gives explicit approval
5. .\deploy.ps1 "message"  (PowerShell, -ExecutionPolicy Bypass)

NEVER run deploy.ps1 without Lynn's explicit localhost approval first. No exceptions.
NEVER push code that has not compiled cleanly.

---

## FILE WRITING -- CRITICAL RULES

### PATH VERIFICATION BEFORE EVERY FILE WRITE -- no exceptions
Before writing or editing any file, confirm its exact path:
Get-ChildItem "C:\Users\Lynn\making-disciples-daily\src" -Recurse | Where-Object { $_.Name -eq "TargetFile.tsx" }
Replace "TargetFile.tsx" with the actual filename. Do not assume paths from memory.
Files may live in subdirectories you do not expect (e.g., dashboard/, layout/, people/).

### NEVER use Set-Content -Encoding UTF8
PowerShell UTF8 adds a BOM (\xEF\xBB\xBF) that trips the ASCII deploy guard.

### ALWAYS use this method for file writes:
[System.IO.File]::WriteAllText($path, $content, [System.Text.UTF8Encoding]::new($false))

### For complex multi-line TypeScript files:
Use a Node .cjs script (NOT .js) with fs.writeFileSync() and an array of lines joined by \n
Example:
  const lines = [
    'line one',
    'line two',
  ];
  require('fs').writeFileSync('target.ts', lines.join('\n'), 'utf8');

### Why .cjs not .js:
package.json has "type": "module" -- .js files are treated as ESM and will fail with require()

### PowerShell here-strings:
Correct syntax for single quotes: @'...'@
Do NOT use bash-style escaping like '"'"' -- it does not work in PowerShell

### If a file is corrupted:
Restore from git BEFORE patching: git checkout HEAD -- path/to/file.ts
(Workflow Rule #8)

---

## ASCII GUARD

The deploy.ps1 pre-commit hook blocks any non-ASCII characters in staged
.ts/.tsx source files. This includes: em dashes, curly quotes, box-drawing
characters, Unicode symbols.

If you must represent a special character, use a JavaScript escape sequence.
Example: \u2014 for em dash, \u00F3 for o-with-accent

Use git commit --no-verify ONLY when a BOM or encoding issue is confirmed and
cannot be resolved any other way. Not for convenience.

---

## ARCHITECTURE PRINCIPLE #1: SSOT (Single Source of Truth)

Every constant, type, and configuration has ONE authoritative source.
All consumers import from that single source.
NO duplicate definitions anywhere in the codebase.
Changes to a domain require updating only ONE file.

### SSOT File Map

| Domain                       | Authoritative File                         |
|------------------------------|--------------------------------------------|
| Types / Interfaces           | src/constants/contracts.ts                 |
| Routes                       | src/constants/routes.ts                    |
| Access Control / Roles       | src/constants/accessControl.ts             |
| Validation Rules             | src/constants/validation.ts                |
| Growth Signs (the 7)         | src/constants/growthSigns.ts               |
| Apprentice Stages            | src/constants/apprenticeStages.ts          |
| Question Types               | src/constants/questionTypes.ts             |
| Prayer Visibility            | src/constants/prayerVisibility.ts          |
| Reminder Policy              | src/constants/reminderPolicy.ts            |
| Invitation Config            | src/constants/invitationConfig.ts          |
| Bible Versions               | src/constants/bibleVersions.ts             |
| Scripture Guardrail (Rule 5) | src/constants/scriptureGuardrail.ts        |
| Audience / Role Terms        | src/constants/audienceConfig.ts            |
| Branding                     | src/config/branding.ts                     |
| Feature Flags                | src/config/featureFlags.ts                 |

RESERVED for later (create the slot, leave empty until needed):
| Theology Profiles            | src/constants/theologyProfiles.ts          |
| Pricing                      | src/constants/pricingConfig.ts             |

### Before touching any SSOT file:
Audit ALL consumers of that file. Every import must be verified.
Never declare work complete until all consumers are checked.

---

## ARCHITECTURE PRINCIPLE #2: FRONTEND DRIVES BACKEND

Frontend constants are the authoritative source.
Backend (Supabase) validates against frontend-defined values.
Database enum values must match frontend constants EXACTLY.
RLS policies reference values from the frontend enum list -- never read config
from a table.
NEVER propose database triggers for business logic or autonomous backend actions.

Edge functions in v1 are limited to exactly three jobs:
1. Sending invite emails
2. The daily reminder generator (pg_cron)
3. GDPR export/delete

The DB enums that MUST mirror contracts.ts exactly:
role, growth_sign, question_type, visibility, apprentice_stage, group_type,
commitment_status, prayer_status.

---

## ARCHITECTURE PRINCIPLE #3: SCRIPTURE INTEGRITY (Rule 5 equivalent)

Reverence for Scripture is enforced in code via src/constants/scriptureGuardrail.ts.
Any verse text pasted into a session, journal entry, or passage template is
checked for: valid reference format, fair-use length cap (from bibleVersions.ts),
and -- in any future AI-assisted path -- a hard prohibition on fabricated verse
text. v1 has no AI generation, but the guardrail is built now so journal and
session paste-in fields are protected from day one and any future feature
inherits it.

---

## ARCHITECTURE PRINCIPLE #4: CARE FOR PEOPLE IS ENFORCED IN RLS

This app puts adult disciplers in ongoing relationship with people who may be
minors. Two protections are structural, not optional:

1. profiles.is_minor flag exists from the first migration.
2. Adult-to-minor discipling relationships are VISIBLE to an org admin (and,
   where applicable, a parent/guardian contact) by default -- never private
   between an adult and a minor. Prayer and message visibility rules in
   prayerVisibility.ts and the RLS policies must enforce this. When in doubt,
   default to MORE oversight, not less. Flag any design that would create a
   private adult-minor channel and STOP for Lynn's review.

---

## CRITICAL WORKFLOW RULES

### Rule #1: Verify actual file contents before any change
Never assume file contents. Read the actual file before proposing any change.
Identify the violation with file name and line number before proposing a fix.
Claude Code: Read files directly from the repo -- do not ask Lynn to upload them.

### Rule #2: Complete solutions only -- no partial fixes
Provide full file contents. No diffs. No patches. No partial edits.
Lynn copies complete files -- she does not apply patches manually.
Claude Code: Edit files in place using complete rewrites.

### Rule #3: Route bug pattern -- update BOTH files
Every route added to routes.ts MUST also be added to App.tsx in the SAME pass.
VERIFY BOTH FILES on every route change. This pattern caused four production
bugs in the sister project. Do not let it happen here.

### Rule #4: Dependency chain before deploy
Verify all files referencing new properties or exports are included in the same deploy.

### Rule #5: npm run build before every deploy
No exceptions. Clean build required before .\deploy.ps1

### Rule #6: Never overwrite working code with stale copies
Always verify the file being deployed reflects ALL changes from the current session.

### Rule #7: Verify before claiming
Never cite a commit reference or session log as proof a change exists.
Read the actual file and confirm the change is present.

### Rule #8: Corrupted files -- restore from git first
git checkout HEAD -- src/path/to/file.ts THEN apply fix to clean file.

### Rule #9: Single branch only
Branch is main. No secondary branches. Deploy script enforces main.

### Rule #10: Never present options you are not certain about
If you do not know where a Supabase setting lives, say so.
Uncertainty stated clearly is less damaging than confident wrong guidance.

### Rule #11: Bible version IDs must be lowercase
Backend expects kjv, esv, niv etc. Frontend must normalize before saving.

### Rule #12: Use JavaScript escape sequences for non-ASCII
Never use literal Unicode in source files. ASCII guard will block the deploy.
Correct: \u2014 for em dash. Wrong: pasting the actual character.

### Rule #13: AudienceConfig -- never hardcode participant strings
NEVER hardcode "disciple", "discipler", "apprentice", or "group member" as
display strings in components. Always resolve through audienceConfig.ts.

### Rule #14: Supabase migrations via CLI only
All database schema changes MUST use a migration file in supabase/migrations/
and be applied via: npx supabase db push --linked
NEVER apply schema changes manually via the Supabase Dashboard SQL editor.
Before running db push: verify the SQL is correct AND the change is not already
applied to the live database.

### Rule #15: Run /audit-ssot before touching constants, configs, or backend
At the start of any session that touches constants, roles, routes, growth signs,
or backend functions -- run the /audit-ssot slash command first.
It is read-only and diagnostic. It saves findings to SSOT_AUDIT_REPORT.md.
Never modify SSOT files without first knowing the current violation state.

### Rule #16: Accessibility is non-negotiable on every UI change
Every interactive element must meet WCAG 2.1 AA minimum. See the ACCESSIBILITY
VERIFICATION BLOCK at the end of this file. Append it to every CC prompt that
touches any UI component, navigation, modal, form, or interactive element.

### Rule #17: Run npm run sync-constants after every change to a FILES_TO_SYNC file
The synced files mirror from src/constants/ to supabase/functions/_shared/ via
scripts/sync-constants.cjs. The current FILES_TO_SYNC list lives in that script.
Run npm run sync-constants immediately after editing any synced file. Never
hand-edit the _shared/ mirrors -- they are auto-generated and overwritten on the
next sync.

### Rule #18: Roles live in their own table
user_roles is a dedicated table with a has_role() SECURITY DEFINER function that
powers RLS. NEVER store role on org_members or profiles. Build has_role,
is_org_admin, is_org_member, and is_discipler_of BEFORE writing any RLS policy
that depends on them.

### Rule #19: Hardcoded admin UUID in RLS admin policies -- break-glass only
The break-glass admin_full_access RLS pattern grants one hardcoded admin UUID
(Lynn's auth.users id) full access on admin tables. It is RESTRICTIVE (one user)
and intentionally accepted. DO NOT rewrite these policies unless Lynn explicitly
asks to add a second admin, at which point the rewrite swaps the literal UUID
check for has_role(auth.uid(), 'admin'). Record the exact UUID and affected
tables in PROJECT_MASTER.md when provisioned.

---

## DEBUGGING PROTOCOL

1. STOP -- Do not propose solutions immediately
2. DIAGNOSE -- Identify root cause through systematic analysis
3. VERIFY -- Confirm diagnosis before any code changes
4. PROPOSE -- Present complete solution with substantiation
5. WAIT -- Get approval before implementing
6. IMPLEMENT -- Provide complete, tested solution

---

## COMMIT MESSAGE FORMAT

[CATEGORY]: Brief description
Categories: SSOT, FIX, FEATURE, REFACTOR, SECURITY, DOCS

---

## SUPABASE PROJECT

URL: <fill at provisioning -- NEW project, never reuse the BLS project>
Edge Functions: supabase/functions/
Shared utilities: supabase/functions/_shared/

NEVER commingle MDD data with BibleLessonSpark or any other project. MDD is a
separate Supabase project with its own data plane.

---

## SLASH COMMANDS

### /prime
Read CLAUDE.md and PROJECT_MASTER.md in full. Confirm architecture understanding before proceeding.

### /create-plan
Create a step-by-step implementation plan for the requested task. Present for approval before writing any code.

### /implement
Implement the approved plan. Follow deploy sequence. No partial fixes.

### /audit-ssot
Runs a read-only SSOT and Frontend-Drives-Backend audit of the entire project.
- Scans all src/ files for duplicated constants, hardcoded values, and backend-defined values that should be frontend-sourced
- Checks for any database-stored strings that conflict with or duplicate frontend SSOT definitions
- Checks that every route in routes.ts appears in App.tsx (Rule #3)
- Produces a findings report saved as SSOT_AUDIT_REPORT.md in the project root
- NO code changes are made during this command -- diagnostic only
- Report format: violation, file, line number, rule broken, recommended fix
Run this command at the start of any session touching constants, configs, roles, routes, or backend functions.

---

## PROJECT ROOT AUDIT FILES

SSOT_AUDIT_REPORT.md -- Generated by /audit-ssot. Contains all SSOT and
Frontend-Drives-Backend violations found in the last audit run. Read this
before touching any SSOT files.

---

## MANDATORY SESSION-END PROTOCOL -- not optional

At the end of every working session, before signing off:

1. Update PROJECT_MASTER.md with a session log covering all work completed,
   files changed, commits made, bugs found/fixed, and carry-forward items.
2. Update CLAUDE.md ONLY if new rules were added or existing rules changed.
3. Commit both files: .\deploy.ps1 "DOCS: Update PROJECT_MASTER and CLAUDE for [date] session"
4. Remind Lynn: "Please re-upload PROJECT_MASTER.md to the Claude.ai project
   so the next session has current context."

This protocol ensures no session's work is lost between conversations.
Skipping it causes the next session to start with stale context, leading
to duplicated work and missed carry-forwards.

---

## ACCESSIBILITY VERIFICATION BLOCK
## Append this block to every CC prompt that touches any UI component, navigation, modal, form, or interactive element.

ACCESSIBILITY VERIFICATION (required on every UI change)

Making Disciples Daily is committed to WCAG 2.1 AA compliance.
Every feature must be usable without a mouse and by a screen-reader user.

Before reporting build complete, verify every interactive element changed or added:

ARIA
- Buttons that must stay focusable use aria-disabled="true" -- never the disabled attribute
- Decorative icons have aria-hidden="true"
- Gated/locked items have aria-label describing both name and reason
- Status regions use aria-live="polite"
- Error messages use role="alert"
- Nav landmarks have aria-label or equivalent

KEYBOARD
- Tab order includes all interactive elements
- Hidden elements use conditional rendering -- not display:none or visibility:hidden
- Focus moves to first error on validation failure
- Enter/Space activates every button and control

STRUCTURE
- Heading hierarchy is logical -- no skipped levels
- Form inputs have explicit label elements -- not placeholder-only
- Input groups use fieldset and legend where appropriate
- Skip link present on any page with substantial navigation

COMPONENTS
- Native HTML controls preferred on accessible flows
- If shadcn/Radix components used, verify correct ARIA behavior is not stripped by customization

ROUTES (if a new route was added)
- routes.ts updated
- App.tsx updated in the same pass

Keyboard-only verification: Tab through every changed element without using the mouse.
Confirm focus is visible at all times. Report any element that cannot be reached by keyboard.

---

Claude Code reads this file automatically at session start.
No manual priming required.

Before any work begins:
1. Read this file (CLAUDE.md) -- done automatically
2. Read PROJECT_MASTER.md -- required, contains current session state and What's Next
3. Read the actual source files relevant to the task
4. Confirm understanding before making any changes
5. npm run build after changes and before deploying
