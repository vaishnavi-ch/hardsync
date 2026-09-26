# HardSync â€” Leadership Flight Simulator & Executive Presence Sanctuary

Rehearse critical leadership conversations in a safe, private flight deck before walking into the real room.

---

## Documentation Quick Links
- **[DOCUMENTATION.md](DOCUMENTATION.md)**: Repository guide covering architecture, technologies, source layout, current implementation, limitations, and follow-up work.
- **[PRD.md](PRD.md)**: Product requirements, user stories, acceptance criteria, scope, release gates, and open decisions.
- **[PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md)**: Comprehensive architectural guide, full feature breakdown, user journey, and technical specifications.
- **[web_mockups/index.html](web_mockups/index.html)**: Interactive mobile design mockup studio implementing unboxed spatial art direction (Joyce & Poster Art synthesis).
- **[server/README.md](server/README.md)**: Local Python backend setup and execution instructions.
- **[IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md)**: Verification test reports, provider integration status, and security compliance.
- **[CODEBASE_AUDIT.md](CODEBASE_AUDIT.md)**: Detailed source code and architecture audit.
- **[site/public/index.html](site/public/index.html)**: Static marketing site — landing page, FAQ, Terms, Privacy, and account deletion. Deploy the `site/public` folder as-is to any static host.

---

## Quick Preview
Preview the mobile interactive design studio:
```powershell
python -m http.server 8089
```
Then visit: **http://localhost:8089/web_mockups/index.html**

## Run the Flutter web app

The installed Flutter 3.35.2 Chrome debugger is incompatible with the current
Chrome execution-context protocol and can fail with `Cannot send Null` or
`Failed to start Dart Development Service`. Run the app through Flutter's web
server target:

```powershell
.\scripts\run_web.ps1
```

Then open **http://localhost:8091**. This keeps hot reload available and avoids
the crashing Chrome debugger bridge.
