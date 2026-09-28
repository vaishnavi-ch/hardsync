-- Stores the Apple refresh token obtained from the native Sign in with Apple
-- authorization code exchange, so account deletion can revoke the grant per
-- App Store guideline 5.1.1(v). Service-role only: never exposed to clients.
BEGIN;

CREATE TABLE public.apple_oauth_tokens (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  refresh_token text NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.apple_oauth_tokens ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.apple_oauth_tokens FROM authenticated, anon;

COMMIT;
