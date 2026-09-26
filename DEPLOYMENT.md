# HardSync online deployment

## What runs where

- Flutter is the client installed on Android/iOS or published as a web build.
- Supabase stores accounts, profiles, catalog data, progress, credits, practice sessions, transcripts, reports, and analyses.
- `hardsync-api` keeps Gemini and RevenueCat credentials private.
- `hardsync-live` maintains long-running Gemini Live WebSocket connections.
- Live call audio and video are streamed to Gemini Live and are not stored by HardSync.

The two Python processes are cloud services. A user never starts them and never sees ports 8082 or 8000.

## Deploy the backend on Render

1. Push this repository to GitHub.
2. Open the Render dashboard and choose **New â†’ Blueprint**.
3. Connect the repository. Render reads `render.yaml` and creates `hardsync-api` and `hardsync-live`.
4. Add every secret marked `sync: false` in the Render dashboard. Never commit their values.
5. Set the same random `GEMINI_LIVE_SHARED_SECRET` on both services.
6. Set `GEMINI_LIVE_BRIDGE_URL` on `hardsync-api` to:

   `wss://<hardsync-live-host>/api/gemini-live`

7. Set `ALLOWED_ORIGINS` to the comma-separated Flutter web origins. Native apps do not send a browser Origin header.
8. Set the Supabase publishable key on the API and Live services. The Live bridge uses the signed-in user's access token and Supabase row-level security to read session context; it does not need a service-role key.
9. Point RevenueCat's webhook to:

   `https://<hardsync-api-host>/api/webhooks/revenuecat`

10. Use a long random Authorization value for both RevenueCat's webhook configuration and `REVENUECAT_WEBHOOK_AUTHORIZATION`.

Render prompts for `sync: false` secrets when a Blueprint is first created, as described in its Blueprint documentation.

## Build Flutter against the online API

### Android upload signing

Release builds use an upload key and never the Android debug key. Create the upload keystore and keep its passwords private. Copy `android/key.properties.example` to `android/key.properties`, set `storeFile` to the keystore path relative to the `android` directory, then fill in the alias and passwords. Both the properties file and keystore are ignored by Git. Enroll the app in Play App Signing when creating the Play listing; upload the signed AAB with the upload key.

The signing certificate's SHA-1 and SHA-256 fingerprints are needed for Google sign-in and other API restrictions. Obtain them from the upload keystore and also add the Play App Signing app-signing certificate fingerprints from Play Console after enrollment.

Web:

```powershell
flutter build web --release --dart-define=BACKEND_URL=https://<hardsync-api-host>
```

Android:

```powershell
flutter build appbundle --release --dart-define=BACKEND_URL=https://<hardsync-api-host>
```

iOS:

```bash
flutter build ipa --release --dart-define=BACKEND_URL=https://<hardsync-api-host>
```

Publish `build/web` on Cloudflare Pages, Render Static Sites, or another static host. Add that exact HTTPS origin to `ALLOWED_ORIGINS`.

## Local development

`python tools/run_dev.py` starts all local processes. Local ports exist only for development. The same code writes permanent application state to Supabase; SQLite is not used.

## Required Supabase secret

Copy the project's server-side service role key from Supabase **Project Settings â†’ API Keys** into the two cloud services. This key bypasses RLS and is used only for verified RevenueCat events and for loading a signed Gemini Live session. It must never be exposed to Flutter.
