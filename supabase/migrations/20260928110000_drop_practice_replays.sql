begin;

-- The opt-in call-recording feature (practice_replays) is removed: nothing
-- in the app or backend calls these functions or reads this table anymore.

drop function if exists public.expire_stale_practice_replays();
drop function if exists public.save_practice_replay(uuid, text, text, integer);
drop table if exists public.practice_replays;

commit;
