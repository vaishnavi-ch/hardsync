-- "Drills Done" (profile_screen.dart) counts rows in session_attempts, which
-- the client wrote via a direct .upsert(). 20260925120000_secure_billing_fields
-- correctly revoked UPDATE on session_attempts from authenticated (billing/score
-- fields are server-owned), but Postgres requires UPDATE privilege for the
-- ON CONFLICT DO UPDATE branch of an upsert even when no row actually
-- conflicts -- so every single upsert has been failing with permission
-- denied since that migration, for every session, not just custom ones.
--
-- This RPC replaces the raw upsert: it runs as security definer (like
-- reserve_practice_session and save_practice_report already do), so it's
-- unaffected by the caller's revoked table grants. It also tolerates a
-- scenario_id that doesn't exist in public.scenarios (true for every custom
-- scenario, which is generated client-side and never inserted into that
-- table) by storing NULL instead of failing the whole insert.
create or replace function public.record_practice_attempt(
  p_session_id uuid,
  p_scenario_id text,
  p_duration_seconds integer,
  p_overall_score integer,
  p_clarity_score integer,
  p_boundary_score integer,
  p_composure_score integer,
  p_empathy_score integer,
  p_executive_tier text,
  p_report jsonb
) returns void
language plpgsql security definer set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_scenario_id text := null;
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  if p_scenario_id is not null and exists(select 1 from public.scenarios where id = p_scenario_id) then
    v_scenario_id := p_scenario_id;
  end if;
  insert into public.session_attempts(
    id, user_id, scenario_id, duration_seconds, overall_score, clarity_score,
    boundary_score, composure_score, empathy_score, executive_tier, report
  ) values (
    p_session_id, v_user, v_scenario_id, greatest(0, coalesce(p_duration_seconds, 0)),
    p_overall_score, p_clarity_score, p_boundary_score, p_composure_score,
    p_empathy_score, p_executive_tier, p_report
  )
  on conflict (id) do update set
    duration_seconds = excluded.duration_seconds,
    overall_score = excluded.overall_score,
    clarity_score = excluded.clarity_score,
    boundary_score = excluded.boundary_score,
    composure_score = excluded.composure_score,
    empathy_score = excluded.empathy_score,
    executive_tier = excluded.executive_tier,
    report = excluded.report
  where session_attempts.user_id = v_user;
end;
$$;

revoke all on function public.record_practice_attempt(
  uuid, text, integer, integer, integer, integer, integer, integer, text, jsonb
) from public, anon;
grant execute on function public.record_practice_attempt(
  uuid, text, integer, integer, integer, integer, integer, integer, text, jsonb
) to authenticated;
