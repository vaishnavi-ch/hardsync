begin;

-- Gemini Live Avatar (video calls) needs a built-in avatar_name per persona,
-- the same way voice_name already carries the persona's Gemini voice.
alter table public.practice_sessions
  add column if not exists avatar_name text not null default '';

drop function if exists public.reserve_practice_session(text,text,text,text,text);

create or replace function public.reserve_practice_session(
  p_scenario_id text, p_mode text, p_provider text,
  p_context text default '', p_voice_name text default '', p_avatar_name text default ''
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
  insert into public.practice_sessions(user_id,scenario_id,mode,provider,status,credit_cost,context,voice_name,avatar_name)
    values(v_user,nullif(p_scenario_id,''),p_mode,p_provider,'starting',0,left(coalesce(p_context,''),6000),
           left(coalesce(p_voice_name,''),64), left(coalesce(p_avatar_name,''),64))
    returning * into v_session;
  return v_session;
end;
$$;

revoke all on function public.reserve_practice_session(text,text,text,text,text,text) from public,anon;
grant execute on function public.reserve_practice_session(text,text,text,text,text,text) to authenticated;

commit;
