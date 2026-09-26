# HardSync monetization, authentication, and data plan

Updated: 25 September 2026

## Executive decision

HardSync should use a hybrid subscription and metered usage model:

- **Free:** lessons, progress, and text practice with a small starter balance.
- **Pro:** unlock audio practice and grant a monthly credit allowance.
- **Ultra:** unlock video practice and grant a larger monthly allowance.
- **Credit packs:** consumable in-app purchases for practice beyond the allowance.
- **Rewarded ads:** an optional recovery mechanism for free users, never a forced interruption.

Entitlements and purchased credits must be verified server side. The app may display cached values, but it must never mint credits or unlock a paid tier by changing local state.

## Recommended products

### Subscriptions

| Plan | Suggested price | Access | Credits per billing month |
|---|---:|---|---:|
| Free | $0 | Lessons, progress, text practice | 30 once at account creation |
| Pro | $19/month or $179.88/year | Free features plus audio practice | 300 |
| Ultra | $39/month or $359.88/year | Pro features plus HD video and visual analysis | 700 |

The store price returned by RevenueCat is the display authority. Hard-coded prices are placeholders and must not override localized store prices.

### Credit spending

| Practice mode | Credits | Approximate pack value at $0.06â€“$0.10 per credit |
|---|---:|---:|
| Text rehearsal | 5 | $0.30â€“$0.50 |
| Live audio rehearsal | 15 | $0.90â€“$1.50 |
| HD video rehearsal | 30 | $1.80â€“$3.00 |

One credit is an internal usage unit, not a fixed cash amount. With the current packs its retail value decreases from about $0.10 to $0.06 as pack size increases. Before launch, measure the 95th percentile provider cost of a complete 10 minute session and preserve at least a 65% gross margin after store fees.

### Credit packs

| Product ID | Credits | Price | Effective price per credit |
|---|---:|---:|---:|
| `hardsync_credits_50` | 50 | $4.99 | $0.100 |
| `hardsync_credits_150` | 150 | $11.99 | $0.080 |
| `hardsync_credits_500` | 500 | $29.99 | $0.060 |

These are consumable in-app purchases. Purchased credits must not expire. Apple requires in-app purchase for app currency and says purchased currency may not expire. Google Play also requires Play Billing for in-app virtual currency and limits that currency to this app.

## RevenueCat configuration

Create these exact identifiers and use exact equality in code:

- Entitlements: `pro`, `ultra`
- Offering: `default`
- Subscription packages: `$rc_monthly` for Pro and `$rc_annual` or an explicit `ultra_annual` package for Ultra
- In-app currency: `TBC` (HardSync Credits)
- Consumables: the three credit products listed above

RevenueCatâ€™s current model is Product â†’ Entitlement â†’ Offering. Products must be attached to the correct entitlement and the `default` offering must contain every package shown by the app. HardSync uses the Supabase user UUID as RevenueCat `appUserID` so purchases follow the user across devices and platforms.

For credits, RevenueCat In-App Currency is the preferred ledger. It can grant currency from verified purchases and subscriptions. Spending or server deposits still require the RevenueCat Developer API and a secret held by the backend. After a balance change, invalidate the SDK currency cache before fetching the new value.

Production requirements:

1. Debug builds may use `REVENUECAT_TEST_STORE_KEY`.
2. Release builds must use the platform-specific public key.
3. Add `REVENUECAT_SECRET_KEY` only to the backend secret store.
4. Configure an authenticated, HMAC-signed RevenueCat webhook.
5. Make webhook handling idempotent using the RevenueCat event ID.
6. On each webhook, fetch the subscriber from RevenueCat and persist the resulting tier instead of interpreting every event independently.
7. Test initial purchase, renewal, cancellation, expiration, billing issue, upgrade, downgrade, refund, restore, reinstall, and account switching.

## RevenueCat Ad Monetization strategy

RevenueCat Ad Monetization is the authority for ad event tracking, verified rewards, credit grants, entitlement grants, and combined subscription/ad reporting. It is currently a beta feature. It works alongside an ad mediation SDK rather than serving inventory itself. For HardSync Flutter, RevenueCat's documented rewarded flow uses `google_mobile_ads` to render the ad and RevenueCat to verify and grant the reward.

### Format

Use **opt-in rewarded ads only** for the first release. Do not add banners, interstitials, or app-open ads to this coaching product. Calls, lessons, and reflection are high-attention flows; forced ads would reduce trust and can create accidental-click risk.

### Reward and limits

- Reward: **3 credits per completed ad**.
- Daily cap: **2 rewarded ads / 6 credits**.
- Cooldown: **10 minutes** between rewards.
- Free users only. Hide ads for Pro and Ultra.
- Configure the reward rule in RevenueCat: the rewarded ad unit grants **3 TBC**.
- Point the ad unit's SSV callback to RevenueCat's shared endpoint: `https://api.revenuecat.com/v1/incoming-webhooks/admob-ssv-rewarded`.
- Generate a RevenueCat reward-verification token after the Flutter ad loads and attach its user ID and custom data to the ad's SSV options.
- After the earned-reward callback, poll RevenueCat with the client transaction ID.
- Update the UI only when RevenueCat returns a verified currency reward. RevenueCat performs the server-side grant and invalidates its currency cache.
- Show the exact reward before the user opts in.
- Never reward a click, install, or advertiser conversion; the reward is for completing eligible rewarded inventory.

Three credits are meaningful progress toward a 5-credit text rehearsal without letting ad revenue subsidize expensive audio or video sessions. Treat this as an initial hypothesis. Recalculate quarterly from actual rewarded-ad revenue by country and provider cost.

### Placement

Good placements:

- Credit store: â€œWatch an ad Â· earn 3 credits.â€
- Insufficient-credit sheet after the user intentionally tries to start text practice.
- Post-session completion screen as an optional replenishment action.

Do not place ads:

- During onboarding, sign-up, login, purchase, or restore.
- In a lesson or knowledge check.
- In text, audio, or video practice.
- Next to navigation, primary buttons, message fields, or call controls.
- Between scrolling course cards.
- As a surprise when the app opens or returns to foreground.

Use stable RevenueCat placements: `credit_store_rewarded`, `insufficient_text_credits_rewarded`, and `session_complete_rewarded`. Report loaded, displayed, opened, revenue, and failed-to-load events with the same impression ID. RevenueCat then exposes impressions, CTR, eCPM, fill rate, revenue, and monetized-customer reporting beside subscription data.

## New-account experience

Expected state sequence:

1. Three-page illustrated onboarding.
2. Authentication choice: Apple, Google, or email.
3. Email verification state when required.
4. Goal and role selection.
5. Account creation creates the Supabase profile and grants exactly 30 starter credits once.
6. RevenueCat identifies the customer with the Supabase UUID.
7. Home opens with empty progress, zero completed lessons, no streak, no session history, and a starter recommendation.
8. Learn shows the complete catalog with progress at zero.
9. Practice shows text available; audio and video explain their plan requirement.
10. Profile shows Free, 30 credits, account management, privacy, restore purchases, and delete account.

Current implementation status: the app launches directly into `AppShell`; onboarding exists as a secondary screen and is not yet a persisted first-launch gate. This must be completed before release.

## Source of truth and data location

| Data | Current location | Production target |
|---|---|---|
| User identity and profile | Supabase Auth + `profiles` | Supabase |
| Course catalog | Bundled Dart content | Bundled/versioned content or CMS |
| Course progress | Primarily UI/demo state | Supabase, per user |
| Subscription purchase | RevenueCat Test Store client | RevenueCat + verified backend/webhook |
| Subscription tier | RevenueCat client plus local Python lookup | RevenueCat entitlement mirrored to Supabase |
| Credits | Python SQLite charge ledger plus a stale Supabase column | One server ledger; preferably RevenueCat In-App Currency |
| Session reports/transcripts | Python SQLite and direct client inserts to Supabase | Backend writes to Supabase |
| Recordings | Local `server/.state` media | Backend upload to private R2, signed playback URLs |
| R2 URL | No confirmed upload at present | Persist only after successful upload |

The current local Python/SQLite server is suitable for local development, not multi-instance production. It has no shared transaction store, durable job queue, production webhook endpoint, or confirmed R2 upload. Direct client inserts into Supabase are protected by RLS but should move behind the backend for a single consistent session transaction.

## State and failure matrix

| Flow | Required states |
|---|---|
| Auth | idle, submitting, verification required, authenticated, invalid credentials, network error, provider cancelled |
| Offerings | loading, available, empty offering, unavailable, stale cached offering |
| Purchase | purchasing, success, user cancelled, pending, declined, already owned, network error |
| Restore | restoring, restored, nothing found, unsupported on web, error |
| Subscription | active, trial, grace period, billing issue, cancelled but active, expired, refunded |
| Credits | loading, loaded, insufficient, reserving, reserved, refunded, purchase pending, reward pending, offline |
| Ad | loading, ready, unavailable, opened, earned, dismissed without reward, SSV pending, SSV duplicate |
| Recording | disabled, recording, uploading, local ready, R2 uploaded, upload failed, replay expired |
| New account | empty profile, empty history, empty progress, starter credits granted, grant already applied |

## Verified findings on 25 September 2026

- RevenueCat Flutter SDK dependency is present and meets the Test Store minimum version.
- Only a Test Store key is configured. Apple, Google, and web production public keys are empty.
- The backend RevenueCat secret is absent, so server-side entitlement verification cannot work in the current environment.
- RevenueCat Ad Monetization is not integrated yet. The Flutter ad-rendering dependency and rewarded ad units are also not configured, so rewarded ads correctly award zero credits today.
- Supabase URL and publishable key are configured.
- R2 credentials and a public domain are present on the backend, but the server does not perform an R2 upload. Local recording playback works; cloud playback is not implemented.
- A later Supabase migration had restored broad profile grants. A repair migration now prevents clients from updating billing fields.
- Paid tier mutation from the client is now rejected outside local test mode.
- Credits shown in the app now come from the same backend that reserves and refunds session credits.
- RevenueCat identity now follows the Supabase UUID on sign-in and returns to anonymous state on sign-out.

## Launch gates

- Configure real store products, entitlements, offering, tax, regional prices, and subscription disclosures.
- Add backend secret management, RevenueCat webhook, and verified credit ledger.
- Enable RevenueCat Ads beta, connect the AdMob account, sync rewarded ad units, and create the 3 TBC reward rule.
- Add the Flutter ad-rendering SDK, consent flow, development test units, RevenueCat verification-token/poll flow, and the app-side daily availability limit.
- Implement actual private R2 upload and signed replay delivery.
- Add a persisted first-launch onboarding/auth gate and server-side one-time starter grant.
- Move session persistence from direct client writes and local SQLite to the production backend/Supabase.
- Run real device sandbox tests for Apple and Google. Web requires a configured RevenueCat Billing, Stripe Billing, or Paddle Billing engine.

## Primary references

- RevenueCat products and offerings: https://www.revenuecat.com/docs/projects/configuring-products
- RevenueCat Flutter setup and web limits: https://www.revenuecat.com/docs/getting-started/installation/flutter
- RevenueCat customer identity: https://www.revenuecat.com/docs/customers/identifying-customers
- RevenueCat Test Store: https://www.revenuecat.com/docs/test-and-launch/sandbox/test-store
- RevenueCat In-App Currency: https://www.revenuecat.com/docs/offerings/virtual-currency
- RevenueCat webhooks: https://www.revenuecat.com/docs/integrations/webhooks
- RevenueCat Ad Monetization: https://www.revenuecat.com/docs/ad-monetization
- RevenueCat verified ad rewards: https://www.revenuecat.com/docs/ad-monetization/rewards
- RevenueCat manual ad tracking: https://www.revenuecat.com/docs/ad-monetization/manual-integration
- Google rewarded ads for Flutter: https://developers.google.com/admob/flutter/rewarded
- Google AdMob placement guidance: https://support.google.com/admob/answer/2936217
- Apple App Review Guidelines 3.1.1: https://developer.apple.com/app-store/review/guidelines/
- Google Play Payments policy: https://support.google.com/googleplay/android-developer/answer/9858738
