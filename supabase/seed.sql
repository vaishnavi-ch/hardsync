-- ==============================================================================
-- HardSync â€” Seed Data for Scenarios
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
