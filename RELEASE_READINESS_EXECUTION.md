# HardSync release readiness execution

Updated: 2026-09-25

## RevenueCat Test Store verification

- Flutter SDK `purchases_flutter 10.13.1` meets RevenueCat's Test Store minimum.
- Debug SDK initialization succeeded with the Test Store API key.
- Current offering `default` loaded with Monthly (`$rc_monthly`), Yearly (`$rc_annual`), and Lifetime (`$rc_lifetime`) packages.
- Purchase cancellation returned RevenueCat's user-cancelled result and did not grant an entitlement.
- Simulated purchase failure returned RevenueCat's Test Store failure and did not grant an entitlement.
- Valid Monthly purchase completed and activated sandbox entitlement `test_pro`.
- Restore purchases completed with the active sandbox entitlement.
- The app recognizes `test_pro` only in a debug Test Store build. Release builds still require exact production entitlement IDs and backend verification.
- Ultra remains blocked because the current Test Store offering has no Ultra package or `test_ultra` entitlement.
- Monthly expiry needs a timed follow-up run: Test Store renews it every five minutes and expires it after five renewals, about 25 minutes.

Debug harness: `flutter run -d web-server -t lib/revenuecat_test_harness.dart`

## Completed in code

- Persisted launch routing: onboarding, authentication, then the authenticated app.
- Responsive navigation and screen tests for phone, tablet, and desktop widths.
- Complete learning catalog, lesson states, reflection, quiz retry, and completion flows.
- Practice setup, text/audio/video gating, reservation, refund, reports, and replay states.
- Supabase email/password, OAuth, reset-password, session history, profile, and deletion client flows.
- RLS migration protecting billing fields from client updates.
- Exact RevenueCat `pro` and `ultra` entitlement checks and Supabase UUID identity sync.
- RevenueCat Test Store purchase and restore code paths.
- RevenueCat rewarded-ad verification flow using Google Mobile Ads only as the renderer.
- RevenueCat currency webhook ingestion into the backend credit ledger.
- Idempotent webhook processing for purchase and ad credit grants.
- Call recording uploads and replay have been disabled; live media is streamed to the call provider and is not stored by HardSync.
- Atomic credit reservation and idempotent refund handling.

## Verified locally

| Check | Result |
|---|---|
| Python backend tests | 25 passed |
| Flutter unit/widget tests | 40 passed |
| Flutter static analysis | No issues |
| Flutter web release build | Passed |
| Browser authentication smoke test | Passed |
| Browser console errors/warnings | None |
| Android debug build | Blocked locally: Android SDK/`ANDROID_HOME` is not installed |

## External configuration still required

These operations cannot be completed from source code or with a public client key.

1. Apply the Supabase migrations using an authenticated dashboard or CLI session.
2. Configure Supabase production SMTP, redirect URLs, Google OAuth, and Apple OAuth.
3. Add RevenueCat production store apps, products, entitlements, offering, secret key, and webhook authorization value.
4. Enable RevenueCat Ads beta, connect the ad inventory account, configure the shared SSV callback, create currency `CR`, and assign a 3-credit reward.
6. Replace Google test app/ad unit IDs before production release.

## Required backend environment

```text
REVENUECAT_SECRET_KEY
REVENUECAT_PROJECT_ID
REVENUECAT_WEBHOOK_AUTHORIZATION
```

The RevenueCat webhook URL is:

```text
https://<backend-host>/api/webhooks/revenuecat
```

Set its `Authorization` header to the exact value stored in
`REVENUECAT_WEBHOOK_AUTHORIZATION`.

## Test ad configuration

Debug mobile builds use Google's official rewarded test units when custom units
are absent. Android and iOS manifests contain Google's sample application IDs.
Production builds require real IDs; no fallback ad unit is used in release mode.

## Credit authority

The backend ledger is the balance shown and spent by HardSync. RevenueCat
validates purchases and rewarded ads, then sends a
`VIRTUAL_CURRENCY_TRANSACTION` webhook. The server applies only `CR`
adjustments from `ad_reward` and `in_app_purchase`, records the event ID, and
ignores duplicate delivery. The Flutter reward callback never mints credits.
