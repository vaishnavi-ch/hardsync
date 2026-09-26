-- Only editable profile fields may be changed by clients. Billing is server-owned.
BEGIN;
REVOKE ALL ON public.profiles FROM authenticated;
GRANT SELECT ON public.profiles TO authenticated;
GRANT UPDATE (full_name, avatar_url, leadership_role) ON public.profiles TO authenticated;

REVOKE ALL ON public.scenarios FROM authenticated;
GRANT SELECT, INSERT ON public.scenarios TO authenticated;
DROP POLICY IF EXISTS "Users can insert custom scenarios" ON public.scenarios;
CREATE POLICY "Users can insert custom scenarios" ON public.scenarios
FOR INSERT TO authenticated
WITH CHECK (is_custom = TRUE AND created_by = (SELECT auth.uid()));

REVOKE ALL ON public.session_attempts, public.transcripts FROM authenticated;
GRANT SELECT, INSERT ON public.session_attempts, public.transcripts TO authenticated;
COMMIT;
