# HardSync screen and state audit

Updated: 2026-09-25

This document translates the supplied mockups into the product state model. It
is a build checklist, not a mood board. A screen is complete only when its
loading, empty, active, completed, error, and locked states are represented as
appropriate.

## Global navigation

The signed-in shell has five persistent destinations: Home, Learn, Practice,
Progress, and Profile. Authentication, onboarding, paywall, focused lessons,
scenario setup, live calls, results, and destructive account flows hide the
global bar. Every destination retains its own scroll and selected state.

## Entry and account

Implemented: illustrated welcome, create account, sign in, password reset,
email sent, profile/account menu, logout confirmation, signed-out state,
delete confirmation, and account deleted.

Required states: idle, validating, submitting, provider redirect, invalid
credentials, offline/provider failure, reset sent, authenticated, guest,
logout pending, delete pending, delete failed, deleted.

## Subscription

Implemented: paywall introduction, monthly/yearly control, three existing plan
tiers, purchase processing, restore entry point, and active-plan treatment.

Required states: intro, billing period selected, plan selected, free plan,
purchase pending, purchase cancelled, purchase failed, entitlement restored,
active subscription, and expired subscription. The selected visual plan must
never grant backend access before the entitlement succeeds.

## Home

Implemented: dedicated dashboard, personalized greeting, progress hero,
current path, streak/lesson/time metrics, continue-learning card, recommended
practice card, and encouragement banner.

Remaining data states: first-day empty dashboard, partially completed path,
completed path, unread notification, offline cached progress, and backend load
failure. Replace sample metrics with account-scoped progress when that endpoint
is available.

## Learn

Implemented: four paths, nine courses, 45 authored lessons, course detail,
lesson content, contextual illustrations, and locally persisted completion.

Implemented staged lesson player:

1. Lesson introduction and outcome
2. Concept explanation
3. Key takeaways or framework
4. Worked example
5. Reflection or practice prompt
6. Knowledge check with selected/correct/incorrect states
7. Lesson completion and next lesson
8. Module completion, points, and next practice recommendation

The player now includes distinct Learn, Takeaways, Example, Reflect, Recap,
Check, and Complete states, including answer selection, correct/incorrect
feedback, retry, contextual illustrations, and persisted completion.

Remaining states: dedicated roadmap overview, locked path/module detail, saved
reflection sync, full course completion, level-up, and achievement unlock.

## Practice catalog and preparation

Implemented: scenario catalog with filters, scenario details, persona and user
role selection, text/audio/video modes, subscription and credit checks, and
custom-scenario input.

Required catalog states: all/category filter, search, recommended item, locked
premium item, no matches, loading, and backend failure.

Required custom scenario sequence:

1. Start from scratch, template, or AI description
2. Define situation and goal
3. Create or choose persona
4. Review scenario
5. Choose text, voice, or video mode
6. Configure coaching hints and analysis
7. Practice
8. Save to library or discard
9. Keep practicing, try another scenario, or return home

Implemented custom builder states: start method, situation and goal, persona,
review, and handoff to the existing mode/access/session preparation flow. The
entry is now visible in the Practice catalog.

Remaining states: saved drafts, AI generation failure, custom avatar editing,
save-to-library, and post-practice continuation.

## Live practice

Implemented: connecting/in-call/ending state machine, transcript display,
voice/video surfaces, mute/camera controls, provider embeds, and generated
debrief routing.

Required visual states: connecting, AI listening, AI speaking, user speaking,
muted, camera off, captions on, hint expanded, network degraded, reconnecting,
permission denied, provider failed, end-call confirmation, processing results,
and safely ended. Text practice also requires a working composer, quick prompts,
send, pause, and inline AI replies.

## Results and history

Implemented: detailed debrief, score cards, telemetry sections, key moments,
coaching blueprint, transcript, practice again, and replay entry.

Required result states: analysis processing, insufficient evidence, completed
analysis, positive/needs-work moments, moment detail and alternative phrasing,
save scenario, share achievement, level-up, and next recommended action.

Session history must use real account attempts with loading, empty, error, and
populated states. Canned replay content must not appear as user history.

## Progress

Implemented: dedicated Overview, Insights, and Badges tabs; learning journey;
skill bars; streak and achievement metrics; week/month/all-time switching; and
practice-history entry.

Remaining data states: no activity, partial data, earned/locked badge detail,
new badge celebration, level-up, comparison period, and backend failure.

## Profile

Implemented: permanent Profile navigation destination with signed-in and guest
variants, account menu, subscription entry, settings, help, logout, and delete.

Remaining states: editable identity, avatar selection, notification controls,
privacy/export controls, subscription status detail, and destructive-operation
errors.

## Visual acceptance rules

- Use the cream canvas, navy text, violet/lilac primary accents, apricot energy
  accents, and olive/sage growth accents sampled from the supplied assets.
- Use Newsreader for editorial display headings and Plus Jakarta Sans for UI.
- Use one dominant illustration per screen and smaller assets only when they
  explain a card, milestone, persona, or concept.
- Use Cupertino icons for navigation and universal controls. Use HardSync
  assets for branded concepts, achievements, course content, and personas.
- Use soft 18â€“28 px radii, thin tinted borders, restrained shadows, and generous
  white space. Avoid generic gradient cards, decorative glass effects, and
  repetitive icon tiles without information hierarchy.
- Keep primary actions at the bottom of focused flows and visible above the
  safe area. Use black for major gateway actions and violet for in-product
  progression actions.
