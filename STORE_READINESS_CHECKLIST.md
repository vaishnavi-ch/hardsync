# HardSync store readiness checklist

Updated: 26 September 2026

## Completed without store-console access

- [x] Audited Android/iOS app configuration against current store guidance.
- [x] Added clear camera and microphone purpose strings.
- [x] Kept camera and microphone hardware optional on Android.
- [x] Added purchase cancellation handling and Restore Purchases.
- [x] Added RevenueCat Customer Center access on configured native builds.
- [x] Added a direct Manage Store Subscription action before account deletion.
- [x] Removed the false claim that account deletion cancels store billing.
- [x] Replaced hard-coded active renewal/trial claims with store-managed wording.
- [x] Changed plan cards to use RevenueCat localized `priceString` when an offering is available.
- [x] Added functional in-app Privacy Policy and Terms screens.
- [x] Added deployable `/privacy.html`, `/terms.html`, and `/account-deletion.html` web resources.
- [x] Added an authenticated Supabase `delete-account` Edge Function.
- [x] Account deletion removes custom scenarios, cascaded Supabase records, and the Auth user. Call audio/video are not stored by HardSync.
- [x] Kept rewarded credit issuance behind RevenueCat reward verification.
- [x] Kept Google test rewarded-unit IDs limited to debug fallback in Dart configuration.
- [x] Added a production data map for Play Data safety and App Store Privacy.
- [x] Added reviewer access notes and an end-to-end review script.
- [x] Added iOS Podfile and matched native launch backgrounds to HardSync styling.
- [x] Improved web startup and lazy tab construction.
- [x] Rebranded app display name, Flutter package, Android/iOS identifiers, native method channels, and OAuth scheme to HardSync.
- [x] Built Android debug APK and confirmed package ID `com.hardsync.mobile`, label `HardSync`, and target API 36 in APK metadata.
- [x] Configured Android release builds to require a private upload key instead of signing with the debug key; signing credentials and keystore paths are Git-ignored.
- [x] Set the iOS team to `DZSQU87XUV` with automatic signing for Runner build configurations.
- [ ] Revalidate Web and Windows release builds after the HardSync package rename.

## Ready to configure when accounts exist

- [ ] Register `com.hardsync.mobile` as an Explicit App ID in Apple Developer; confirm it is available to this team.
- [ ] Create Google Play and App Store Connect records with `com.hardsync.mobile`.
- [ ] Generate and securely back up the Android upload keystore, fill local `android/key.properties`, enroll in Play App Signing, and register upload/app-signing certificate fingerprints with Google OAuth and API restrictions.
- [ ] Register the explicit App ID `com.hardsync.mobile` under team `DZSQU87XUV`; enable Sign in with Apple and confirm In-App Purchase is available. Configure Apple certificates and provisioning in Xcode on macOS.
- [ ] Create Apple/Google subscription products and attach them to RevenueCat offerings and entitlements.
- [ ] Supply production RevenueCat public SDK keys.
- [ ] Create production Google Mobile Ads app and rewarded-unit IDs; separate them from debug IDs.
- [ ] Configure Google Mobile Ads consent choices and determine whether iOS ATT is required.
- [ ] Publish the web build on the final HTTPS domain and enter its privacy/deletion URLs in both consoles.
- [ ] Replace the placeholder support contact in the public legal pages with a verified monitored address or form.
- [ ] Configure and verify Sign in with Apple token revocation during account deletion.
- [ ] Deploy the `delete-account` Edge Function and verify account/data deletion using a disposable user.
- [ ] Complete Google Ads, Data safety, target audience, content rating, app access, and account deletion declarations.
- [ ] Complete Apple App Privacy, age rating, export compliance, content rights, and review information.
- [ ] Generate final screenshots and previews from release builds.
- [ ] Replace debug signing, build a signed Android App Bundle, and upload it to internal testing.
- [ ] Archive on macOS/Xcode, inspect the aggregate privacy report, and add any app-owned required-reason API declarations.
- [ ] Upload to TestFlight and execute the reviewer script on physical Android and iOS devices.

## Apple Developer registration values

- Description: `HardSync`
- Bundle ID type: Explicit
- Bundle ID: `com.hardsync.mobile`
- Team/App ID Prefix: `DZSQU87XUV`
- Capability: Sign in with Apple (the app presents Apple sign-in)
- In-App Purchase: leave enabled if Apple preselects it; the app sells subscriptions and consumable credits through the stores.
- Other capabilities: leave disabled unless a shipped feature needs one.

## Cannot be truthfully completed before account access

Signing identities, permanent app identifiers, production billing products, localized live prices, tax/banking agreements, store privacy forms, store age ratings, production ad identifiers, sandbox transactions, TestFlight, Play internal testing, and final store validation all depend on Google/Apple console access.
