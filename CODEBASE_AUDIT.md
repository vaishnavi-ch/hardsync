> Follow-up implementation and test results: see [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md). This audit records the original findings; some are now fixed and remaining deployment/device checks are tracked there.

# HardSync codebase audit

Reviewed: 2026-09-23. Scope: local Flutter application, providers, service integrations, models, screens, platform adapters, SQL migration/seed, configuration, and existing tests. No application code was changed. Live provider credentials were not exercised, purchases were not made, and the deployed database was not inspected. Findings about database behavior assume the supplied migration is deployed. Secret values are intentionally omitted.

## Overall assessment

This is a developed Flutter UI prototype with partial real integrations. Supabase auth/session writes, Gemini generation, browser speech/camera/TTS, and avatar API requests have implementations. Billing enforcement, credits, LiveKit, live vision telemetry, recordings, history browsing, and replay are incomplete or simulated. Several screens present simulated output as actual user activity or successful service operations.

The current source fails compilation with the installed RevenueCat dependency.

## Architecture and data flow

- `lib/main.dart`: initializes configuration, Supabase and RevenueCat; installs Settings, Subscription, Credits and Simulation providers; opens AppShell.
- `lib/screens/app_shell.dart`: Home, Sessions, Payments and Account in an IndexedStack. Sessions directly opens a replay screen without a report; it is not a history browser.
- `lib/models/`: local scenario/persona/user-role catalogs, subscription and credit product definitions, telemetry and report structures. Static scenario content is legitimate authored content, but it is separate from the seeded database catalog.
- `lib/providers/`: settings, credits and subscription tiers persist in SharedPreferences. SimulationProvider orchestrates avatar requests, browser-generated dialogue, telemetry, session state and debrief generation.
- Main flow: scenario hub/custom scenario â†’ session preparation â†’ live call â†’ generated debrief â†’ replay or practice again.
- Video attempts Tavus first, then LiveAvatar if no Tavus URL is returned. Audio invokes a simulated LiveKit service. All modes start browser speech recognition; recognized text goes through the local telemetry engine and Gemini/scripted response generator.
- End call generates a Gemini report (with optional webcam still), or a heuristic fallback, then asynchronously attempts Supabase persistence. Only selected scores and transcript fields are saved; full report content is not persisted.
- `supabase/`: migration and seed for profiles, scenarios, session attempts and transcripts. No application backend, recording worker, payment webhook, server credit ledger or provider-token broker was found.
- `site/public/index.html`: separate static design page, not the Flutter application's data/backend layer. `web/` and `windows/` contain platform launch scaffolding. Native camera/speech/TTS/avatar adapters are stubs.

## Verification

- Flutter analysis: **failed**, two errors and two deprecation notices, all in `lib/services/revenuecat_service.dart:87` and `:109`.
- Flutter tests: **failed during compilation** at the same assignments. No test cases completed; this is not evidence that the assertions themselves fail.
- Used the installed Flutter tool snapshot with `analyze --no-pub` and `test --no-pub`; SDK cache access required elevated execution.
- The workspace is not a Git repository, so no Git history/diff review was possible.
- No browser end-to-end run or external API validation was performed. Runtime race conditions below are code-path findings, not reproduced browser incidents.

## Critical / high-priority findings

### 1. Build blocker: RevenueCat return type mismatch

Evidence: `lib/services/revenuecat_service.dart:87`, `:109`.

Both purchase methods assign the result of `Purchases.purchasePackage` directly to `CustomerInfo?`. Installed `purchases_flutter` 10.13.1 returns `PurchaseResult`. Analyzer and test compiler confirm this. Adapt the integration to the installed SDK and obtain customer info from the purchase result; then rerun checks.

### 2. Private credentials are shipped to clients

Evidence: `lib/config/env_config.dart:16`, `pubspec.yaml:68`, `.env`, `assets/env.json`.

Provider API keys are hardcoded as configuration defaults. Both `.env` and the assets directory are bundled. The local `.env` also contains a nonempty Google OAuth client secret. Packaging a secret as a Flutter asset exposes it to app recipients; ignoring it in Git alone would not solve this. The current `.gitignore` also does not exclude these credential files.

Move privileged requests and secrets behind a server boundary, remove private credentials from shipped assets, and rotate exposed private credentials. Supabase publishable keys are intentionally client-facing and should not be treated as private service keys. Credential validity and prior deployment exposure were not tested.

### 3. Paid tiers activate before payment succeeds

Evidence: `lib/screens/subscription_paywall_screen.dart:472`, `lib/providers/subscription_provider.dart:23`, `lib/services/revenuecat_service.dart:74`.

The paywall persists the selected tier before making a purchase and ignores the returned success/failure boolean. Failed or cancelled payments still unlock features. With the current empty RevenueCat configuration, purchase methods explicitly return simulated success.

Tier state is device-local, not derived from current entitlements. Expiration/refund/account changes do not reconcile it. Restore always sets Pro, even if restoring an Ultra purchase. Ultra is mapped to the annual package, while the displayed Ultra price is monthly; there is no separate verified Ultra entitlement mapping. RevenueCat initialization is not linked to subsequent Supabase login/logout.

### 4. Practice Again bypasses tier and credit gates

Evidence: `lib/screens/debrief_report_screen.dart:139`, `lib/providers/simulation_provider.dart:173`.

Practice Again calls `startCall(currentScenario)` directly. Its default mode is video. There is no subscription check or credit deduction, so a Free text rehearsal can lead directly to an uncharged video attempt. Put authorization/credit reservation at the shared session-start boundary, including retries.

### 5. Free text practice has no text-entry control

Evidence: `lib/screens/live_call_screen.dart:468`, `:46`.

The text surface renders a transcript and subtitles but has no text field or send action. It depends on microphone speech recognition, which is started in every mode. Users without a supported browser speech API or microphone permission cannot respond; native builds use a no-op speech adapter.

### 6. Avatar conversation and recorded conversation are disconnected

Evidence: `lib/screens/live_call_screen.dart:46`, `lib/providers/simulation_provider.dart:302`, `lib/services/tavus_embed_web.dart:27`.

The embedded video conversation runs independently of the browser speech â†’ Gemini â†’ TTS pipeline. Tavus iframe integration has no transcript event bridge. The LiveAvatar transcript retrieval method is never called. The local transcript stores locally generated responses, not confirmed utterances from the embedded avatar. Browser TTS is called even with live video active, creating a competing voice path and possible speech-recognition feedback.

Use one authoritative conversation pipeline and feed its actual turns into scoring and persistence.

### 7. Microphone controls do not mute the embedded call

Evidence: `lib/providers/simulation_provider.dart:135`, `lib/screens/live_call_screen.dart:853`, `lib/services/livekit_service.dart:58`.

The mute button only toggles a local boolean. Recognition callbacks ignore text when muted, but recognition itself continues and no Tavus/LiveAvatar microphone command is sent. `LiveKitService.setMuted` has no caller. Camera/mic settings also are not consulted when the live screen starts hardware. A muted indicator is therefore not reliable evidence that the provider microphone is muted.

### 8. Vision telemetry is fabricated and influences evaluation

Evidence: `lib/services/telemetry_engine.dart:73`, `lib/services/camera_service_web.dart:60`, `lib/services/debrief_generator_service.dart:283`.

Telemetry eye-contact/composure scores are random walks. Camera service gaze uses clock milliseconds, not image analysis, and is separate from the telemetry engine. These numbers influence avatar defensiveness, report scores and Gemini's prompt as if they were sensor measurements. Text/audio sessions also receive webcam presence claims. One optional webcam still sent to Gemini does not establish continuous gaze measurements.

Unavailable measurements should be absent; demo measurements need explicit labeling and separation from actual evaluation.

### 9. Tavus errors masquerade as success and block fallback

Evidence: `lib/services/tavus_service.dart:83`, `:108`, `lib/providers/simulation_provider.dart:218`.

An API error returns `success: true` with a fabricated demo-preview URL and `is_mock: true`. SimulationProvider accepts that URL without checking the mock flag. Since a URL now exists, it skips LiveAvatar fallback, then marks the call connected after a fixed delay. Actual iframe readiness is not used to establish call state.

### 10. Credits and ad rewards are entirely local

Evidence: `lib/providers/credits_provider.dart:7`, `:154`, `lib/widgets/rewarded_ad_dialog.dart:48`.

Buying a package directly increments SharedPreferences credits and returns true; there is no checkout. A five-second timer grants an ad reward without an ad network callback. Clearing local storage restores the welcome balance, and the same balance is shared between accounts on the device. Session prep deducts credits before connection and has no failed-connection refund path.

### 11. Recordings and replay are not implemented end to end

Evidence: `lib/services/cloudflare_r2_service.dart:13`, `lib/providers/simulation_provider.dart:438`, `lib/screens/session_replay_screen.dart:256`, `:381`.

There is no recording capture/upload call site; `uploadSessionRecording` is unused. Without configuration it claims upload success. Its configured PUT has no signing/authorization implementation. Session persistence constructs a recording URL using the scenario ID, not a unique recording/session ID.

Replay displays asset images; play/pause, scrubber and speed change widget state without controlling a media player. Duration is hardcoded to 5:12. Download copies a constructed URL rather than downloading a recording. No actual recording object was verified.

### 12. Session history is not wired into the UI

Evidence: `lib/screens/app_shell.dart:26`, `lib/services/supabase_service.dart:237`, `lib/screens/session_replay_screen.dart:35`, `:559`, `:704`.

`fetchUserSessionHistory` has no callers. The Sessions tab opens a default replay without a report. Missing transcripts are replaced with invented dialogue. Replay insights remain fixed Alex-specific feedback even when a real report from a different scenario is supplied. New users see fictional session content instead of an empty state.

### 13. Custom scenario session saves violate the supplied foreign key

Evidence: `lib/screens/custom_scenario_screen.dart:74`, `lib/services/supabase_service.dart:194`, `supabase/migrations/20260923_init_schema.sql:41`.

Custom scenarios get new local IDs but are never inserted into `scenarios`. Saving an attempt includes that ID, while `session_attempts.scenario_id` references the scenarios table. Against this schema, the insert fails. The service logs and returns null; the caller still logs that the session was persisted.

Other persistence gaps: session and transcript insertion are separate requests, so transcript failure leaves an incomplete session; unauthenticated sessions are not saved; the mock save path claims local persistence but writes nothing; AI summary, blueprint, key moments, raw metrics and snapshot are not stored for report reconstruction.

### 14. Authentication can silently degrade to fake success

Evidence: `lib/services/supabase_service.dart:67`, `:97`, `:182`, `lib/screens/sign_in_screen.dart:57`.

When Supabase initialization fails, email sign-in/signup accepts input and sets local mock authentication. This does not grant a real Supabase session or bypass server RLS, but the UI claims successful cloud authentication. Explicit demo login is also exposed. Demo mode and production auth failure should have distinct UI/state.

## Additional correctness findings

- **Selected counterpart changes after greeting:** `simulation_provider.dart:339` passes `activeScenario.persona` rather than `activeCounterpart` to generation and transcript labels. Select another counterpart in preparation to trigger inconsistent identity; the chosen user role also is not included in the Gemini dialogue prompt.
- **Session cancellation races:** `startCall` resumes after asynchronous API calls and unconditionally sets `inCall`; ending while connecting can be undone by the pending start. `handleUserUtterance` appends/speaks a response after its await without checking session identity or ended state. Concurrent utterances are not serialized. Reset does not cancel all running work; native/browser back navigation is not protected by a session cleanup boundary.
- **LiveAvatar cleanup token never assigned:** `_liveAvatarSessionToken` is declared and checked during shutdown but never populated. Consequently the provider's API stop path cannot run for embeds. Actual provider lifecycle behavior needs live verification.
- **Speech duration is assumed:** recognized turns call `handleUserUtterance` without a duration, so each counts as four seconds. Avatar speaking time is also fixed at four seconds. WPM/talk ratio do not measure actual duration.
- **Hedging counter never increments:** `telemetry_engine.dart` detects hedging but does not update `SpeechMetrics.hedgingCount`; it instead adds to filler count. Multiword filler `you know` cannot match the per-word filler loop. Browser WPM helper also counts repeated interim results, though that callback is not wired into the live screen.
- **Current Gemini user turn is duplicated:** SimulationProvider appends the user turn before passing history; `ai_avatar_service.dart` then appends the same utterance again.
- **Empty-session fallback scores are misleading:** the heuristic gives clarity 98 without any user speech, positive default presence, and invented gaze observations. Missing evidence needs an insufficient-data result.
- **Settings do not reliably control behavior:** `useLiveCloudAi` is not passed to generation; camera/mic preferences are not used at session start. The sandbox getter always resolves to the override initialized to true, so an environment false value cannot determine the initial state. LiveAvatar sandbox mode also does not prevent separate Tavus requests.
- **No request timeout in dialogue/avatar setup:** Gemini dialogue, Tavus creation and LiveAvatar HTTP methods can wait without an application deadline. Debrief generation does have a 12-second timeout.
- **Native support is incomplete:** Windows scaffold exists, but speech, TTS, camera and video embeds are stubs outside web. The UI still offers these modes.
- **Embedded screens assume pushed routes:** payment activation and replay Back call `Navigator.pop` even when displayed as root AppShell tabs. Separate embedded-tab behavior from route dismissal.
- **Share reports claims a clipboard write without doing one:** `debrief_report_screen.dart:58` only shows a snackbar.
- **Goals do not persist:** `goal_selection_screen.dart:43` navigates without saving selected goals. Custom scenario generation is a delay plus a fixed template/default Alex persona; the user's text is retained as context, but objectives are not generated.
- **Hardcoded identity/activity:** `scenario_hub_screen.dart:101` shows a three-day streak and `:199` greets Sarah regardless of authentication. User avatar assets and static replay feedback remain demo content.
- **Integration status is configuration presence:** settings labels say Connected/Active based on nonempty key checks rather than operational service state. Hardcoded provider defaults make missing-key detection misleading.
- **Cross-account local state:** credits, subscriptions and settings use global preference keys; logout does not reset/reload account-specific state.

## Supplied database policy concerns

These are source-level policy findings, not an audit of the deployed Supabase project.

- Profiles grant authenticated users table-wide UPDATE on their own row, including `is_pro_subscriber` and `streak_count`. Those columns cannot safely become authoritative entitlements/activity measurements without restricting writes. Current client subscription gating already uses local preferences, so this is not an additional demonstrated gating path.
- Custom-scenario INSERT only checks `created_by = auth.uid()`; it does not require `is_custom = true`. That flag defaults false, and false rows are publicly selectable. A client can therefore insert a publicly visible scenario through a policy labeled as custom/private.
- Session scores and transcript labels are client-authored. They are unsuitable as tamper-resistant rankings or certification without server validation.
- The user-creation trigger does not copy the provided leadership role into the profile. Stored profile role defaults to Engineering Leader.
- RLS is enabled on all four tables, and session/transcript ownership policies are present. The problem is incomplete field-level/business rules, not a total absence of row security.

## Mock / unfinished feature inventory

| Area | Current behavior | Main files |
| --- | --- | --- |
| Home personalization | Sarah greeting, fixed streak | `screens/scenario_hub_screen.dart` |
| Catalog | Authored in Dart; not fetched from SQL | `models/scenario.dart`, `models/persona.dart` |
| Custom generation | Local template after delay | `screens/custom_scenario_screen.dart` |
| Auth fallback | Fake email auth; explicit demo user | `services/supabase_service.dart` |
| Subscription | Local tier, simulated purchases when unconfigured | `providers/subscription_provider.dart`, `services/revenuecat_service.dart` |
| Credits | Local balance and immediate top-ups | `providers/credits_provider.dart` |
| Rewarded ads | Five-second timer | `widgets/rewarded_ad_dialog.dart` |
| Audio transport | Simulated connection and random audio meter | `services/livekit_service.dart` |
| Video fallback | Fabricated successful Tavus session URL | `services/tavus_service.dart` |
| Dialogue fallback | Fixed phrases selected by keywords/defensiveness | `services/ai_avatar_service.dart` |
| Eye contact / composure | Random and clock-derived values | `services/telemetry_engine.dart`, `services/camera_service_web.dart` |
| Debrief fallback | Transcript heuristics mixed with artificial vision values | `services/debrief_generator_service.dart` |
| Recording storage | Constructed URLs; no capture/upload flow | `services/cloudflare_r2_service.dart` |
| Session history | Unused fetch; canned fallback rows | `services/supabase_service.dart` |
| Replay | Static images/controls, sample turns, fixed insights | `screens/session_replay_screen.dart` |
| Native media | No-op platform adapters | `services/*_stub.dart` |

## Suggested repair order

1. Remove client-bundled private credentials and rotate exposed secrets; fix compilation and rerun checks.
2. Make demo mode explicit; stop claiming successful auth, payment, connection, upload or sensor analysis on fallback/failure.
3. Centralize entitlement and credit enforcement on a trusted backend; route Practice Again through the same start checks.
4. Finish text input and select one authoritative audio/video conversation pipeline, including true mute, transcript events and cancellation.
5. Fix scenario/session persistence, account scoping, history browsing and report reconstruction.
6. Implement real recording/replay and either real supported telemetry or honest unavailable states.
7. Add meaningful regression coverage: cancelled purchases, credit gating/retries, custom saves, empty history, muted provider microphone, ending during connection/response, counterpart selection and account switching. Existing tests mainly check catalogs/local behavior and some explicitly expect mock purchases and rewards.
