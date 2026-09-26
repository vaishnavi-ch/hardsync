# HardSync production data map

Use this document when completing Google Play Data safety and Apple App Privacy. Recheck it after every SDK or backend change.

| Data | Purpose | Linked to user | Main processors | Deletion |
|---|---|---:|---|---|
| Email, auth identity, user ID | Account authentication | Yes | Supabase; OAuth provider | Auth user deletion |
| Name, avatar, role, goals, settings | Profile and personalization | Yes | Supabase | Profile cascade |
| Course progress and achievements | Learning functionality | Yes | Supabase | Profile cascade |
| Practice text and transcripts | AI practice and feedback | Yes | Supabase, Gemini | Session/profile cascade |
| Live audio/video streams | Deliver user-initiated voice/video practice | Streamed to provider; not stored by HardSync | Gemini, Tavus/Daily | Not retained by HardSync; verify provider retention terms |
| AI analysis and session scores | Coaching feedback and progress | Yes | Gemini, Supabase | Session/profile cascade |
| Subscription product, transaction and entitlement state | Purchases and access | Yes | Apple/Google, RevenueCat, Supabase backend | Store financial records follow store/legal retention; local entitlement data removed with account |
| Credit balance and ledger | Feature access, fraud prevention | Yes | Supabase, RevenueCat | Profile cascade; legally required anti-fraud records may be retained if policy is updated |
| Rewarded ad impression/transaction identifiers | Reward verification and advertising | Yes/pseudonymous | Google Mobile Ads, RevenueCat | Provider retention applies; local reward ledger follows account deletion rules |
| Network and technical diagnostics | Security and reliability | Sometimes | Hosting providers, Supabase, Google/Tavus/Daily/RevenueCat | Provider retention schedules |

## Permission declarations

- Camera: user-initiated video rehearsal and optional visual delivery feedback.
- Microphone: user-initiated audio/video rehearsal and vocal delivery feedback.
- Internet: authentication, catalog, AI practice, subscriptions, ads, and sync.
- No location, contacts, SMS, call log, health, photo library, or background location permission is requested by the app manifest.

## Advertising declaration

Google Play answer: **Yes, contains ads**, because users may voluntarily watch rewarded ads. Final tracking and personalization answers depend on the production Google Mobile Ads consent configuration and must match the App Store privacy response.

## Items to reconfirm before submission

- Production SDK versions and their privacy disclosures.
- Whether diagnostics/crash reporting is added.
- Confirm live audio/video provider retention and processing terms.
- Verified support and privacy contact address.
- Regional consent configuration and whether ATT applies.
- Any legally retained purchase or anti-fraud records after account deletion.
