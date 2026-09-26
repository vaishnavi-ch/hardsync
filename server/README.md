# HardSync backend

The Flutter application is the client. This directory contains private API services that use Gemini for text, live audio/video, and analysis, RevenueCat for entitlements, and Supabase for user data.

## Local development

From the project root:

```powershell
python tools/run_dev.py
```

The launcher starts the HTTP API, Gemini Live WebSocket bridge, and Flutter. The local ports are development addresses only. The API does not use SQLite or a local application database: account, session, transcript, and report state is stored in Supabase. Call audio and video are streamed live to Gemini and are not recorded or stored by HardSync.

Required local variables are documented in `.env.example`. Gemini keys stay on the API and Live bridge servers; never include them in Flutter build arguments or public assets.

The former `--test-calls` bypass has been removed. Test with a real Supabase test user and RevenueCat Test Store so authentication, RLS, entitlements and session handling follow the production path.

## Storage ownership

- Supabase Auth: identity and sessions
- Supabase Postgres: profiles, learning progress, practice sessions, turns, reports, and analyses
- Gemini Live: live audio/video streams for active sessions only
- Recording uploads are disabled by the API and rejected with HTTP 410

Text, audio, and video sessions reserve an active-session slot using an atomic Supabase function. Failed unconnected sessions release that slot. Stale reservations expire after eleven minutes.

## Services

### HTTP API

```powershell
python server/app.py --port 8082
```

### Gemini Live bridge

```powershell
python -m uvicorn server.gemini_live_bridge:app --host 127.0.0.1 --port 8000
```

The bridge validates a five-minute signed ticket, authenticates the signed-in user, reads the user's session through Supabase RLS, and keeps Google credentials server-side.

## Cloud deployment

See [DEPLOYMENT.md](../DEPLOYMENT.md). `render.yaml` defines both services and prompts for secrets in Render instead of committing them.

## Verification

```powershell
python -m py_compile server/app.py server/gemini_live_bridge.py
python -m unittest discover -s server -p test_app.py -v
flutter test --no-pub
dart analyze lib test
```
