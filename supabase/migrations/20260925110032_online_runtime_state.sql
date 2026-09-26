begin;

-- Public catalog content. Asset keys refer to bundled, versioned artwork; no
-- remote URLs or user data are stored in these rows.
create table if not exists public.personas (
  id text primary key,
  name text not null,
  role text not null,
  company text not null,
  avatar_asset text not null,
  call_background_asset text not null,
  bio text not null,
  personality_traits text not null,
  baseline_defensiveness integer not null check (baseline_defensiveness between 0 and 100),
  pushback_phrases jsonb not null default '[]'::jsonb,
  yielding_phrases jsonb not null default '[]'::jsonb,
  tavus_replica_id text not null default '',
  voice_style text not null,
  position integer not null default 0,
  active boolean not null default true,
  updated_at timestamptz not null default now()
);

create table if not exists public.user_persona_options (
  id text primary key,
  title text not null,
  level text not null,
  role_summary text not null,
  core_stakes text not null,
  icon_asset text not null,
  default_trap_hedging text not null,
  executive_standard text not null,
  position integer not null default 0,
  active boolean not null default true
);

create table if not exists public.learning_paths (
  id text primary key,
  title text not null,
  audience text not null,
  illustration_asset text not null,
  position integer not null default 0,
  active boolean not null default true
);

create table if not exists public.courses (
  id text primary key,
  title text not null,
  audience text not null,
  level text not null,
  promise text not null,
  takeaway text not null,
  hero_asset text not null,
  position integer not null default 0,
  active boolean not null default true,
  updated_at timestamptz not null default now()
);

create table if not exists public.path_courses (
  path_id text not null references public.learning_paths(id) on delete cascade,
  course_id text not null references public.courses(id) on delete cascade,
  position integer not null default 0,
  primary key (path_id, course_id)
);

create table if not exists public.lessons (
  id uuid primary key default gen_random_uuid(),
  course_id text not null references public.courses(id) on delete cascade,
  position integer not null,
  title text not null,
  outcome text not null,
  concept text not null,
  example text not null,
  reflection text not null,
  illustration_asset text not null,
  unique (course_id, position)
);

alter table public.profiles
  add column if not exists onboarding_completed boolean not null default false,
  add column if not exists selected_goal_ids jsonb not null default '[]'::jsonb,
  add column if not exists selected_user_persona_id text references public.user_persona_options(id),
  add column if not exists settings jsonb not null default '{"camera_enabled":true,"mic_enabled":true}'::jsonb;

create table if not exists public.learning_progress (
  user_id uuid not null references public.profiles(id) on delete cascade,
  course_id text not null references public.courses(id) on delete cascade,
  lesson_position integer not null check (lesson_position >= 0),
  completed_at timestamptz not null default now(),
  reflection text,
  primary key (user_id, course_id, lesson_position)
);
create index if not exists learning_progress_user_idx on public.learning_progress(user_id);

create table if not exists public.practice_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  scenario_id text references public.scenarios(id) on delete set null,
  mode text not null check (mode in ('text','audio','video')),
  provider text not null check (provider in ('gemini_text','gemini_live','tavus')),
  status text not null check (status in ('starting','active','ended','cancelled','failed')),
  credit_cost integer not null check (credit_cost >= 0),
  provider_session_id text,
  context text not null default '',
  report jsonb,
  analysis jsonb,
  recording_object_key text,
  created_at timestamptz not null default now(),
  ended_at timestamptz
);
create index if not exists practice_sessions_user_created_idx
  on public.practice_sessions(user_id, created_at desc);

create table if not exists public.practice_turns (
  id bigint generated always as identity primary key,
  session_id uuid not null references public.practice_sessions(id) on delete cascade,
  turn_index integer not null check (turn_index >= 0),
  speaker text not null check (speaker in ('user','persona')),
  speaker_name text not null,
  text text not null check (length(trim(text)) > 0),
  timestamp_ms integer not null check (timestamp_ms >= 0),
  unique (session_id, turn_index)
);
create index if not exists practice_turns_session_idx on public.practice_turns(session_id, turn_index);

create table if not exists public.credit_ledger (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  amount integer not null check (amount <> 0),
  reason text not null,
  session_id uuid references public.practice_sessions(id) on delete set null,
  external_event_id text unique,
  created_at timestamptz not null default now()
);
create index if not exists credit_ledger_user_created_idx
  on public.credit_ledger(user_id, created_at desc);

alter table public.personas enable row level security;
alter table public.user_persona_options enable row level security;
alter table public.learning_paths enable row level security;
alter table public.courses enable row level security;
alter table public.path_courses enable row level security;
alter table public.lessons enable row level security;
alter table public.learning_progress enable row level security;
alter table public.practice_sessions enable row level security;
alter table public.practice_turns enable row level security;
alter table public.credit_ledger enable row level security;

grant select on public.personas, public.user_persona_options, public.learning_paths,
  public.courses, public.path_courses, public.lessons to anon, authenticated;
grant select, insert, update, delete on public.learning_progress to authenticated;
grant select on public.practice_sessions, public.practice_turns, public.credit_ledger to authenticated;
grant update (full_name, avatar_url, leadership_role, onboarding_completed,
  selected_goal_ids, selected_user_persona_id, settings) on public.profiles to authenticated;

drop policy if exists "catalog personas readable" on public.personas;
create policy "catalog personas readable" on public.personas for select to anon, authenticated using (active);
drop policy if exists "catalog user personas readable" on public.user_persona_options;
create policy "catalog user personas readable" on public.user_persona_options for select to anon, authenticated using (active);
drop policy if exists "catalog paths readable" on public.learning_paths;
create policy "catalog paths readable" on public.learning_paths for select to anon, authenticated using (active);
drop policy if exists "catalog courses readable" on public.courses;
create policy "catalog courses readable" on public.courses for select to anon, authenticated using (active);
drop policy if exists "catalog path courses readable" on public.path_courses;
create policy "catalog path courses readable" on public.path_courses for select to anon, authenticated using (true);
drop policy if exists "catalog lessons readable" on public.lessons;
create policy "catalog lessons readable" on public.lessons for select to anon, authenticated using (true);

drop policy if exists "users read own learning progress" on public.learning_progress;
create policy "users read own learning progress" on public.learning_progress
  for select to authenticated using ((select auth.uid()) = user_id);
drop policy if exists "users insert own learning progress" on public.learning_progress;
create policy "users insert own learning progress" on public.learning_progress
  for insert to authenticated with check ((select auth.uid()) = user_id);
drop policy if exists "users update own learning progress" on public.learning_progress;
create policy "users update own learning progress" on public.learning_progress
  for update to authenticated using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
drop policy if exists "users delete own learning progress" on public.learning_progress;
create policy "users delete own learning progress" on public.learning_progress
  for delete to authenticated using ((select auth.uid()) = user_id);

drop policy if exists "users read own practice sessions" on public.practice_sessions;
create policy "users read own practice sessions" on public.practice_sessions
  for select to authenticated using ((select auth.uid()) = user_id);
drop policy if exists "users read own practice turns" on public.practice_turns;
create policy "users read own practice turns" on public.practice_turns
  for select to authenticated using (exists (
    select 1 from public.practice_sessions s
    where s.id = practice_turns.session_id and s.user_id = (select auth.uid())
  ));
drop policy if exists "users read own credit ledger" on public.credit_ledger;
create policy "users read own credit ledger" on public.credit_ledger
  for select to authenticated using ((select auth.uid()) = user_id);

-- Atomic credit reservation. Clients cannot update balances or author ledger
-- rows directly. The JWT identity is the only accepted owner.
create or replace function public.reserve_practice_session(
  p_scenario_id text, p_mode text, p_provider text, p_context text default ''
) returns public.practice_sessions
language plpgsql security definer set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_cost integer;
  v_session public.practice_sessions;
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  v_cost := case p_mode when 'text' then 5 when 'audio' then 15 when 'video' then 30 else null end;
  if v_cost is null then raise exception 'Unknown practice mode'; end if;
  update public.profiles set credits = credits - v_cost
    where id = v_user and credits >= v_cost;
  if not found then raise exception 'Insufficient credits'; end if;
  insert into public.practice_sessions(user_id, scenario_id, mode, provider, status, credit_cost, context)
    values(v_user, p_scenario_id, p_mode, p_provider, 'starting', v_cost, left(coalesce(p_context,''),6000))
    returning * into v_session;
  insert into public.credit_ledger(user_id, amount, reason, session_id)
    values(v_user, -v_cost, 'practice_reservation', v_session.id);
  return v_session;
end;
$$;
revoke all on function public.reserve_practice_session(text,text,text,text) from public, anon;
grant execute on function public.reserve_practice_session(text,text,text,text) to authenticated;

create or replace function public.refund_unconnected_practice_session(p_session_id uuid)
returns boolean language plpgsql security definer set search_path = public
as $$
declare v_user uuid := auth.uid(); v_cost integer;
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  update public.practice_sessions set status='cancelled', ended_at=now()
    where id=p_session_id and user_id=v_user and status='starting'
    returning credit_cost into v_cost;
  if v_cost is null then return false; end if;
  update public.profiles set credits=credits+v_cost where id=v_user;
  insert into public.credit_ledger(user_id,amount,reason,session_id)
    values(v_user,v_cost,'practice_refund',p_session_id);
  return true;
end;
$$;
revoke all on function public.refund_unconnected_practice_session(uuid) from public, anon;
grant execute on function public.refund_unconnected_practice_session(uuid) to authenticated;

commit;
