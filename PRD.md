# HardSync product requirements document

**Status:** Working PRD synthesized from the repository on 2026-09-24. Product intent and planned requirements are separated from current implementation. This document does not imply that roadmap items are implemented or deployed.

## 1. Product overview

HardSync helps leaders practice difficult workplace conversations in a private environment before having them in real life. It combines scenario-based rehearsal, configurable counterpart personas, text/audio/video interaction, and a practical review of the user's recorded dialogue.

## 2. Problem statement

Managers and executives often have limited opportunities to rehearse sensitive conversations. Anxiety, unclear boundaries, and unstructured feedback can make conversations harder for both parties. HardSync gives users a repeatable practice flow and helps them reflect on what they actually said.

## 3. Target users

- New managers moving from peer to manager.
- Engineering/product leaders negotiating priorities and deadlines.
- People managers delivering corrective or developmental feedback.
- Senior leaders pushing back on unrealistic requests or negotiating across teams.

## 4. Product principles

- Practice should feel private and low-stakes.
- Feedback should be grounded in the saved transcript or actual recording.
- Missing evidence should produce an explicit limitation, never an invented observation.
- Users control microphone/camera activation and understand when recording begins.
- Session, subscription, and playback access must be checked by trusted server-side logic.
- Coaching should encourage clear, empathetic, actionable communication using C.A.R.E.: Connect, Ask, Recognize, Empower.

## 5. User stories and acceptance criteria

### A. Account access

As a user, I want to sign in so my sessions can be associated with my account.

- Email/password and configured OAuth sign-in succeed only with a valid Supabase session.
- Auth failure is shown as failure; it does not silently create a fake signed-in state.
- Sign-out clears the active authenticated session and refreshes account-bound state.

### B. Select or create a scenario

As a leader, I want to choose a relevant situation or describe my own.

- Scenario cards expose context, difficulty, counterpart, objectives, and phrases to avoid.
- Custom scenario creation validates required context and provides a chosen counterpart/objectives.
- A custom scenario can be associated with a saved session without violating the scenario foreign key or ownership policy.

### C. Prepare a rehearsal

As a user, I want to select my role, counterpart, and mode before starting.

- Selected counterpart and user role persist into the server prompt and transcript labels.
- The selected mode's subscription entitlement requirements are enforced by the server.
- Missing entitlement, provider setup failure, and an existing active call have clear recovery messages.
- Starting a session atomically reserves the session slot; failed unconnected starts release it once.

### D. Practice a conversation

As a user, I want to respond naturally and experience a relevant counterpart response.

- Text mode offers a working text entry and send action.
- Audio/video mode connects to the configured real provider and only reports connected after provider confirmation.
- Microphone mute and camera controls reflect the provider's actual state.
- The transcript reflects verified user and counterpart utterances, with appropriate timestamps.
- Camera and microphone remain off until user activation; recording requires clear user action.
- End/leave finalizes the session and prevents late async callbacks from reopening it.

### E. Review a session

As a user, I want to revisit what happened and identify a useful next step.

- The user can find their own saved sessions from a real history list.
- Transcript turns link to correct timestamps where media exists.
- Recording playback is private, owner-scoped, seekable when media supports it, and unavailable states are honest.
- Analysis quotes match saved user turns and timestamps stay inside the recording duration.
- Analysis distinguishes transcript evidence from audio/video observations and discloses missing devices/evidence.
- Numeric scores are shown only after a validated, supported scoring method exists.

### F. Account and monetization

As a user, I want accurate plan access.

- Subscription tier comes from trusted server/verified provider state, not local editable preferences.
- Subscription access is granted only after verified provider transactions.
- Restore purchases reconciles the actual entitlement, including the correct tier.
- If commerce is unavailable, UI presents that state and does not claim purchase success.

## 6. Functional scope

### MVP / currently represented in source

- Flutter cross-platform app shell, onboarding, scenario catalog and custom scenario UI.
- Scenario preparation and text/audio/video mode selection.
- Python local API for identity validation, provider session creation, session reservation and state.
- Tavus/Daily integration path for browser audio/video.
- Browser recording, private local upload, report/transcript review, and media playback path.
- Supabase auth/schema/session persistence path.
- Gemini-backed analysis path with server-side evidence checks.

Implementation caveats are detailed in [DOCUMENTATION.md](DOCUMENTATION.md) and [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md). Code availability is not equivalent to production readiness.

### Not currently available / future scope

- Production-hosted backend and cloud recording storage/retention.
- Verified subscription billing.
- Numerically scored leadership performance assessment.
- Fully validated physical-device audio/video controls across supported browsers and native platforms.
- Production migration deployment and verified Supabase policy behavior.
- Product analytics and validated progress measurement.

## 7. Nonfunctional requirements

### Security and privacy

- Provider secrets remain on server; client receives only public settings and short-lived/session-scoped access.
- All session/media/report routes enforce authenticated ownership.
- Uploads validate content type, size, ordering/offset, and session state.
- Playback access expires and can be refreshed only by the owner.
- Retention, deletion, and backup behavior must be explicit before production launch.
- Review all SQL grants and RLS policies together, not as isolated migrations.

### Reliability

- Idempotent end and cancellation operations.
- Recover abandoned reservations and sessions without charging indefinitely.
- Make provider/recording/analysis errors recoverable where possible.
- Never fabricate successful sessions, recordings, purchases, score values, or user activity.

### Accessibility and usability

- Clear focus and touch targets; keyboard-accessible web interaction.
- Responsive layouts for phone, tablet, and desktop.
- Captions/transcript availability for audio/video practice.
- Respect reduced-motion and platform permission conventions.

## 8. Data and integrations

- Supabase: identity and planned cloud profile/scenario/session/transcript records.
- Local Python service: current session authority and SQLite-backed local account/session/media state.
- Tavus/Daily: counterpart conversation and WebRTC media.
- Gemini: dialogue generation and/or evidence-grounded analysis.
- RevenueCat: entitlement lookup integration; commerce fulfillment is not currently available.
- Cloudflare R2: referenced in code/schema naming, but not the active storage described by current local server docs.

The coexistence of Supabase and local SQLite creates two persistence boundaries. Before production, define one authoritative data model and a clear synchronization/retention contract.

## 9. Success metrics (proposed)

- Activation: percent of new users who complete a first rehearsal.
- Practice: sessions per active user, repeat rehearsal rate, and return interval.
- User outcome: self-reported readiness/confidence before and after practice.
- Quality: provider start success, valid transcript coverage, recording finalization success, and analysis evidence validation.
- Trust: purchase reconciliation errors, unauthorized access incidents, and misleading/unsubstantiated feedback incidents.

Do not treat model-generated score changes as outcome evidence without validation and user research.

## 10. Release gates

1. Choose and document production hosting and authoritative session storage and subscription entitlement state.
2. Review SQL grants/RLS; apply migrations to a staging Supabase project and test ownership/role behavior.
3. Configure and verify provider identity mapping, entitlements, callback URLs, and key rotation.
4. Implement and verify advertised subscription purchase flows.
5. Complete device/browser permission, mute, camera, recording, and interruption testing.
6. Test deletion/retention, backup/restore, and private playback access.
7. Run Flutter analysis/tests, Python tests, web build, and end-to-end staging scenarios; record actual results and date.
8. Remove or label sample/static progress content so the shipped interface cannot imply activity that did not occur.

## 11. Open product decisions

- Which platforms are launch targets: web only, iOS/Android, or all Flutter targets?
- Should user history and media be local-first or cloud-synced? What retention and deletion controls are required?
- Which plans and entitlements will launch, and what verified purchase flow fulfills them?
- Is AI feedback transcript-only at launch, or should actual audio/video analysis be required?
- What scenario authoring and sharing permissions are needed for custom scenarios?
- Which user-reported outcome measures should define practice progress?
