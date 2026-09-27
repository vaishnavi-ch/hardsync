# HardSync project documentation

> Repository reference for product, engineering, and project planning. Written from the source and configuration in this repository on 2026-09-24. For externally verified behavior and known environment limitations, see [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md); for historic audit findings and fixes, see [CODEBASE_AUDIT.md](CODEBASE_AUDIT.md).

## What this repository is

HardSync is a cross-platform Flutter rehearsal app for practicing difficult workplace and leadership conversations. The main journey is: choose a built-in or custom scenario, select a counterpart and text/audio/video mode, rehearse, then review the transcript and available session analysis. The product's coaching framework is C.A.R.E. (Connect, Ask, Recognize, Empower).

This repository contains the Flutter client, a local Python HTTP server, Supabase SQL assets, web/native launch scaffolding, static design prototypes, and a large illustration/avatar/icon library. It is not a deployed hosted service. Treat the implementation-status notes as dated reports, not guarantees about the current remote services or a production environment.

## Product requirements (current product intent)

### Users and problem

- Primary users: new and experienced people managers, engineering leaders, directors, and executives.
- Need: rehearse sensitive or high-stakes conversations before having them with colleagues, reports, peers, or executives.
- Product promise: private practice with realistic workplace situations, followed by practical, evidence-grounded reflection.

### Main user flow

1. Sign in (Supabase email/password or configured OAuth provider).
2. Browse built-in scenarios or draft a custom scenario.
3. Choose the user's leadership role, counterpart, and rehearsal mode.
4. Start a server-created session; the server checks identity, entitlement and concurrent-session conflicts.
5. Rehearse by text, or join the configured Tavus/Daily audio/video session. Browser media recording is an explicit user action and devices default off.
6. End the session, finalize captured media when applicable, save available transcript/session data, and review the session.
7. Reopen saved sessions and inspect available insights, transcript, and recording.

### Functional requirements

- Present scenario catalog, objectives, counterpart personas, and custom scenario authoring.
- Support text, audio, and video modes subject to server-side plan/subscription rules.
- Keep a session's owner, state, and session reservation on the server; reject concurrent active sessions and release failed starts.
- Display session transcript and explicit recording/analysis states. Evidence-based analysis must cite saved dialogue and, if used, the actual recording.
- Keep camera/microphone off until user enables them; disclose capture through the join/record action.
- Support signed-in history and account settings, with clear error and unavailable states.

### Nonfunctional requirements

- Private provider credentials must remain server-side; browser API responses should not expose them.
- Enforce owner checks for session operations, uploads, analysis, and playback; validate upload sequence and signed playback expiry.
- Avoid asserting measurements that have not actually been collected. Numeric performance scoring is not currently available.
- Provide explicit failure/retry states for provider, recording, and analysis failures.
- Keep mobile and web UI accessible and responsive; use the project's warm, illustration-led visual language.

## Implementation status at a glance

â€œPresent in sourceâ€ describes code paths found in the repository. â€œReported verifiedâ€ refers to the dated project status notes and is not a new test run in this documentation task.

| Area | Present in source | Limitations / status |
|---|---|---|
| Flutter app and screens | Onboarding, scenario hub/custom scenario, prep, live call, debrief, session detail/replay, sign-in, settings, and subscription UI | Some screens communicate unavailable purchase/score features; UI presence alone does not mean backend capability. |
| Text rehearsal | Server session creation, scripted first response, Gemini-backed user-turn response path | Provider/network configuration required; failures should surface rather than imply a successful AI reply. |
| Audio/video rehearsal | Python server creates Tavus conversations and returns Daily call information; web embed and media capture adapters exist | Requires real provider setup, supported browser, user media permission, and device verification. Native adapter coverage differs. |
| Recording/replay | Browser capture, chunk upload/finalization, private local media storage, ticketed playback and replay screens are described and implemented across client/server | Local machine storage, not a deployed retention/storage service; closing early can lose final chunks. Historical sessions without media cannot be reconstructed. |
| Session analysis | Server analysis endpoint uses Gemini and may attach a saved recording; the Flutter local generator returns unscored transcript observations | Gemini/provider access is external. Numerical coaching scores and certified delivery measurements are unavailable. Model output is interpretation. |
| Authentication | Supabase email/password and OAuth client paths; server validates bearer tokens in normal mode | Needs configured Supabase and redirect/provider settings. Remote setup and multi-user production behavior are not verified here. |
| Sessions and subscriptions | Server-owned session reservations and stale-session recovery; RevenueCat entitlement lookup when configured | Store subscription purchases are handled by RevenueCat. Test-call mode is loopback-only and consumes real provider usage. |
| Supabase persistence | Schema/migrations/seed; client saves session/report/transcript; local server integrates with Supabase auth | Migration dated 20260923115434 is prepared, not applied remotely according to status notes. Client persistence and local server storage are distinct paths. |
| Cloudflare R2 | Service name/model and SQL recording path fields exist | Current server README describes private local file storage; do not assume R2 upload is active. |
| Design prototypes | `mockups/`, `web_mockups/`, `site/public/` | Standalone prototypes/static pages, separate from production Flutter session state. |

### Explicitly not done / unavailable

- Product purchase flow, verified subscription purchases, rewarded-ad grants, and production billing fulfillment.
- Numerical performance scorecards; current UI/model structures should not be read as proof of validated scoring.
- Hosted production backend, cloud recording retention, and verified deployed RLS/schema.
- Hardware-based end-to-end validation of local mic/camera capture, permissions, speaker audibility, and device switching (see the implementation status report).
- Any claim that the described remote credentials, products, entitlement mapping, database migration, or OAuth callbacks are correctly configured in production.

## Architecture

```text
Flutter / Dart client
  â”œâ”€ Screens, models, theme, widgets
  â”œâ”€ Provider state: simulation, settings, subscription
  â”œâ”€ Supabase Flutter: auth and session persistence
  â””â”€ HTTP BackendService â”€â”€> local Python HTTP server
                                 â”œâ”€ Supabase bearer-token validation (normal mode)
                                 â”œâ”€ SQLite account/session/reservation/report state
                                 â”œâ”€ Tavus conversation creation
                                 â”œâ”€ Gemini analysis
                                 â””â”€ private local media chunks and playback tickets
Browser media bridge â”€â”€â”€â”€â”€â”€â”€â”€â”€> Daily/Tavus iframe and browser recording
Supabase migrations/seed â”€â”€â”€â”€â”€> PostgreSQL schema, policies, scenario catalog
```

### Client entry and state

- `lib/main.dart`: initializes environment config, Supabase, RevenueCat, and Provider graph; opens `AppShell`.
- `lib/providers/simulation_provider.dart`: call/session lifecycle, transcript, provider events, call timer, finalization, and persistence calls.

- `lib/providers/subscription_provider.dart`: refreshes entitlement state from RevenueCat/backend; paid access should be treated as server-controlled.
- `lib/providers/settings_provider.dart`: local user preferences and provider/client settings; see configuration section for secret handling boundary.

### Backend and data

- `lib/services/backend_service.dart`: JSON HTTP transport, bearer token attachment, backend URL resolution.
- `server/app.py`: Python standard-library HTTP server; session reservations and state; identity, provider calls, recording, analysis, playback routes.
- `lib/services/supabase_service.dart`: Supabase initialization, auth, scenario/session/transcript operations.
- `supabase/migrations/20260923_init_schema.sql`: profiles, scenarios, session attempts, transcripts, RLS and seed scenarios.
- `supabase/migrations/20260923115434_restrict_client_privileges.sql`: column-level profile privileges and custom-scenario insertion policy tightening; status says prepared but not remotely applied.
- `supabase/migrations/20260923143000_supabase_r2_cloud_storage.sql`: adds legacy billing/report/analysis and recording URL fields. Review its broad grants together with the later privilege migration before deployment.

### Media and AI adapters

- `lib/services/tavus_service.dart`, `tavus_embed_*`, `live_avatar_service.dart`, `live_avatar_embed_*`: counterpart/video provider integration and platform-specific embed surface.
- `lib/services/camera_service*`, `speech_service*`, `tts_service*`: conditional browser/native adapters. Inspect the active platform implementation before assuming parity.
- `lib/services/livekit_service.dart`: LiveKit adapter/service abstraction; server README currently describes Tavus/Daily for audio/video.
- `lib/services/cloudflare_r2_service.dart`: recording URL abstraction; do not equate this with an active R2 upload. The local server currently stores recordings in `server/.state`.
- `lib/services/debrief_generator_service.dart`: local transcript-only, zero-score fallback/observation report.
- `server/app.py`: authoritative server analysis path, Gemini provider calls, evidence checks and caching.

## Technology stack and skills represented in code

| Technology | Use in this repository |
|---|---|
| Dart / Flutter (Dart SDK constraint `^3.9.0`) | Cross-platform mobile/web UI, platform adapters, unit/widget tests |
| Provider | Flutter app state and dependency wiring |
| Python 3 | Local HTTP API, provider proxy, account/session/recording/analysis orchestration |
| SQLite | Local backend state: sessions, recordings, cached analyses |
| Supabase Auth + PostgreSQL + RLS | User identity and cloud schema/session data |
| Google Gemini API | Text-generation path and server-side session analysis, depending on mode/path |
| Tavus + Daily | AI video counterpart and browser call surface |
| RevenueCat | Subscription entitlement lookup |
| Browser Web APIs / iframe bridge | Media permissions, Daily call media, recording, playback |
| HTML, CSS, JavaScript | Static mockups and web call/bootstrap bridge |
| SQL | Supabase schema, policies, indexes, trigger, seed data |
| Android Gradle/Kotlin, iOS Swift/Xcode, Windows CMake/C++ | Flutter platform runners and app packaging scaffolding |

Engineering skill areas demonstrated: Flutter screen/component development; Provider state management; REST API integration; auth/session design; SQL/RLS schema work; Python HTTP and SQLite transactions; browser media capture/WebRTC integration; AI-provider orchestration; platform-specific conditional imports; test writing; responsive design systems and asset management.

Declared Flutter packages are in `pubspec.yaml`: `provider`, `supabase_flutter`, `purchases_flutter`, `google_fonts`, `fl_chart`, `http`, `shared_preferences`, `intl`, `crypto`, and `cupertino_icons`. Package declaration alone does not prove a feature is fully integrated.

## Source and file guide

### Flutter app (`lib/`)

| Directory | Responsibility |
|---|---|
| `lib/config/` | Runtime/environment configuration (`env_config.dart`) |
| `lib/models/` | Scenario/persona/user persona, debrief, telemetry and subscription data types |
| `lib/providers/` | Cross-screen state, session lifecycle, settings, entitlements |
| `lib/screens/` | Onboarding, goal choice, home/scenario, custom scenario, preparation/live call, debrief/detail/replay, sign-in, settings, plans |
| `lib/services/` | Backend, auth/data, AI/avatar/media, recording/replay, telemetry and billing adapters |
| `lib/theme/` | Theme tokens and asset registry |
| `lib/widgets/` | Reusable score,  camera, dialog, telemetry and waveform widgets |

Important authored source files (the table describes focus; consult the file for exact behavior):

- App composition: `main.dart`, `screens/app_shell.dart`.
- Main journey: `screens/onboarding_screen.dart`, `scenario_hub_screen.dart`, `custom_scenario_screen.dart`, `session_prep_screen.dart`, `live_call_screen.dart`, `debrief_report_screen.dart`, `session_detail_screen.dart`, `session_replay_screen.dart`.
- Account/monetization UI: `sign_in_screen.dart`, `settings_modal.dart`, `subscription_paywall_screen.dart`, `subscription_store_modal.dart`.
- State and core models: `providers/simulation_provider.dart`, `subscription_provider.dart`, `settings_provider.dart`; corresponding files under `models/`.
- Integrations: `services/backend_service.dart`, `supabase_service.dart`, `tavus_service.dart`, `tavus_embed_web.dart`, `debrief_generator_service.dart`, `cloudflare_r2_service.dart`, `revenuecat_service.dart`.

### Server (`server/`)

- `app.py`: API server, auth/entitlement checks, session reservation/cancellation, provider calls, uploads, analysis, transcript/report/history and playback handling.
- `test_app.py`: Python unittest coverage for reservation and recovery, ownership, provider contracts, recording/upload, analysis and media ticket behavior.
- `README.md`: setup, modes, constraints and known operational limitations.
- `.state/`: runtime local SQLite and media files; ignored by Git and not source documentation.

### Database (`supabase/`)

- `migrations/20260923_init_schema.sql`: initial relational model and RLS.
- `migrations/20260923115434_restrict_client_privileges.sql`: privilege tightening prepared for remote review/application.
- `migrations/20260923143000_supabase_r2_cloud_storage.sql`: additional profile/session columns and grants.
- `seed.sql`: built-in scenario records. App-side `lib/models/scenario.dart` also has a static catalog; compare the two when changing scenario content.

### Web, native, prototypes, and assets

- `web/`: Flutter web shell, manifest, call page/JS bridge, and vendored Daily iframe library/license.
- `android/`, `ios/`, `windows/`: platform runner/configuration files; generated registrants and build scaffolding are not product logic.
- `web_mockups/`, `mockups/`, `site/public/`: independently previewable visual prototypes/static page; not authoritative runtime flows.
- `assets/`: illustrations, badges, gamification art, icons, avatars and archive/platform exports. `pubspec.yaml` lists the Flutter-consumed directories. ZIP archives and per-platform image variants are distribution/source assets rather than individual logic files.
- `test/`: Flutter widget/call-flow tests.

### Root docs/config

- `README.md`: entry point and preview instructions.
- `PROJECT_OVERVIEW.md`: aspirational product/architecture narrative; read alongside implementation status because portions describe intended behavior.
- `CODEBASE_AUDIT.md`: earlier audit snapshot and findings, followed by status reference.
- `IMPLEMENTATION_STATUS.md`: later implementation and verification report with outstanding limitations.
- `COURSE_CATALOG.md`, `DESIGN_RULEBOOK.md`: learning content and visual/design guidance; some design directions are prototype requirements, not proof of current UI conformity.
- `pubspec.yaml`, `analysis_options.yaml`: Dart constraints, packages, assets and lint configuration.
- `skills-lock.json`: records Supabase and Supabase Postgres best-practice agent-skill sources; these are development guidance, not runtime dependencies.
- `.gitignore`: excludes local env/state/build outputs. `.env` and `assets/env.json` are local environment material and should never be copied into public docs.

## Data entities and flows

### Supabase data model (intended cloud persistence)

- `profiles`: one row per Supabase auth user; identity and profile.
- `scenarios`: built-in and user-created scenario definitions, objectives and phrases to avoid.
- `session_attempts`: owner, scenario reference, duration, scores/tier columns, recording URL, analysis/report JSON.
- `transcripts`: ordered speaker turns and timestamps/tags, cascading from session attempt.

### Local server model

- `accounts`: server-controlled subscription state and tier cache/state.
- `practice_sessions`: owner, mode, state, provider conversation ID, creation time, report and request count.
- `recordings`: per-session media type, byte count, completion flag and metadata; bytes are held in private local files.
- `analyses`: cached analysis payload per session.

### Session lifecycle (server)

`starting` â†’ `active` after provider connection â†’ `ended`; failed starts can be cancelled. A session reservation checks the current tier and prevents a second active session for the same owner. Stale sessions are recovered after the configured expiry window. Verify exact route behavior in `server/app.py` before changing this contract.

## Configuration and local development

Read [server/README.md](server/README.md) before running provider-backed calls. Normal operation expects the Flutter web build to be served by the same-origin Python server; local test-call mode is an explicit loopback-only integration mode, grants test entitlements and still invokes real provider services.

Expected private server configuration includes Supabase URL/publishable key, Gemini key/model, Tavus key/persona, and optionally RevenueCat server secret. Exact env variable names and aliases are documented in `server/README.md` and `server/app.py`. Never paste actual key values into documentation or commit them. `GEMINI_MODEL` defaults to `gemini-3.5-flash` per the current server README.

The Flutter client always talks to the deployed backend. It resolves its backend URL from the compile-time `BACKEND_URL` define, defaulting to `https://hardsync.onrender.com` (the deployed `hardsync-api` Render service) when not overridden — there is no local/loopback fallback. The Gemini Live bridge is deployed separately as `hardsync-live` on Render and is only reached server-side via `GEMINI_LIVE_BRIDGE_URL`. Do not distribute the test-call mode or expose it through a tunnel.

Repository commands recorded in project docs:

```powershell
# UI prototype
python -m http.server 8090
# then open http://127.0.0.1:8090/mockups/

# Python server
python server/app.py
# or explicit local provider integration mode
python server/app.py --test-calls --port 8082

# Reported project verification commands (not run as part of writing these docs)
python -m unittest discover -s server -p test_app.py -v
flutter test --no-pub
flutter analyze --no-pub
```

## Testing and verification record

Test sources are `server/test_app.py`, `test/call_flow_test.dart`, and `test/widget_test.dart`. The 2026-09-23 `IMPLEMENTATION_STATUS.md` reports passing Python and Flutter suites, Flutter analysis, web build, and browser rehearsals, plus the specific device/cloud/billing limits listed there. This documentation update did not rerun tests, use credentials, invoke external providers, or inspect a live Supabase project. Re-run the documented checks against the intended environment before release.

## Known risks and follow-up work

1. Review/apply the privilege migration only after reconciling the grants in all SQL migrations; verify RLS against a real Supabase project.
2. Decide whether session history/analysis/recording are intended to be cloud-persisted or local-only, then unify data ownership and retention behavior.
3. Implement a verified billing and subscription fulfillment path before offering subscription purchase flows.
4. Complete hardware/browser compatibility testing, including denied permissions, device switching and media finalization.
5. Keep the product UI aligned with current truthful feature state: do not display sample values as measured user progress or scores.
6. Reconcile old concept docs, design mockups and current implementation as features change; clearly mark aspirational artifacts.
7. Ensure keys embedded in prior builds are rotated where required; current local source/docs must not re-expose them.

## Product success measures (proposed)

- Rehearsal completion rate and time from scenario selection to first user turn.
- Repeat practice rate by scenario and return practice frequency.
- User-rated confidence/readiness before and after a rehearsal (self-report, not inferred emotion).
- Transcript/analysis availability and evidence validation rate.
- Session start failure, recording finalization failure, and analysis failure rates.
- Session reservation/cancellation correctness and entitlement authorization outcomes.

These are proposed measurement definitions; analytics instrumentation and validated thresholds are not documented as implemented.
