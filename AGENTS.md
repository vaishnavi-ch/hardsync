# Project development guidance

HardSync is a Flutter app for Android and iOS, with Supabase-backed accounts and progress. Mobile voice and video calls are core product flows. Gemini Live is the primary realtime provider; Tavus is the fallback. Keep provider credentials in server environment files and never copy them into Flutter assets or logs.

## Project skills

Use the matching skill under `.agents/skills/` when working on these areas:

- Flutter structure and features: `flutter-apply-architecture-best-practices`
- Responsive screens and navigation: `flutter-build-responsive-layout`, `flutter-setup-declarative-routing`
- Widget and device flows: `flutter-add-widget-test`, `flutter-add-integration-test`
- Dart logic and mocks: `dart-add-unit-test`, `dart-generate-test-mocks`
- Formatting, analysis, and runtime debugging: `dart-run-static-analysis`, `dart-fix-runtime-errors`
- Backend requests: `flutter-use-http-package`
- Android, Flutter, and Google platform documentation: `retrieving-developer-knowledge`
- Supabase: `supabase`, `supabase-postgres-best-practices`

## MCP setup

`.agents/mcp_config.json` configures the Dart MCP server and a project-scoped, read-only Supabase MCP server. Supabase OAuth must be authorized in the MCP client before its tools can connect.
