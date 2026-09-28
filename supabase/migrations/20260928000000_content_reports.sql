begin;

-- Lets a user flag an AI-generated response they found objectionable, giving
-- HardSync a reviewable report queue (Apple App Review guideline 1.2 requires
-- apps with AI/user-generated content to offer a reporting mechanism).
-- Inserts only ever happen through report_ai_response so session ownership
-- is verified server-side rather than trusted from the client.
create table if not exists public.content_reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  session_id uuid references public.practice_sessions(id) on delete set null,
  speaker text,
  reported_text text not null,
  note text,
  status text not null default 'open',
  created_at timestamptz not null default now()
);

create index if not exists content_reports_user_id_idx on public.content_reports(user_id);
create index if not exists content_reports_created_at_idx on public.content_reports(created_at);

alter table public.content_reports enable row level security;

drop policy if exists "content_reports_select_own" on public.content_reports;
create policy "content_reports_select_own" on public.content_reports
  for select using (auth.uid() = user_id);

-- No insert/update/delete policy for authenticated: rows are only ever
-- created by report_ai_response (security definer) below, and reviewed
-- through the service role.

create or replace function public.report_ai_response(
  p_session_id uuid, p_reported_text text, p_speaker text default null,
  p_note text default null
) returns public.content_reports
language plpgsql security definer set search_path = public
as $$
declare
  v_user uuid := auth.uid(); v_report public.content_reports;
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  if p_session_id is not null and not exists(
    select 1 from public.practice_sessions where id = p_session_id and user_id = v_user
  ) then
    raise exception 'Session not found';
  end if;
  if p_reported_text is null or length(trim(p_reported_text)) = 0 then
    raise exception 'Reported text is required';
  end if;
  insert into public.content_reports(user_id, session_id, speaker, reported_text, note)
    values (v_user, p_session_id, left(coalesce(p_speaker,''), 64),
            left(p_reported_text, 4000), left(coalesce(p_note,''), 2000))
    returning * into v_report;
  return v_report;
end;
$$;

revoke all on function public.report_ai_response(uuid,text,text,text) from public,anon;
grant execute on function public.report_ai_response(uuid,text,text,text) to authenticated;

commit;
