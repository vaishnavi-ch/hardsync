-- Billing and credits are server-owned. This migration repairs the broad
-- grants introduced by 20260923143000_supabase_r2_cloud_storage.sql.
BEGIN;

REVOKE ALL ON public.profiles FROM authenticated;
GRANT SELECT ON public.profiles TO authenticated;
GRANT UPDATE (full_name, avatar_url, leadership_role) ON public.profiles TO authenticated;

REVOKE ALL ON public.session_attempts, public.transcripts FROM authenticated;
GRANT SELECT, INSERT ON public.session_attempts, public.transcripts TO authenticated;

COMMIT;
