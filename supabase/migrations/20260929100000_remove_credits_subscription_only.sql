begin;

-- Credits are gone: audio needs an active Pro/Ultra subscription and video
-- needs Ultra (both enforced server-side against RevenueCat entitlements in
-- server/app.py). Sessions are no longer metered -- rate_per_minute stays 0 so
-- charge_practice_session_usage is a no-op -- but every audio/video session is
-- hard-capped at 10 minutes. Text sessions have no time limit.
-- The profiles.credits column and credit_ledger table are left in place
-- (historical data), they are just no longer read or written.

create or replace function public.reserve_practice_session(
  p_scenario_id text, p_mode text, p_provider text,
  p_context text default '', p_voice_name text default '', p_avatar_name text default ''
) returns public.practice_sessions
language plpgsql security definer set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_session public.practice_sessions;
  v_max_seconds integer;
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  perform public.expire_stale_practice_sessions();
  if exists(select 1 from public.practice_sessions where user_id=v_user and status in ('starting','active')) then
    raise exception 'An earlier rehearsal is still open';
  end if;
  if p_mode not in ('text','audio','video') then raise exception 'Unknown practice mode'; end if;
  if p_provider not in ('gemini_text','gemini_live','tavus') then raise exception 'Unknown provider'; end if;
  v_max_seconds := case when p_mode = 'text' then null else 600 end;
  insert into public.practice_sessions(
    user_id,scenario_id,mode,provider,status,credit_cost,context,voice_name,avatar_name,rate_per_minute,max_seconds)
    values(v_user,nullif(p_scenario_id,''),p_mode,p_provider,'starting',0,left(coalesce(p_context,''),6000),
           left(coalesce(p_voice_name,''),64), left(coalesce(p_avatar_name,''),64), 0, v_max_seconds)
    returning * into v_session;
  return v_session;
end;
$$;

drop function if exists public.apply_credit_event(uuid,text,integer,text);

commit;
