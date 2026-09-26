# HardSync store submission compliance audit

Audit date: 26 September 2026

Scope: Flutter source and configuration, Android/iOS manifests, account lifecycle, policies, monetization, and public review preparation. Store-console values and live provider configuration cannot be inspected from the repository.

## Verdict

**Not ready to submit to production review.** The source has useful foundations (account deletion UI and Edge Function, legal screens, camera/microphone purpose strings, purchase restoration, and review notes), but permanent identity/signing, published support/legal URLs, external service configuration, store declarations, and native device validation remain open.

## Current findings

| Area | Status | Evidence / action |
|---|---|---|
| App identity | Configure externally | Android and iOS project identifiers are now `com.hardsync.mobile`. Register this exact Explicit App ID in Apple Developer and create the Play app with the same package ID; confirm Apple accepts it for your team before uploading. Update OAuth/provider configuration to match. |
| Android release signing | Blocked | `android/app/build.gradle.kts` signs release with the debug key. Configure a protected upload key and Play App Signing; never commit the key or passwords. |
| iOS signing and capabilities | Blocked | Bundle ID is set to `com.hardsync.mobile`. Register the matching explicit App ID, enable Sign in with Apple (the app offers it), configure distribution signing/provisioning, and create the App Store Connect record. In-App Purchase is enabled by default for an explicit App ID. Xcode is not installed here, so an archive has not been verified. |
| Android target API | Verified in debug APK | Gradle targets and compiles against API 36. `aapt` confirmed the built debug APK reports package `com.hardsync.mobile`, target SDK 36, and app label HardSync. The release AAB was blocked while resolving dependencies because Java could not validate the remote certificate chain. |
| Privacy/terms | Needs publication | In-app legal screens and static web pages exist. Publish them at stable HTTPS URLs, enter the privacy URL in both stores, and add a verified monitored developer support contact to store metadata. The policy now says live call audio/video is streamed to the provider and not stored by HardSync. Verify provider retention terms. |
| Account deletion | Implemented, deployment unverified | Authenticated `supabase/functions/delete-account/index.ts` removes user rows and the Auth user. Call media is not stored by HardSync. Deploy the function and test it with a disposable user. Publish the account-deletion URL and verify the browser request path end-to-end. Apple Sign in with Apple revocation is not implemented in the inspected function if that login method is enabled. |
| Data disclosures | Console task | Use `STORE_PRIVACY_DATA_MAP.md` plus final production SDK behavior to complete Google Data safety and Apple App Privacy. Confirm streamed media handling, ads identifiers/personalization, diagnostics, provider retention, processors, and whether tracking applies. |
| Camera/microphone | Conditional | iOS purpose strings and Android permissions exist; Android hardware is optional. Verify prompts occur only on user-initiated voice/video entry and denied-permission fallbacks work. |
| Subscriptions | Console/device task | RevenueCat flow and restore code exist. Configure real products, localized prices, offers, entitlements, and customer-center behavior in both stores and RevenueCat; verify purchase, restore, cancellation, expiration, and refund on TestFlight and Play testing. |
| Ads/rewarded credits | Console/device task | Configure production ad IDs and required consent/child treatment; verify Google Play â€œcontains adsâ€ declaration and App Store disclosures. Confirm rewards are credited only after server-verified idempotent events. |
| Reviewer access | Incomplete | `STORE_REVIEWER_NOTES.md` has placeholders. Supply reusable credentials and precise paths in Play Console and App Store Connect; make gated features reviewable. |
| Metadata and rating | Incomplete | Set app name, descriptions, category, age/content ratings, privacy/support URLs, screenshots, copyright/content rights, export compliance, and review contact. |
| Native quality validation | Partial | Android debug APK builds successfully. Android release AAB could not resolve uncached dependencies due a Java PKIX certificate-chain failure. iOS archive cannot be built here because Xcode is unavailable. Physical-device review flows remain untested. |

## HardSync rebrand and verification record

- App label and web/legal/documentation branding: **HardSync**.
- Android application ID and namespace: `com.hardsync.mobile`.
- iOS Bundle ID and test target IDs: `com.hardsync.mobile` and `com.hardsync.mobile.RunnerTests`.
- Flutter package name: `hardsync`; OAuth callback scheme: `hardsync://`.
- Android debug APK build: passed. APK metadata confirms app ID, HardSync label, compile SDK 36, and target SDK 36.
- Python backend tests: 13 passed.
- `dart analyze lib`: no errors; eight unused-code warnings remain in `learning_screen.dart`.
- `dart analyze lib test`: test sources report nine API/missing-symbol errors across `call_flow_test.dart` and `widget_test.dart`; the test suite is not currently analyzer-clean.
- `flutter test --no-pub`: did not complete in this environment.
- Android release AAB: blocked on remote dependency SSL certificate validation. Android release signing is still configured to use the debug key and must be replaced before submission.
- Online name search did not surface an obvious HardSync app listing in the queried results. This is not store-name reservation or trademark clearance; verify in both developer consoles and trademark databases before launch.

## Recommended order now that developer accounts are available

1. Register `com.hardsync.mobile` as an Explicit App ID in Apple Developer and confirm the identifier is accepted. Enable Sign in with Apple. Create the Google Play and App Store Connect records with this exact ID. Choose a monitored support contact.
2. Configure Supabase production OAuth redirect URLs and Apple/Google sign-in capabilities; configure RevenueCat store apps and production entitlements/products.
3. Publish the web site on the final HTTPS domain. Set privacy policy, terms, support, and account deletion URLs in both consoles; replace support metadata with a monitored contact.
4. Configure Android upload signing/Play App Signing and Apple signing/capabilities. Keep signing and provider secrets in protected environment/secret storage.
5. Deploy Supabase migrations/functions and production secrets. Test account and media deletion, including partial failures and social-login revocation if applicable.
6. Build Android App Bundle with target API 36; validate the final resolved target and SDK warnings. Archive with supported Xcode and review the privacy manifest report.
7. Configure products, ads, consent, and billing, then run closed/internal Play testing and TestFlight on real devices.
8. Complete Data safety/App Privacy, ads declaration, audience/content ratings, export compliance, reviewer access, metadata, screenshots, and review notes from production behavior.
9. Submit only after Play pre-review and App Store Connect validations are clear and deletion, sign-in, camera/mic, purchase/restore, and error states pass on release builds.

## Account-specific note

If the Google developer account is a personal account created after 13 November 2023, Google requires a closed test with at least 12 testers opted in continuously for 14 days before requesting production access. Check Play Console account eligibility; this does not apply identically to every account type.

## Official references

- [Google Play target API requirements](https://support.google.com/googleplay/android-developer/answer/11926878)
- [Google Play account deletion requirements](https://support.google.com/googleplay/android-developer/answer/13327111)
- [Google Play reviewer sign-in details](https://support.google.com/googleplay/android-developer/answer/15748846)
- [Google Play publishing](https://support.google.com/googleplay/android-developer/answer/9859751)
- [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Apple app privacy disclosures](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy)
- [Apple app information requirements](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information)
- [Apple account deletion requirement](https://developer.apple.com/support/offering-account-deletion-in-your-app/)
