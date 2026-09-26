begin;

-- Opt-in call replays: a user can choose, per session, to save a recording of
-- their own camera/mic to Cloudflare R2 for later review. Off by default;
-- rows self-expire after 30 days. Inserts only ever happen through
-- save_practice_replay so a session's ownership is verified server-side and
-- expires_at can't be spoofed by the client.
create table if not exists public.practice_replays (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  session_id uuid not null references public.practice_sessions(id) on delete cascade,
  r2_key text not null,
  mime_type text not null default 'video/webm',
  duration_seconds integer not null default 0,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '30 days'
);

create index if not exists practice_replays_user_id_idx on public.practice_replays(user_id);
create index if not exists practice_replays_expires_at_idx on public.practice_replays(expires_at);

alter table public.practice_replays enable row level security;

drop policy if exists "practice_replays_select_own" on public.practice_replays;
create policy "practice_replays_select_own" on public.practice_replays
  for select using (auth.uid() = user_id);

drop policy if exists "practice_replays_delete_own" on public.practice_replays;
create policy "practice_replays_delete_own" on public.practice_replays
  for delete using (auth.uid() = user_id);

-- No insert/update policy for authenticated: rows are only ever created by
-- save_practice_replay (security definer) below.

create or replace function public.save_practice_replay(
  p_session_id uuid, p_r2_key text, p_mime_type text default 'video/webm',
  p_duration_seconds integer default 0
) returns public.practice_replays
language plpgsql security definer set search_path = public
as $$
declare
  v_user uuid := auth.uid(); v_replay public.practice_replays;
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  if not exists(select 1 from public.practice_sessions where id = p_session_id and user_id = v_user) then
    raise exception 'Session not found';
  end if;
  if p_r2_key is null or length(p_r2_key) = 0 or length(p_r2_key) > 300 then
    raise exception 'Invalid replay key';
  end if;
  insert into public.practice_replays(user_id, session_id, r2_key, mime_type, duration_seconds)
    values (v_user, p_session_id, p_r2_key, left(coalesce(p_mime_type,'video/webm'),64),
            greatest(0, coalesce(p_duration_seconds,0)))
    returning * into v_replay;
  return v_replay;
end;
$$;

revoke all on function public.save_practice_replay(uuid,text,text,integer) from public,anon;
grant execute on function public.save_practice_replay(uuid,text,text,integer) to authenticated;

-- Lazily expires the CALLING user's own overdue replays (mirrors
-- expire_stale_practice_sessions) and returns their R2 keys so the backend
-- can delete the matching objects from Cloudflare R2 right after.
create or replace function public.expire_stale_practice_replays()
returns setof text
language plpgsql security definer set search_path = public
as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  return query
    delete from public.practice_replays
    where user_id = v_user and expires_at < now()
    returning r2_key;
end;
$$;

revoke all on function public.expire_stale_practice_replays() from public,anon;
grant execute on function public.expire_stale_practice_replays() to authenticated;

commit;
