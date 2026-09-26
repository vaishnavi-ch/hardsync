begin;

-- Text practice stays in the credit ledger schema for compatibility, but it
-- costs nothing. Audio and video still reserve and refund credits as before.
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
    if v_row.status='starting' and v_row.credit_cost > 0 then
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
  v_cost := case p_mode when 'text' then 0 when 'audio' then 15 when 'video' then 30 else null end;
  if v_cost is null then raise exception 'Unknown practice mode'; end if;
  if p_provider not in ('gemini_text','gemini_live','tavus') then raise exception 'Unknown provider'; end if;
  if v_cost > 0 then
    update public.profiles set credits=credits-v_cost where id=v_user and credits>=v_cost;
    if not found then raise exception 'Insufficient credits'; end if;
  end if;
  insert into public.practice_sessions(user_id,scenario_id,mode,provider,status,credit_cost,context)
    values(v_user,nullif(p_scenario_id,''),p_mode,p_provider,'starting',v_cost,left(coalesce(p_context,''),6000))
    returning * into v_session;
  if v_cost > 0 then
    insert into public.credit_ledger(user_id,amount,reason,session_id)
      values(v_user,-v_cost,'practice_reservation',v_session.id);
  end if;
  return v_session;
end;
$$;

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
  if v_cost > 0 then
    update public.profiles set credits=credits+v_cost where id=v_user;
    insert into public.credit_ledger(user_id,amount,reason,session_id)
      values(v_user,v_cost,'practice_refund',p_session_id);
  end if;
  return true;
end;
$$;

commit;
