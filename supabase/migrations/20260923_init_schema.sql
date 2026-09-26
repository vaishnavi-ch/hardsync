-- ==============================================================================
-- HardSync â€” Production PostgreSQL Schema for Supabase
-- Core tables: profiles, scenarios, session_attempts, transcripts
-- Validated against official Supabase & Postgres Best Practices
-- ==============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. PROFILES (Extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    full_name TEXT,
    avatar_url TEXT,
    leadership_role TEXT DEFAULT 'Engineering Leader',
    streak_count INT DEFAULT 1,
    is_pro_subscriber BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. SCENARIOS (Default and Custom User Scenarios)
CREATE TABLE IF NOT EXISTS public.scenarios (
    id TEXT PRIMARY KEY,
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    subtitle TEXT,
    category TEXT NOT NULL,
    difficulty TEXT NOT NULL,
    persona_id TEXT NOT NULL,
    context_brief TEXT NOT NULL,
    user_objectives JSONB DEFAULT '[]'::jsonb,
    trap_phrases_to_avoid JSONB DEFAULT '[]'::jsonb,
    is_custom BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. SESSION ATTEMPTS (Flight Simulator Rehearsal Attempts & Scores)
CREATE TABLE IF NOT EXISTS public.session_attempts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    scenario_id TEXT REFERENCES public.scenarios(id) ON DELETE SET NULL,
    duration_seconds INT NOT NULL,
    overall_score INT NOT NULL,
    clarity_score INT NOT NULL,
    boundary_score INT NOT NULL,
    composure_score INT NOT NULL,
    empathy_score INT NOT NULL,
    executive_tier TEXT NOT NULL,
    recording_r2_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 4. TRANSCRIPTS (Turn-by-Turn Dialogue and Heuristic Tags)
CREATE TABLE IF NOT EXISTS public.transcripts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID REFERENCES public.session_attempts(id) ON DELETE CASCADE NOT NULL,
    turn_index INT NOT NULL,
    speaker TEXT NOT NULL, -- 'user' or 'persona'
    speaker_name TEXT NOT NULL,
    text TEXT NOT NULL,
    timestamp_ms INT NOT NULL,
    tone_tag TEXT, -- 'Neutral', 'Clear', 'Firm Boundary', 'Defensive', 'Hedging'
    is_strong_boundary BOOLEAN DEFAULT FALSE,
    has_hedging BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ==============================================================================
-- PERFORMANCE INDEXES (Foreign Keys & RLS Subqueries)
-- ==============================================================================

CREATE INDEX IF NOT EXISTS idx_session_attempts_user_id ON public.session_attempts(user_id);
CREATE INDEX IF NOT EXISTS idx_session_attempts_scenario_id ON public.session_attempts(scenario_id);
CREATE INDEX IF NOT EXISTS idx_transcripts_session_id ON public.transcripts(session_id);
CREATE INDEX IF NOT EXISTS idx_scenarios_created_by ON public.scenarios(created_by);

-- ==============================================================================
-- EXPOSE TABLES TO DATA API (PostgREST)
-- ==============================================================================

GRANT ALL ON TABLE public.profiles, public.scenarios, public.session_attempts, public.transcripts TO authenticated;
GRANT SELECT ON TABLE public.scenarios TO anon;

-- ==============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scenarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.session_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transcripts ENABLE ROW LEVEL SECURITY;

-- Profiles: Users can view and update their own profile
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile" 
ON public.profiles FOR SELECT 
TO authenticated
USING ((select auth.uid()) = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" 
ON public.profiles FOR UPDATE 
TO authenticated
USING ((select auth.uid()) = id)
WITH CHECK ((select auth.uid()) = id);

-- Scenarios: Default scenarios are viewable by all; custom scenarios by creator
DROP POLICY IF EXISTS "Public scenarios are viewable by all authenticated users" ON public.scenarios;
DROP POLICY IF EXISTS "Default scenarios are viewable by all" ON public.scenarios;
CREATE POLICY "Default scenarios are viewable by all" 
ON public.scenarios FOR SELECT 
TO anon, authenticated 
USING (is_custom = FALSE);

DROP POLICY IF EXISTS "Users can view own custom scenarios" ON public.scenarios;
CREATE POLICY "Users can view own custom scenarios" 
ON public.scenarios FOR SELECT 
TO authenticated 
USING (is_custom = TRUE AND created_by = (select auth.uid()));

DROP POLICY IF EXISTS "Users can insert custom scenarios" ON public.scenarios;
CREATE POLICY "Users can insert custom scenarios" 
ON public.scenarios FOR INSERT 
TO authenticated 
WITH CHECK (created_by = (select auth.uid()));

-- Session Attempts: Users can select and insert their own attempts
DROP POLICY IF EXISTS "Users can view own session attempts" ON public.session_attempts;
CREATE POLICY "Users can view own session attempts" 
ON public.session_attempts FOR SELECT 
TO authenticated
USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can insert own session attempts" ON public.session_attempts;
CREATE POLICY "Users can insert own session attempts" 
ON public.session_attempts FOR INSERT 
TO authenticated
WITH CHECK ((select auth.uid()) = user_id);

-- Transcripts: Users can view and insert transcripts for their sessions
DROP POLICY IF EXISTS "Users can view transcripts of their sessions" ON public.transcripts;
CREATE POLICY "Users can view transcripts of their sessions" 
ON public.transcripts FOR SELECT 
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.session_attempts 
        WHERE public.session_attempts.id = public.transcripts.session_id 
        AND public.session_attempts.user_id = (select auth.uid())
    )
);

DROP POLICY IF EXISTS "Users can insert transcripts for their sessions" ON public.transcripts;
CREATE POLICY "Users can insert transcripts for their sessions" 
ON public.transcripts FOR INSERT 
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.session_attempts 
        WHERE public.session_attempts.id = public.transcripts.session_id 
        AND public.session_attempts.user_id = (select auth.uid())
    )
);

-- ==============================================================================
-- AUTOMATIC PROFILE CREATION TRIGGER (Secured with explicit search_path)
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name, avatar_url)
    VALUES (
        new.id,
        new.email,
        coalesce(new.raw_user_meta_data->>'full_name', 'Executive Trainee'),
        coalesce(new.raw_user_meta_data->>'avatar_url', '')
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN new;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- ==============================================================================
-- DEFAULT SEED SCENARIOS
-- ==============================================================================

INSERT INTO public.scenarios (
    id,
    title,
    subtitle,
    category,
    difficulty,
    persona_id,
    context_brief,
    user_objectives,
    trap_phrases_to_avoid,
    is_custom
) VALUES 
(
    'scenario_managing_former_peer',
    'Managing Former Peer',
    'Holding Deadlines Under Emotional Guilt',
    'Peer Transition',
    'High Stakes',
    'alex',
    'You were promoted to Engineering Lead two months ago. Alex, who was formerly your equal peer and close friend on the team, is resisting the sprint deadline for the payments migration. He uses casual familiarity ("Come on, you know me") and accuses you of micromanaging to evade accountability.',
    '["Acknowledge his engineering perspective without conceding the deadline.", "State the business impact clearly without apologizing or hedging.", "Agree on a concrete mitigation plan before ending the call."]'::jsonb,
    '["I''m sorry to have to ask you this...", "I just feel like maybe we should...", "I know you hate this, but management is making me..."]'::jsonb,
    FALSE
),
(
    'scenario_boundary_fortress',
    'The Boundary Fortress',
    'Pushing Back on Urgent Upward Demands',
    'Upward Management',
    'Executive Crucible',
    'jordan',
    'It is Friday at 4:30 PM. VP Jordan has just called requiring a surprise 20-page analytics deck for Monday morning''s board review. Your team has been operating at redline capacity. You must defend team burnout boundaries without appearing uncommitted.',
    '["Validate Jordan''s urgency before stating current squad bandwidth.", "Hold the boundary against weekend emergency work.", "Offer an executive trade-off: a focused 2-page summary Monday, full deck Wednesday."]'::jsonb,
    '["We can''t do this, my team will quit.", "I guess we could try to work over the weekend...", "Why is this always our responsibility?"]'::jsonb,
    FALSE
),
(
    'scenario_radical_candor',
    'The Radical Candor Loop',
    'Corrective Feedback with Psychological Safety',
    'Direct Reports',
    'High Stakes',
    'marcus',
    'Marcus is a gifted junior engineer who becomes defensive and shut down during code reviews. His recent blunt comments in PRs caused friction with other contributors. Deliver direct corrective feedback with compassion without diluting the core message.',
    '["Cite specific PR comment examples rather than vague character judgments.", "Explain the cultural impact on team trust.", "Establish a two-way support cadence for professional growth."]'::jsonb,
    '["Everyone says you are being difficult.", "It''s not really a big deal, but...", "You just need to calm down in Slack."]'::jsonb,
    FALSE
),
(
    'scenario_cross_team_alignment',
    'Cross-Team Alignment',
    'Breaking Deadlocks with Diplomatic Influence',
    'Negotiations',
    'Foundational',
    'priya',
    'Marketing Lead Priya is refusing to release dedicated frontend bandwidth for critical authentication security updates because of an upcoming ad campaign. Negotiate a compromise that protects security compliance while maintaining launch continuity.',
    '["Demonstrate understanding of her campaign revenue goals.", "Frame security compliance as a shared business risk.", "Secure partial engineering commitment or phased rollout."]'::jsonb,
    '["Security always trumps marketing.", "You have to give us what we want.", "We''ll just escalate this to the CTO."]'::jsonb,
    FALSE
)
ON CONFLICT (id) DO UPDATE SET
    title = EXCLUDED.title,
    subtitle = EXCLUDED.subtitle,
    category = EXCLUDED.category,
    difficulty = EXCLUDED.difficulty,
    persona_id = EXCLUDED.persona_id,
    context_brief = EXCLUDED.context_brief,
    user_objectives = EXCLUDED.user_objectives,
    trap_phrases_to_avoid = EXCLUDED.trap_phrases_to_avoid;
