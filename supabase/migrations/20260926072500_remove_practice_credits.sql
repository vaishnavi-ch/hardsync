begin;

-- Keep the old billing columns and ledger for historical records, while making
-- all new practice sessions free and preventing any further balance changes.
create or replace function public.expire_stale_practice_sessions()
returns integer language plpgsql security definer set search_path = public
as $$
declare v_user uuid := auth.uid(); v_count integer := 0; v_row record;
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  for v_row in
    select id, status from public.practice_sessions
    where user_id=v_user and status in ('starting','active')
      and created_at < now() - interval '11 minutes'
    for update
  loop
    update public.practice_sessions
      set status=case when v_row.status='starting' then 'cancelled' else 'ended' end,
          ended_at=now()
      where id=v_row.id;
    v_count := v_count + 1;
  end loop;
  return v_count;
end;
$$;

create or replace function public.reserve_practice_session(
  p_scenario_id text, p_mode text, p_provider text, p_context text default ''
) returns public.practice_sessions
language plpgsql security definer set search_path = public
as $$
declare
  v_user uuid := auth.uid(); v_session public.practice_sessions;
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  perform public.expire_stale_practice_sessions();
  if exists(select 1 from public.practice_sessions where user_id=v_user and status in ('starting','active')) then
    raise exception 'An earlier rehearsal is still open';
  end if;
  if p_mode not in ('text','audio','video') then raise exception 'Unknown practice mode'; end if;
  if p_provider not in ('gemini_text','gemini_live','tavus') then raise exception 'Unknown provider'; end if;
  insert into public.practice_sessions(user_id,scenario_id,mode,provider,status,credit_cost,context)
    values(v_user,nullif(p_scenario_id,''),p_mode,p_provider,'starting',0,left(coalesce(p_context,''),6000))
    returning * into v_session;
  return v_session;
end;
$$;

create or replace function public.cancel_unconnected_practice_session(p_session_id uuid)
returns boolean language plpgsql security definer set search_path = public
as $$
declare v_user uuid := auth.uid();
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  update public.practice_sessions set status='cancelled', ended_at=now()
    where id=p_session_id and user_id=v_user and status='starting';
  return found;
end;
$$;

create or replace function public.end_practice_session(p_session_id uuid)
returns text language plpgsql security definer set search_path=public
as $$
declare v_status text;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  select status into v_status from public.practice_sessions
    where id=p_session_id and user_id=auth.uid() for update;
  if v_status is null then raise exception 'Session not found'; end if;
  if v_status='starting' then
    update public.practice_sessions set status='cancelled',ended_at=now()
      where id=p_session_id and user_id=auth.uid() and status='starting';
  elsif v_status='active' then
    update public.practice_sessions set status='ended',ended_at=now()
      where id=p_session_id and user_id=auth.uid();
  end if;
  return coalesce((select status from public.practice_sessions where id=p_session_id),v_status);
end;
$$;

create or replace function public.apply_credit_event(
  p_user_id uuid,p_event_id text,p_amount integer,p_reason text
) returns integer language plpgsql security definer set search_path = public
as $$
begin
  raise exception 'Credit events are no longer supported';
end;
$$;

revoke all on function public.expire_stale_practice_sessions() from public,anon;
revoke all on function public.reserve_practice_session(text,text,text,text) from public,anon;
revoke all on function public.cancel_unconnected_practice_session(uuid) from public,anon;
revoke all on function public.end_practice_session(uuid) from public,anon;
revoke all on function public.apply_credit_event(uuid,text,integer,text) from public,anon,authenticated;
grant execute on function public.expire_stale_practice_sessions() to authenticated;
grant execute on function public.reserve_practice_session(text,text,text,text) to authenticated;
grant execute on function public.cancel_unconnected_practice_session(uuid) to authenticated;
grant execute on function public.end_practice_session(uuid) to authenticated;
grant execute on function public.apply_credit_event(uuid,text,integer,text) to service_role;

commit;
