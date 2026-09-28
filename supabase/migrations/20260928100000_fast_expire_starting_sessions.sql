-- A session stuck in 'starting' (never connected -- app closed, network
-- failure, etc.) was only cleared after the same 11-minute window used for
-- 'active' calls, so closing the app right after starting a call blocked a
-- retry for up to 11 minutes. 'starting' sessions haven't consumed any
-- credits yet, so they're safe to expire fast; only 'active' calls (which
-- did connect and may legitimately still be running) keep the 11-minute
-- grace period.
create or replace function public.expire_stale_practice_sessions()
returns integer language plpgsql security definer set search_path = public
as $$
declare v_user uuid := auth.uid(); v_count integer := 0; v_row record;
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  for v_row in
    select id, status from public.practice_sessions
    where user_id=v_user and status in ('starting','active')
      and (
        (status = 'starting' and created_at < now() - interval '60 seconds')
        or (status = 'active' and created_at < now() - interval '11 minutes')
      )
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
