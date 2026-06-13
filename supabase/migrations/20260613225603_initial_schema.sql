-- ============================================================================
-- Making Disciples Daily -- Initial schema (Phase 1, items 6-7)
-- ----------------------------------------------------------------------------
-- One atomic migration: enums -> tables (RLS on, authenticated-only grants)
-- -> SECURITY DEFINER helper functions -> RLS policies.
--
-- ARCHITECTURE PRINCIPLES ENFORCED HERE:
--   #2 Frontend drives backend: the four Phase-1 enums below mirror the string
--      unions in src/constants/contracts.ts EXACTLY (role, visibility,
--      commitment_status, prayer_status). The four Phase-2 enums (growth_sign,
--      question_type, apprentice_stage, group_type) are still `never` in
--      contracts.ts, so NO database enum is created for them yet.
--   #4 Care for people: adult-to-minor discipling is NEVER a private channel.
--      A minor's relationship / prayer / journal MUST carry an org_id (so an
--      org admin always has oversight), and RLS gives an org admin AND the
--      linked guardian read access regardless of 'private' visibility.
--   Rule #18: roles live ONLY in user_roles; helper functions are created
--      BEFORE any policy that uses them.
--
-- All migrations are CLI-applied (Rule #14). Reviewed before db push (gate).
-- ============================================================================

create extension if not exists pgcrypto;  -- gen_random_uuid()

-- ============================================================================
-- SECTION 1 -- ENUM TYPES (mirror src/constants/contracts.ts exactly)
-- ============================================================================

create type public.role as enum ('admin', 'org_admin', 'org_member', 'discipler');
create type public.visibility as enum ('private', 'group', 'org');
create type public.commitment_status as enum ('open', 'completed', 'missed', 'cancelled');
create type public.prayer_status as enum ('active', 'answered', 'archived');

-- ============================================================================
-- SECTION 2 -- TABLES
-- (RLS enabled + grants applied per table in SECTION 3; policies in SECTION 5.)
-- ============================================================================

-- ---- profiles --------------------------------------------------------------
-- One row per auth user. Profile is created by the app right after signup
-- (NO auth.users trigger -- Principle #2 forbids business-logic triggers).
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  avatar_url text,
  timezone text not null default 'UTC',
  quiet_hours jsonb,                                   -- e.g. {"start":"22:00","end":"07:00"}
  is_minor boolean not null default false,             -- Principle #4 flag, from migration one
  notification_prefs jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---- guardian_contacts -----------------------------------------------------
-- Parent/guardian record for a minor (locked decision, June 13 2026). Combined
-- with org-admin oversight, this is the guardian half of the minor-safety rule.
create table public.guardian_contacts (
  id uuid primary key default gen_random_uuid(),
  minor_user_id uuid not null references public.profiles(id) on delete cascade,
  guardian_name text not null,
  guardian_email text not null,
  relationship text,                                   -- e.g. "mother", "legal guardian"
  created_at timestamptz not null default now()
);
create index idx_guardian_contacts_minor on public.guardian_contacts(minor_user_id);
create index idx_guardian_contacts_email on public.guardian_contacts(lower(guardian_email));

-- ---- organizations ---------------------------------------------------------
create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  created_by uuid not null references auth.users(id),
  settings jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- ---- org_members (NO role column -- Rule #18) ------------------------------
create table public.org_members (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'invited' check (status in ('active', 'invited', 'suspended')),
  created_at timestamptz not null default now(),
  unique (org_id, user_id)
);
create index idx_org_members_user on public.org_members(user_id);
create index idx_org_members_org on public.org_members(org_id);

-- ---- user_roles (roles live ONLY here -- Rule #18) ------------------------
-- org_id NULL => solo (role 'discipler') or platform ('admin').
create table public.user_roles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  org_id uuid references public.organizations(id) on delete cascade,
  role public.role not null,
  created_at timestamptz not null default now(),
  unique (user_id, org_id, role)
);
create index idx_user_roles_user on public.user_roles(user_id);
create index idx_user_roles_org on public.user_roles(org_id);

-- ---- invitations (admin-insert only) --------------------------------------
create table public.invitations (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations(id) on delete cascade,
  email text not null,
  role public.role not null default 'org_member',
  token text not null unique,
  invited_by uuid not null references auth.users(id),
  expires_at timestamptz not null,
  accepted_at timestamptz,
  created_at timestamptz not null default now()
);
create index idx_invitations_org on public.invitations(org_id);
create index idx_invitations_email on public.invitations(lower(email));

-- ---- relationships (1:1 discipler -> disciple; optional apprentice) --------
-- SAFETY: a minor disciple MUST have org_id (so an org admin oversees) -- this
-- is enforced in the RLS WITH CHECK below, never a private adult-minor channel.
create table public.relationships (
  id uuid primary key default gen_random_uuid(),
  discipler_id uuid not null references public.profiles(id) on delete cascade,
  disciple_id uuid not null references public.profiles(id) on delete cascade,
  apprentice_id uuid references public.profiles(id) on delete set null,   -- Phase 2
  org_id uuid references public.organizations(id) on delete set null,
  status text not null default 'active' check (status in ('active', 'paused', 'ended')),
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  created_at timestamptz not null default now(),
  check (discipler_id <> disciple_id)
);
create index idx_relationships_discipler on public.relationships(discipler_id);
create index idx_relationships_disciple on public.relationships(disciple_id);
create index idx_relationships_org on public.relationships(org_id);

-- ---- groups (group_type enum deferred to Phase 2) -------------------------
create table public.groups (
  id uuid primary key default gen_random_uuid(),
  org_id uuid references public.organizations(id) on delete cascade,
  name text not null,
  description text,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now()
);
create index idx_groups_org on public.groups(org_id);

-- ---- group_members --------------------------------------------------------
create table public.group_members (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (group_id, user_id)
);
create index idx_group_members_group on public.group_members(group_id);
create index idx_group_members_user on public.group_members(user_id);

-- ---- sessions (1:1 or group discipleship session record) ------------------
create table public.sessions (
  id uuid primary key default gen_random_uuid(),
  relationship_id uuid references public.relationships(id) on delete cascade,
  group_id uuid references public.groups(id) on delete cascade,
  org_id uuid references public.organizations(id) on delete set null,
  created_by uuid not null references public.profiles(id),
  title text,
  notes text,
  scheduled_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  check (relationship_id is not null or group_id is not null)
);
create index idx_sessions_relationship on public.sessions(relationship_id);
create index idx_sessions_group on public.sessions(group_id);

-- ---- commitments ----------------------------------------------------------
create table public.commitments (
  id uuid primary key default gen_random_uuid(),
  relationship_id uuid references public.relationships(id) on delete cascade,
  session_id uuid references public.sessions(id) on delete set null,
  assigned_to uuid not null references public.profiles(id) on delete cascade,
  created_by uuid not null references public.profiles(id),
  description text not null,
  due_date date,
  status public.commitment_status not null default 'open',
  completed_at timestamptz,
  created_at timestamptz not null default now()
);
create index idx_commitments_relationship on public.commitments(relationship_id);
create index idx_commitments_assigned on public.commitments(assigned_to);

-- ---- prayer_requests (visibility + prayer_status; minor oversight) --------
-- SAFETY: a request authored by OR about a minor MUST carry org_id.
create table public.prayer_requests (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles(id) on delete cascade,
  subject_id uuid references public.profiles(id) on delete set null,   -- who it is about
  relationship_id uuid references public.relationships(id) on delete set null,
  group_id uuid references public.groups(id) on delete set null,
  org_id uuid references public.organizations(id) on delete set null,
  title text not null,
  body text,
  visibility public.visibility not null default 'private',
  status public.prayer_status not null default 'active',
  answered_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index idx_prayer_author on public.prayer_requests(author_id);
create index idx_prayer_group on public.prayer_requests(group_id);
create index idx_prayer_org on public.prayer_requests(org_id);

-- ---- journal_entries (visibility; minor oversight) ------------------------
create table public.journal_entries (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles(id) on delete cascade,
  relationship_id uuid references public.relationships(id) on delete set null,
  org_id uuid references public.organizations(id) on delete set null,
  title text,
  body text,
  visibility public.visibility not null default 'private',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index idx_journal_author on public.journal_entries(author_id);

-- ---- notifications (in-app only in v1) ------------------------------------
create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  type text not null,
  title text not null,
  body text,
  link text,
  read_at timestamptz,
  created_at timestamptz not null default now()
);
create index idx_notifications_user on public.notifications(user_id);

-- ---- activity_logs (append-only audit trail) ------------------------------
create table public.activity_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.profiles(id) on delete set null,
  org_id uuid references public.organizations(id) on delete set null,
  action text not null,
  entity_type text,
  entity_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index idx_activity_org on public.activity_logs(org_id);
create index idx_activity_actor on public.activity_logs(actor_id);

-- ============================================================================
-- SECTION 3 -- GRANTS + RLS ENABLE (authenticated only, no anon)
-- ============================================================================
do $$
declare t text;
begin
  foreach t in array array[
    'profiles','guardian_contacts','organizations','org_members','user_roles',
    'invitations','relationships','groups','group_members','sessions',
    'commitments','prayer_requests','journal_entries','notifications','activity_logs'
  ] loop
    -- enable (NOT force) RLS: clients only ever connect as anon/authenticated,
    -- both fully filtered by the policies below. The table owner (postgres) and
    -- service_role bypass RLS -- required so the SECURITY DEFINER helper
    -- functions can read these same tables without infinite policy recursion.
    execute format('alter table public.%I enable row level security;', t);
    execute format('revoke all on table public.%I from anon;', t);
    execute format('grant select, insert, update, delete on table public.%I to authenticated;', t);
  end loop;
end $$;

-- ============================================================================
-- SECTION 4 -- HELPER FUNCTIONS (SECURITY DEFINER, created BEFORE policies)
-- ----------------------------------------------------------------------------
-- Owned by the migration role (postgres) which bypasses RLS inside the function
-- body -- the documented Supabase pattern that prevents RLS recursion when a
-- table's policy must read user_roles / org_members / relationships.
-- search_path is pinned empty; every object is schema-qualified.
-- ============================================================================

-- has_role(uid, org, role): exact membership in user_roles. org IS NULL matches
-- the solo/platform rows (org_id null) via "is not distinct from".
create or replace function public.has_role(_user_id uuid, _org_id uuid, _role public.role)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.user_roles ur
    where ur.user_id = _user_id
      and ur.role = _role
      and (ur.org_id is not distinct from _org_id)
  );
$$;

-- is_org_admin: org_admin of this org, OR the platform admin.
create or replace function public.is_org_admin(_user_id uuid, _org_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select public.has_role(_user_id, _org_id, 'org_admin')
      or public.has_role(_user_id, null, 'admin');
$$;

-- is_org_member: active org_members row, OR org_admin/platform admin.
create or replace function public.is_org_member(_user_id uuid, _org_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.org_members om
    where om.user_id = _user_id
      and om.org_id = _org_id
      and om.status = 'active'
  )
  or public.is_org_admin(_user_id, _org_id);
$$;

-- is_discipler_of: active discipler -> disciple relationship.
create or replace function public.is_discipler_of(_user_id uuid, _disciple_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.relationships r
    where r.discipler_id = _user_id
      and r.disciple_id = _disciple_id
      and r.status = 'active'
  );
$$;

-- is_minor: convenience flag read for the oversight rule (Principle #4).
create or replace function public.is_minor(_user_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select coalesce((select p.is_minor from public.profiles p where p.id = _user_id), false);
$$;

-- is_guardian_of: the linked guardian of a minor, matched by the guardian email
-- on the viewer's auth account. (Guardian portal access requires the guardian to
-- hold an account with that email -- see PROJECT_MASTER carry-forward flag.)
create or replace function public.is_guardian_of(_user_id uuid, _minor_user_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1
    from public.guardian_contacts gc
    join auth.users u on lower(u.email) = lower(gc.guardian_email)
    where gc.minor_user_id = _minor_user_id
      and u.id = _user_id
  );
$$;

-- can_oversee_minor: TRUE if the viewer is an org admin of the minor's org OR a
-- linked guardian. This is the read-side override that guarantees an adult-minor
-- record is never private from oversight (Principle #4).
create or replace function public.can_oversee_minor(_user_id uuid, _minor_user_id uuid, _org_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select public.is_org_admin(_user_id, _org_id)
      or public.is_guardian_of(_user_id, _minor_user_id);
$$;

revoke all on function
  public.has_role(uuid, uuid, public.role),
  public.is_org_admin(uuid, uuid),
  public.is_org_member(uuid, uuid),
  public.is_discipler_of(uuid, uuid),
  public.is_minor(uuid),
  public.is_guardian_of(uuid, uuid),
  public.can_oversee_minor(uuid, uuid, uuid)
from anon;

grant execute on function
  public.has_role(uuid, uuid, public.role),
  public.is_org_admin(uuid, uuid),
  public.is_org_member(uuid, uuid),
  public.is_discipler_of(uuid, uuid),
  public.is_minor(uuid),
  public.is_guardian_of(uuid, uuid),
  public.can_oversee_minor(uuid, uuid, uuid)
to authenticated;

-- ============================================================================
-- SECTION 5 -- RLS POLICIES
-- ============================================================================

-- ---- profiles -------------------------------------------------------------
create policy profiles_select on public.profiles for select to authenticated
using (
  id = auth.uid()
  or public.is_discipler_of(auth.uid(), id)
  or public.is_guardian_of(auth.uid(), id)
  or exists (
    select 1 from public.org_members om
    where om.user_id = profiles.id and public.is_org_admin(auth.uid(), om.org_id)
  )
  or public.has_role(auth.uid(), null, 'admin')
);
create policy profiles_insert on public.profiles for insert to authenticated
with check (id = auth.uid());
create policy profiles_update on public.profiles for update to authenticated
using (id = auth.uid() or public.has_role(auth.uid(), null, 'admin'))
with check (id = auth.uid() or public.has_role(auth.uid(), null, 'admin'));
create policy profiles_delete on public.profiles for delete to authenticated
using (id = auth.uid() or public.has_role(auth.uid(), null, 'admin'));

-- ---- guardian_contacts ----------------------------------------------------
create policy guardian_select on public.guardian_contacts for select to authenticated
using (
  minor_user_id = auth.uid()
  or public.is_discipler_of(auth.uid(), minor_user_id)
  or public.is_guardian_of(auth.uid(), minor_user_id)
  or exists (
    select 1 from public.org_members om
    where om.user_id = guardian_contacts.minor_user_id
      and public.is_org_admin(auth.uid(), om.org_id)
  )
  or public.has_role(auth.uid(), null, 'admin')
);
create policy guardian_write on public.guardian_contacts for all to authenticated
using (
  public.is_discipler_of(auth.uid(), minor_user_id)
  or exists (
    select 1 from public.org_members om
    where om.user_id = guardian_contacts.minor_user_id
      and public.is_org_admin(auth.uid(), om.org_id)
  )
  or public.has_role(auth.uid(), null, 'admin')
)
with check (
  public.is_discipler_of(auth.uid(), minor_user_id)
  or exists (
    select 1 from public.org_members om
    where om.user_id = guardian_contacts.minor_user_id
      and public.is_org_admin(auth.uid(), om.org_id)
  )
  or public.has_role(auth.uid(), null, 'admin')
);

-- ---- organizations --------------------------------------------------------
create policy orgs_select on public.organizations for select to authenticated
using (public.is_org_member(auth.uid(), id) or public.has_role(auth.uid(), null, 'admin'));
create policy orgs_insert on public.organizations for insert to authenticated
with check (created_by = auth.uid());
create policy orgs_update on public.organizations for update to authenticated
using (public.is_org_admin(auth.uid(), id))
with check (public.is_org_admin(auth.uid(), id));
create policy orgs_delete on public.organizations for delete to authenticated
using (public.is_org_admin(auth.uid(), id));

-- ---- org_members ----------------------------------------------------------
create policy org_members_select on public.org_members for select to authenticated
using (
  user_id = auth.uid()
  or public.is_org_member(auth.uid(), org_id)
);
-- admin-invite only: only an org admin inserts membership rows.
create policy org_members_insert on public.org_members for insert to authenticated
with check (public.is_org_admin(auth.uid(), org_id));
-- org admin manages status; a member may update their own row (accept -> active).
create policy org_members_update on public.org_members for update to authenticated
using (public.is_org_admin(auth.uid(), org_id) or user_id = auth.uid())
with check (public.is_org_admin(auth.uid(), org_id) or user_id = auth.uid());
create policy org_members_delete on public.org_members for delete to authenticated
using (public.is_org_admin(auth.uid(), org_id) or user_id = auth.uid());

-- ---- user_roles (privilege table -- no self-escalation) -------------------
create policy user_roles_select on public.user_roles for select to authenticated
using (
  user_id = auth.uid()
  or public.is_org_admin(auth.uid(), org_id)
  or public.has_role(auth.uid(), null, 'admin')
);
-- INSERT: platform admin anything; a user may grant ONLY their own solo
-- 'discipler' default (no elevated privilege); an org admin may grant
-- org_admin/org_member within their own org (never 'admin', never solo roles).
create policy user_roles_insert on public.user_roles for insert to authenticated
with check (
  public.has_role(auth.uid(), null, 'admin')
  or (user_id = auth.uid() and org_id is null and role = 'discipler')
  or (org_id is not null and role in ('org_admin', 'org_member')
      and public.is_org_admin(auth.uid(), org_id))
);
create policy user_roles_update on public.user_roles for update to authenticated
using (
  public.has_role(auth.uid(), null, 'admin')
  or (org_id is not null and role in ('org_admin', 'org_member')
      and public.is_org_admin(auth.uid(), org_id))
)
with check (
  public.has_role(auth.uid(), null, 'admin')
  or (org_id is not null and role in ('org_admin', 'org_member')
      and public.is_org_admin(auth.uid(), org_id))
);
create policy user_roles_delete on public.user_roles for delete to authenticated
using (
  public.has_role(auth.uid(), null, 'admin')
  or (org_id is not null and role in ('org_admin', 'org_member')
      and public.is_org_admin(auth.uid(), org_id))
);

-- ---- invitations (admin-insert only) --------------------------------------
create policy invitations_select on public.invitations for select to authenticated
using (public.is_org_admin(auth.uid(), org_id));
create policy invitations_insert on public.invitations for insert to authenticated
with check (public.is_org_admin(auth.uid(), org_id) and invited_by = auth.uid());
create policy invitations_update on public.invitations for update to authenticated
using (public.is_org_admin(auth.uid(), org_id))
with check (public.is_org_admin(auth.uid(), org_id));
create policy invitations_delete on public.invitations for delete to authenticated
using (public.is_org_admin(auth.uid(), org_id));

-- ---- relationships (minor oversight; never a private adult-minor channel) --
create policy relationships_select on public.relationships for select to authenticated
using (
  discipler_id = auth.uid()
  or disciple_id = auth.uid()
  or apprentice_id = auth.uid()
  or public.is_org_admin(auth.uid(), org_id)
  or (public.is_minor(disciple_id) and public.can_oversee_minor(auth.uid(), disciple_id, org_id))
  or public.has_role(auth.uid(), null, 'admin')
);
-- INSERT/UPDATE WITH CHECK enforces: a minor disciple MUST have org_id, so an
-- org admin always oversees -- structurally no private adult-minor channel.
create policy relationships_insert on public.relationships for insert to authenticated
with check (
  (discipler_id = auth.uid() or public.is_org_admin(auth.uid(), org_id))
  and ((not public.is_minor(disciple_id)) or org_id is not null)
);
create policy relationships_update on public.relationships for update to authenticated
using (
  discipler_id = auth.uid()
  or public.is_org_admin(auth.uid(), org_id)
  or public.has_role(auth.uid(), null, 'admin')
)
with check (
  (discipler_id = auth.uid() or public.is_org_admin(auth.uid(), org_id)
   or public.has_role(auth.uid(), null, 'admin'))
  and ((not public.is_minor(disciple_id)) or org_id is not null)
);
create policy relationships_delete on public.relationships for delete to authenticated
using (
  public.is_org_admin(auth.uid(), org_id)
  or public.has_role(auth.uid(), null, 'admin')
);

-- ---- groups ---------------------------------------------------------------
create policy groups_select on public.groups for select to authenticated
using (
  created_by = auth.uid()
  or (org_id is not null and public.is_org_member(auth.uid(), org_id))
  or exists (
    select 1 from public.group_members gm
    where gm.group_id = groups.id and gm.user_id = auth.uid()
  )
  or public.has_role(auth.uid(), null, 'admin')
);
create policy groups_insert on public.groups for insert to authenticated
with check (
  created_by = auth.uid()
  and (org_id is null or public.is_org_member(auth.uid(), org_id))
);
create policy groups_update on public.groups for update to authenticated
using (created_by = auth.uid() or public.is_org_admin(auth.uid(), org_id))
with check (created_by = auth.uid() or public.is_org_admin(auth.uid(), org_id));
create policy groups_delete on public.groups for delete to authenticated
using (created_by = auth.uid() or public.is_org_admin(auth.uid(), org_id));

-- ---- group_members --------------------------------------------------------
create policy group_members_select on public.group_members for select to authenticated
using (
  user_id = auth.uid()
  or exists (
    select 1 from public.groups g
    where g.id = group_members.group_id
      and (g.created_by = auth.uid()
           or public.is_org_admin(auth.uid(), g.org_id)
           or exists (
             select 1 from public.group_members gm2
             where gm2.group_id = g.id and gm2.user_id = auth.uid()
           ))
  )
  or public.has_role(auth.uid(), null, 'admin')
);
create policy group_members_write on public.group_members for all to authenticated
using (
  exists (
    select 1 from public.groups g
    where g.id = group_members.group_id
      and (g.created_by = auth.uid() or public.is_org_admin(auth.uid(), g.org_id))
  )
  or public.has_role(auth.uid(), null, 'admin')
)
with check (
  exists (
    select 1 from public.groups g
    where g.id = group_members.group_id
      and (g.created_by = auth.uid() or public.is_org_admin(auth.uid(), g.org_id))
  )
  or public.has_role(auth.uid(), null, 'admin')
);

-- ---- sessions -------------------------------------------------------------
create policy sessions_select on public.sessions for select to authenticated
using (
  created_by = auth.uid()
  or public.is_org_admin(auth.uid(), org_id)
  or exists (
    select 1 from public.relationships r
    where r.id = sessions.relationship_id
      and (r.discipler_id = auth.uid() or r.disciple_id = auth.uid() or r.apprentice_id = auth.uid()
           or (public.is_minor(r.disciple_id) and public.can_oversee_minor(auth.uid(), r.disciple_id, r.org_id)))
  )
  or exists (
    select 1 from public.group_members gm
    where gm.group_id = sessions.group_id and gm.user_id = auth.uid()
  )
  or public.has_role(auth.uid(), null, 'admin')
);
create policy sessions_insert on public.sessions for insert to authenticated
with check (
  created_by = auth.uid()
  and (
    public.is_org_admin(auth.uid(), org_id)
    or exists (
      select 1 from public.relationships r
      where r.id = sessions.relationship_id
        and (r.discipler_id = auth.uid() or r.apprentice_id = auth.uid())
    )
    or exists (
      select 1 from public.groups g
      where g.id = sessions.group_id and g.created_by = auth.uid()
    )
  )
);
create policy sessions_update on public.sessions for update to authenticated
using (created_by = auth.uid() or public.is_org_admin(auth.uid(), org_id) or public.has_role(auth.uid(), null, 'admin'))
with check (created_by = auth.uid() or public.is_org_admin(auth.uid(), org_id) or public.has_role(auth.uid(), null, 'admin'));
create policy sessions_delete on public.sessions for delete to authenticated
using (created_by = auth.uid() or public.is_org_admin(auth.uid(), org_id) or public.has_role(auth.uid(), null, 'admin'));

-- ---- commitments ----------------------------------------------------------
create policy commitments_select on public.commitments for select to authenticated
using (
  assigned_to = auth.uid()
  or created_by = auth.uid()
  or exists (
    select 1 from public.relationships r
    where r.id = commitments.relationship_id
      and (r.discipler_id = auth.uid() or r.disciple_id = auth.uid() or r.apprentice_id = auth.uid()
           or public.is_org_admin(auth.uid(), r.org_id)
           or (public.is_minor(r.disciple_id) and public.can_oversee_minor(auth.uid(), r.disciple_id, r.org_id)))
  )
  or public.has_role(auth.uid(), null, 'admin')
);
create policy commitments_insert on public.commitments for insert to authenticated
with check (
  created_by = auth.uid()
  and exists (
    select 1 from public.relationships r
    where r.id = commitments.relationship_id
      and (r.discipler_id = auth.uid() or r.disciple_id = auth.uid() or r.apprentice_id = auth.uid())
  )
);
create policy commitments_update on public.commitments for update to authenticated
using (
  assigned_to = auth.uid() or created_by = auth.uid()
  or exists (select 1 from public.relationships r where r.id = commitments.relationship_id and public.is_org_admin(auth.uid(), r.org_id))
  or public.has_role(auth.uid(), null, 'admin')
)
with check (
  assigned_to = auth.uid() or created_by = auth.uid()
  or exists (select 1 from public.relationships r where r.id = commitments.relationship_id and public.is_org_admin(auth.uid(), r.org_id))
  or public.has_role(auth.uid(), null, 'admin')
);
create policy commitments_delete on public.commitments for delete to authenticated
using (
  created_by = auth.uid()
  or exists (select 1 from public.relationships r where r.id = commitments.relationship_id and public.is_org_admin(auth.uid(), r.org_id))
  or public.has_role(auth.uid(), null, 'admin')
);

-- ---- prayer_requests (visibility + minor oversight override) --------------
create policy prayer_select on public.prayer_requests for select to authenticated
using (
  author_id = auth.uid()
  or subject_id = auth.uid()
  or (visibility = 'org' and org_id is not null and public.is_org_member(auth.uid(), org_id))
  or (visibility = 'group' and group_id is not null and exists (
        select 1 from public.group_members gm
        where gm.group_id = prayer_requests.group_id and gm.user_id = auth.uid()))
  -- oversight override: a request by OR about a minor is visible to the org
  -- admin and the linked guardian regardless of 'private' visibility.
  or (public.is_minor(author_id) and public.can_oversee_minor(auth.uid(), author_id, org_id))
  or (subject_id is not null and public.is_minor(subject_id)
        and public.can_oversee_minor(auth.uid(), subject_id, org_id))
  or public.has_role(auth.uid(), null, 'admin')
);
-- INSERT WITH CHECK: a request by OR about a minor MUST carry org_id (oversight).
create policy prayer_insert on public.prayer_requests for insert to authenticated
with check (
  author_id = auth.uid()
  and (
    ((not public.is_minor(author_id))
     and (subject_id is null or not public.is_minor(subject_id)))
    or org_id is not null
  )
);
create policy prayer_update on public.prayer_requests for update to authenticated
using (
  author_id = auth.uid()
  or (public.is_minor(author_id) and public.can_oversee_minor(auth.uid(), author_id, org_id))
  or public.has_role(auth.uid(), null, 'admin')
)
with check (
  author_id = auth.uid()
  or (public.is_minor(author_id) and public.can_oversee_minor(auth.uid(), author_id, org_id))
  or public.has_role(auth.uid(), null, 'admin')
);
create policy prayer_delete on public.prayer_requests for delete to authenticated
using (
  author_id = auth.uid()
  or (public.is_minor(author_id) and public.can_oversee_minor(auth.uid(), author_id, org_id))
  or public.has_role(auth.uid(), null, 'admin')
);

-- ---- journal_entries (visibility + minor oversight override) --------------
create policy journal_select on public.journal_entries for select to authenticated
using (
  author_id = auth.uid()
  or (visibility = 'org' and org_id is not null and public.is_org_member(auth.uid(), org_id))
  or (public.is_minor(author_id) and public.can_oversee_minor(auth.uid(), author_id, org_id))
  or public.has_role(auth.uid(), null, 'admin')
);
create policy journal_insert on public.journal_entries for insert to authenticated
with check (
  author_id = auth.uid()
  and ((not public.is_minor(author_id)) or org_id is not null)
);
create policy journal_update on public.journal_entries for update to authenticated
using (author_id = auth.uid() or public.has_role(auth.uid(), null, 'admin'))
with check (author_id = auth.uid() or public.has_role(auth.uid(), null, 'admin'));
create policy journal_delete on public.journal_entries for delete to authenticated
using (
  author_id = auth.uid()
  or (public.is_minor(author_id) and public.can_oversee_minor(auth.uid(), author_id, org_id))
  or public.has_role(auth.uid(), null, 'admin')
);

-- ---- notifications --------------------------------------------------------
-- Generation is server-side (daily reminder edge function / service_role, which
-- bypasses RLS). Authenticated users read and mark-read their own only.
create policy notifications_select on public.notifications for select to authenticated
using (user_id = auth.uid() or public.has_role(auth.uid(), null, 'admin'));
create policy notifications_insert on public.notifications for insert to authenticated
with check (public.has_role(auth.uid(), null, 'admin'));
create policy notifications_update on public.notifications for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());
create policy notifications_delete on public.notifications for delete to authenticated
using (user_id = auth.uid() or public.has_role(auth.uid(), null, 'admin'));

-- ---- activity_logs (append-only: insert + read, no update/delete) ---------
create policy activity_select on public.activity_logs for select to authenticated
using (
  actor_id = auth.uid()
  or (org_id is not null and public.is_org_admin(auth.uid(), org_id))
  or public.has_role(auth.uid(), null, 'admin')
);
create policy activity_insert on public.activity_logs for insert to authenticated
with check (actor_id = auth.uid());
-- intentionally NO update/delete policy => those commands are denied (immutable).

-- ============================================================================
-- END initial schema
-- ============================================================================
