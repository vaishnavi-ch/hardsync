begin;

alter table public.practice_sessions
  add column if not exists request_count integer not null default 0 check(request_count between 0 and 60),
  add column if not exists recording_metadata jsonb not null default '{}'::jsonb;
create table if not exists public.billing_events(
  event_id text primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  source text not null,
  requested_amount integer not null,
  applied_amount integer not null,
  created_at timestamptz not null default now()
);
alter table public.billing_events enable row level security;

-- Runtime mutations remain behind authenticated functions. The Flutter client
-- and stateless API never receive broad write access to billing or sessions.
create or replace function public.expire_stale_practice_sessions()
returns integer language plpgsql security definer set search_path = public
as $$
declare v_user uuid := auth.uid(); v_count integer := 0; v_row record;
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  for v_row in
    select id, credit_cost, status from public.practice_sessions
    where user_id=v_user and status in ('starting','active')
      and created_at < now() - interval '11 minutes'
    for update
  loop
    if v_row.status='starting' then
      update public.profiles set credits=credits+v_row.credit_cost where id=v_user;
      insert into public.credit_ledger(user_id,amount,reason,session_id)
        values(v_user,v_row.credit_cost,'expired_reservation_refund',v_row.id);
    end if;
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
  v_user uuid := auth.uid(); v_cost integer; v_session public.practice_sessions;
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  perform public.expire_stale_practice_sessions();
  if exists(select 1 from public.practice_sessions where user_id=v_user and status in ('starting','active')) then
    raise exception 'An earlier rehearsal is still open';
  end if;
  v_cost := case p_mode when 'text' then 5 when 'audio' then 15 when 'video' then 30 else null end;
  if v_cost is null then raise exception 'Unknown practice mode'; end if;
  if p_provider not in ('gemini_text','gemini_live','tavus') then raise exception 'Unknown provider'; end if;
  update public.profiles set credits=credits-v_cost where id=v_user and credits>=v_cost;
  if not found then raise exception 'Insufficient credits'; end if;
  insert into public.practice_sessions(user_id,scenario_id,mode,provider,status,credit_cost,context)
    values(v_user,nullif(p_scenario_id,''),p_mode,p_provider,'starting',v_cost,left(coalesce(p_context,''),6000))
    returning * into v_session;
  insert into public.credit_ledger(user_id,amount,reason,session_id)
    values(v_user,-v_cost,'practice_reservation',v_session.id);
  return v_session;
end;
$$;

create or replace function public.connect_practice_session(p_session_id uuid, p_provider_session_id text default null)
returns boolean language plpgsql security definer set search_path=public
as $$
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  update public.practice_sessions set status='active', provider_session_id=coalesce(nullif(p_provider_session_id,''),provider_session_id)
    where id=p_session_id and user_id=auth.uid() and status='starting';
  if found then return true; end if;
  return exists(select 1 from public.practice_sessions where id=p_session_id and user_id=auth.uid() and status='active');
end;
$$;

create or replace function public.end_practice_session(p_session_id uuid)
returns text language plpgsql security definer set search_path=public
as $$
declare v_status text;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  select status into v_status from public.practice_sessions where id=p_session_id and user_id=auth.uid() for update;
  if v_status is null then raise exception 'Session not found'; end if;
  if v_status='starting' then perform public.refund_unconnected_practice_session(p_session_id);
  elsif v_status='active' then update public.practice_sessions set status='ended',ended_at=now() where id=p_session_id;
  end if;
  return coalesce((select status from public.practice_sessions where id=p_session_id),v_status);
end;
$$;

create or replace function public.consume_practice_generation(p_session_id uuid)
returns integer language plpgsql security definer set search_path=public
as $$
declare v_count integer;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  update public.practice_sessions set request_count=request_count+1
    where id=p_session_id and user_id=auth.uid() and status='active' and mode='text' and request_count<60
    returning request_count into v_count;
  if v_count is null then raise exception 'Session generation limit reached'; end if;
  return v_count;
end;
$$;

create or replace function public.save_practice_report(p_session_id uuid,p_report jsonb,p_turns jsonb)
returns boolean language plpgsql security definer set search_path=public
as $$
declare v_existing jsonb;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  select report into v_existing from public.practice_sessions
    where id=p_session_id and user_id=auth.uid() and status in ('ended','cancelled') for update;
  if not found then raise exception 'End the session before saving its report'; end if;
  if v_existing is not null and v_existing->'transcript' is distinct from p_report->'transcript' then
    raise exception 'Saved transcript is immutable';
  end if;
  update public.practice_sessions set report=p_report where id=p_session_id;
  if v_existing is null then
    insert into public.practice_turns(session_id,turn_index,speaker,speaker_name,text,timestamp_ms)
    select p_session_id, n-1,
      case when coalesce(x->>'role','')='user' or coalesce(x->>'speaker','')='You' then 'user' else 'persona' end,
      coalesce(nullif(x->>'speaker',''),case when coalesce(x->>'role','')='user' then 'You' else 'Persona' end),
      x->>'text', greatest(0,coalesce((x->>'seconds')::numeric,0)*1000)::integer
    from jsonb_array_elements(p_turns) with ordinality as t(x,n);
  end if;
  return true;
end;
$$;

create or replace function public.save_practice_analysis(p_session_id uuid,p_analysis jsonb)
returns boolean language plpgsql security definer set search_path=public
as $$
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  update public.practice_sessions set analysis=p_analysis where id=p_session_id and user_id=auth.uid();
  if not found then raise exception 'Session not found'; end if;
  return true;
end;
$$;

create or replace function public.save_recording_metadata(p_session_id uuid,p_object_key text,p_metadata jsonb)
returns boolean language plpgsql security definer set search_path=public
as $$
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  update public.practice_sessions
    set recording_object_key=nullif(p_object_key,''), recording_metadata=coalesce(p_metadata,'{}'::jsonb)
    where id=p_session_id and user_id=auth.uid();
  if not found then raise exception 'Session not found'; end if;
  return true;
end;
$$;

create or replace function public.apply_credit_event(
  p_user_id uuid,p_event_id text,p_amount integer,p_reason text
) returns integer language plpgsql security definer set search_path=public
as $$
declare v_balance integer; v_old integer;
begin
  if auth.role() <> 'service_role' then raise exception 'Service role required'; end if;
  if p_amount=0 or abs(p_amount)>100000 or length(p_event_id)>255 then raise exception 'Invalid credit event'; end if;
  if exists(select 1 from public.billing_events where event_id=p_event_id) then
    return (select credits from public.profiles where id=p_user_id);
  end if;
  select credits into v_old from public.profiles where id=p_user_id for update;
  if v_old is null then raise exception 'Profile not found'; end if;
  update public.profiles set credits=greatest(0,v_old+p_amount) where id=p_user_id returning credits into v_balance;
  insert into public.billing_events(event_id,user_id,source,requested_amount,applied_amount)
    values(p_event_id,p_user_id,p_reason,p_amount,v_balance-v_old);
  if v_balance <> v_old then
    insert into public.credit_ledger(user_id,amount,reason,external_event_id)
      values(p_user_id,v_balance-v_old,p_reason,p_event_id);
  end if;
  return v_balance;
end;
$$;

grant update (full_name,avatar_url,leadership_role,onboarding_completed,selected_goal_ids,selected_user_persona_id,settings)
  on public.profiles to authenticated;

revoke all on function public.expire_stale_practice_sessions() from public,anon;
revoke all on function public.connect_practice_session(uuid,text) from public,anon;
revoke all on function public.end_practice_session(uuid) from public,anon;
revoke all on function public.consume_practice_generation(uuid) from public,anon;
revoke all on function public.save_practice_report(uuid,jsonb,jsonb) from public,anon;
revoke all on function public.save_practice_analysis(uuid,jsonb) from public,anon;
revoke all on function public.save_recording_metadata(uuid,text,jsonb) from public,anon;
revoke all on function public.apply_credit_event(uuid,text,integer,text) from public,anon,authenticated;
grant execute on function public.expire_stale_practice_sessions() to authenticated;
grant execute on function public.connect_practice_session(uuid,text) to authenticated;
grant execute on function public.end_practice_session(uuid) to authenticated;
grant execute on function public.consume_practice_generation(uuid) to authenticated;
grant execute on function public.save_practice_report(uuid,jsonb,jsonb) to authenticated;
grant execute on function public.save_practice_analysis(uuid,jsonb) to authenticated;
grant execute on function public.save_recording_metadata(uuid,text,jsonb) to authenticated;
grant execute on function public.apply_credit_event(uuid,text,integer,text) to service_role;

commit;
