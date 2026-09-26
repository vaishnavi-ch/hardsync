// dart.library.io is unavailable on Flutter Web but true on every native
// platform (Android, iOS, desktop). Checking it first is required: recent
// Dart SDKs also expose dart.library.js_interop on native platforms, so
// checking that condition first was silently routing every native build
// (including Android) to the web implementation instead of this native one.
export 'gemini_live_embed_stub.dart'
    if (dart.library.io) 'gemini_live_embed_native.dart'
    if (dart.library.js_interop) 'gemini_live_embed_web.dart';
