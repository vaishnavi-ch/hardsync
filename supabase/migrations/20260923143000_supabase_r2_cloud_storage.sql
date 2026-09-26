-- ==============================================================================
-- HardSync â€” Supabase Cloud Storage & Cloudflare R2 Integration Migration
-- Stores Users, Sessions, Transcripts, Analysis, and R2 Recording Paths in Supabase
-- ==============================================================================

-- 1. Ensure credits column exists on profiles table in Supabase
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS credits INT DEFAULT 30;

-- 2. Add analysis and report JSONB columns to session_attempts in Supabase
ALTER TABLE public.session_attempts 
ADD COLUMN IF NOT EXISTS analysis JSONB DEFAULT '{}'::jsonb;

ALTER TABLE public.session_attempts 
ADD COLUMN IF NOT EXISTS report JSONB DEFAULT '{}'::jsonb;

-- 3. Ensure recording_r2_url is present on session_attempts
ALTER TABLE public.session_attempts 
ADD COLUMN IF NOT EXISTS recording_r2_url TEXT;

-- 4. Enable RLS and grants
GRANT ALL ON TABLE public.session_attempts TO authenticated;
GRANT ALL ON TABLE public.transcripts TO authenticated;
GRANT ALL ON TABLE public.profiles TO authenticated;
