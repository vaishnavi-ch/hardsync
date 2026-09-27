begin;

-- Reintroduce credits, this time metered by actual call duration instead of a
-- flat per-session charge. Text stays free. Audio costs 1 credit/minute and
-- video costs 6 credits/minute, matching the pricing shown in the app. A
-- session reserves nothing up front beyond an affordability check; the real
-- charge is computed from elapsed time when the session ends (or expires),
-- capped at what the user could afford when they started so a session never
-- overdraws past the balance that was available at reservation time.

alter table public.practice_sessions
  add column if not exists rate_per_minute integer not null default 0,
  add column if not exists max_seconds integer;

alter table public.profiles alter column credits set default 10;

create or replace function public.charge_practice_session_usage(p_session_id uuid, p_user_id uuid)
returns integer language plpgsql security definer set search_path = public
as $$
declare
  v_row public.practice_sessions;
  v_elapsed_minutes integer;
  v_cap_minutes integer;
  v_charge_minutes integer;
  v_cost integer;
  v_old_credits integer;
  v_new_credits integer;
  v_actual_cost integer := 0;
begin
  select * into v_row from public.practice_sessions
    where id = p_session_id and user_id = p_user_id for update;
  if v_row.id is null or v_row.status <> 'active' or v_row.rate_per_minute <= 0 then
    return 0;
  end if;
  v_elapsed_minutes := greatest(1, ceil(extract(epoch from (now() - v_row.created_at)) / 60.0)::integer);
  v_cap_minutes := case when v_row.max_seconds is null then v_elapsed_minutes
                        else greatest(1, v_row.max_seconds / 60) end;
  v_charge_minutes := least(v_elapsed_minutes, v_cap_minutes);
  v_cost := v_charge_minutes * v_row.rate_per_minute;
  if v_cost > 0 then
    select credits into v_old_credits from public.profiles where id = p_user_id for update;
    update public.profiles set credits = greatest(0, v_old_credits - v_cost)
      where id = p_user_id returning credits into v_new_credits;
    v_actual_cost := v_old_credits - v_new_credits;
    if v_actual_cost > 0 then
      insert into public.credit_ledger(user_id, amount, reason, session_id)
        values(p_user_id, -v_actual_cost, 'practice_usage', p_session_id);
    end if;
  end if;
  update public.practice_sessions set credit_cost = v_actual_cost where id = p_session_id;
  return v_actual_cost;
end;
$$;
revoke all on function public.charge_practice_session_usage(uuid,uuid) from public, anon, authenticated;

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
    if v_row.status = 'active' then
      perform public.charge_practice_session_usage(v_row.id, v_user);
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
  p_scenario_id text, p_mode text, p_provider text,
  p_context text default '', p_voice_name text default '', p_avatar_name text default ''
) returns public.practice_sessions
language plpgsql security definer set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_session public.practice_sessions;
  v_rate integer;
  v_balance integer;
  v_max_seconds integer;
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  perform public.expire_stale_practice_sessions();
  if exists(select 1 from public.practice_sessions where user_id=v_user and status in ('starting','active')) then
    raise exception 'An earlier rehearsal is still open';
  end if;
  if p_mode not in ('text','audio','video') then raise exception 'Unknown practice mode'; end if;
  if p_provider not in ('gemini_text','gemini_live','tavus') then raise exception 'Unknown provider'; end if;
  v_rate := case p_mode when 'text' then 0 when 'audio' then 1 when 'video' then 6 else 0 end;
  if v_rate > 0 then
    select credits into v_balance from public.profiles where id=v_user for update;
    if v_balance is null or v_balance < v_rate then
      raise exception 'Insufficient credits';
    end if;
    -- Hard ceiling of 45 minutes per rehearsal regardless of balance, so one
    -- session can't run unbounded even with a very large credit balance.
    v_max_seconds := least(v_balance / v_rate, 45) * 60;
  else
    v_max_seconds := null;
  end if;
  insert into public.practice_sessions(
    user_id,scenario_id,mode,provider,status,credit_cost,context,voice_name,avatar_name,rate_per_minute,max_seconds)
    values(v_user,nullif(p_scenario_id,''),p_mode,p_provider,'starting',0,left(coalesce(p_context,''),6000),
           left(coalesce(p_voice_name,''),64), left(coalesce(p_avatar_name,''),64), v_rate, v_max_seconds)
    returning * into v_session;
  return v_session;
end;
$$;

create or replace function public.end_practice_session(p_session_id uuid)
returns text language plpgsql security definer set search_path=public
as $$
declare v_status text; v_user uuid := auth.uid();
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  select status into v_status from public.practice_sessions
    where id=p_session_id and user_id=v_user for update;
  if v_status is null then raise exception 'Session not found'; end if;
  if v_status='starting' then
    update public.practice_sessions set status='cancelled',ended_at=now()
      where id=p_session_id and user_id=v_user and status='starting';
  elsif v_status='active' then
    perform public.charge_practice_session_usage(p_session_id, v_user);
    update public.practice_sessions set status='ended',ended_at=now()
      where id=p_session_id and user_id=v_user;
  end if;
  return coalesce((select status from public.practice_sessions where id=p_session_id),v_status);
end;
$$;

-- Credits are back, so purchases/renewals need a way to grant them again.
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
revoke all on function public.apply_credit_event(uuid,text,integer,text) from public,anon,authenticated;
grant execute on function public.apply_credit_event(uuid,text,integer,text) to service_role;

commit;
