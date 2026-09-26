# Backend and State Test Report

Date: 2026-09-25

## Coverage

- API authentication and owner isolation
- Session reservation, concurrency, conflict recovery, expiry, cancellation, and refunds
- Free, Pro, and Ultra call restrictions
- Gemini Live audio and Tavus video provider contracts
- Empty, null, malformed, oversized, and invalid request data
- Generation limits and protection against invalid requests consuming quota
- Recording upload retries, offsets, finalization, ownership, formats, and playback ranges
- Immutable reports and transcript validation
- Transcript and recording analysis evidence validation
- Flutter HTTP success, error, empty body, malformed JSON, HTML response, and offline states
- Call lifecycle, late responses, provider events, save retries, and recording finalization
- Responsive UI states across compact phone, standard phone, tablet, landscape tablet, and desktop
- Authentication, learning, quiz retry, custom scenario, paywall, progress, and navigation states

## Fixes made during the audit

- Invalid generation requests are rejected before request quota is incremented.
- Invalid Base64 recording chunks return a client error instead of a server error.
- Empty or malformed session responses no longer crash the Flutter state provider.
- Empty successful HTTP responses and offline failures now have explicit client behavior.
- Credit balances validate numeric type and reject negative or malformed values.
- Corrupt history records are skipped individually instead of hiding all valid history.
- Reports reject missing, blank, oversized, and mutable transcript data.
- R2 access credentials were removed from the public configuration endpoint and Flutter bundle.
- Fabricated R2 URLs were removed. Local playback works; cloud playback remains unavailable until the backend performs and confirms a real upload.

## Verification commands

```text
python -m unittest test_app -v
flutter test
flutter analyze
flutter build web
```

The backend suite contains 22 tests. The Flutter suite contains 40 tests.

## Monetization and new-account audit

- Prevented client-authored Pro and Ultra activation.
- Paid tier expiry and refunds can move the local provider back to Free.
- RevenueCat identity now follows the Supabase UUID.
- Release builds cannot select the RevenueCat Test Store key.
- Credit display reads the same backend ledger used for atomic session charges.
- Added a migration that removes client write access to billing fields.
- Added a persisted first-launch gate: onboarding, authentication, then the app shell.
- Verified the built onboarding and authentication screens in Chrome.
- Production purchases are blocked until Apple, Google, or web RevenueCat keys and the backend RevenueCat secret are configured.
- RevenueCat Ad Monetization remains disabled until its Ads beta, rewarded-unit connection, Flutter rendering SDK, and verified reward rule are configured; no unverified reward is granted.

See `MONETIZATION_AUTH_AND_DATA_PLAN.md` for product identifiers, prices, credit values, ad placement rules, state coverage, data ownership, and the release checklist.
