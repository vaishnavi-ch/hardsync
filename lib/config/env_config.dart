import 'dart:convert';
import 'package:http/http.dart' as http;

/// Centralized configuration that loads credentials transparently.
/// End-users are never prompted for API keys in the UI.
class EnvConfig {
  static final Map<String, String> _env = {};
  static bool _initialized = false;
  static bool get testCalls => _env['TEST_CALLS'] == 'true';
  static Future<void> init() async {
    if (_initialized) return;
    try {
      const base = String.fromEnvironment(
        'BACKEND_URL',
        defaultValue: 'https://hardsync.onrender.com',
      );
      final uri = Uri.parse(base).resolve('/api/config');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200 && !response.body.trim().startsWith('<')) {
        (jsonDecode(response.body) as Map<String, dynamic>).forEach(
          (k, v) => _env[k] = '$v',
        );
      }
    } catch (_) {}
    _initialized = true;
  }

  static bool get hasGeminiKey => _env['HAS_GEMINI'] == 'true';

  // --- SUPABASE CONFIGURATION ---
  static const _defaultSupabaseUrl = 'https://reqwhdhkpazfvvefvsnv.supabase.co';
  static const _defaultSupabaseAnonKey = 'sb_publishable_VRnfgnMucLLuO7CJdre_yA_CAXQhjNH';

  static String get supabaseUrl {
    const fromDefine = String.fromEnvironment('SUPABASE_URL');
    if (fromDefine.isNotEmpty) return fromDefine;
    final inMap = _env['SUPABASE_URL'] ?? _env['NEXT_PUBLIC_SUPABASE_URL'];
    if (inMap != null && inMap.trim().isNotEmpty) return inMap.trim();
    return _defaultSupabaseUrl;
  }

  static String get supabaseAnonKey {
    const fromDefine = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (fromDefine.isNotEmpty) return fromDefine;
    final inMap =
        _env['SUPABASE_ANON_KEY'] ??
        _env['NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY'] ??
        _env['SUPABASE_PUBLISHABLE_KEY'] ??
        _env['NEXT_PUBLIC_SUPABASE_ANON_KEY'];
    if (inMap != null && inMap.trim().isNotEmpty) return inMap.trim();
    return _defaultSupabaseAnonKey;
  }

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  // --- REVENUECAT CONFIGURATION ---
  static const _defaultUseTestStore = true;
  static const _defaultRevenueCatTestStoreKey = 'test_OIDobrEmvzshDcQyHUTygCqVdOp';

  static bool get useRevenueCatTestStore {
    const fromDefine = String.fromEnvironment('REVENUECAT_USE_TEST_STORE');
    if (fromDefine.isNotEmpty) return fromDefine.toLowerCase() == 'true';
    final fromEnv = _env['REVENUECAT_USE_TEST_STORE'];
    if (fromEnv != null) return fromEnv.toLowerCase() == 'true';
    // Fallback: always use Test Store in non-release builds
    return _defaultUseTestStore;
  }

  static String get revenueCatTestStoreKey {
    const fromDefine = String.fromEnvironment('REVENUECAT_TEST_STORE_KEY');
    if (fromDefine.isNotEmpty) return fromDefine;
    final inMap =
        _env['REVENUECAT_TEST_STORE_KEY'] ?? _env['REVENUECAT_API_KEY'];
    if (inMap != null && inMap.trim().isNotEmpty) return inMap.trim();
    return _defaultRevenueCatTestStoreKey;
  }

  static String get revenueCatAppleKey {
    const fromDefine = String.fromEnvironment(
      'REVENUECAT_PUBLIC_SDK_KEY_APPLE',
    );
    if (fromDefine.isNotEmpty) return fromDefine;
    return _env['REVENUECAT_PUBLIC_SDK_KEY_APPLE']?.trim() ?? '';
  }

  static String get revenueCatGoogleKey {
    const fromDefine = String.fromEnvironment(
      'REVENUECAT_PUBLIC_SDK_KEY_GOOGLE',
    );
    if (fromDefine.isNotEmpty) return fromDefine;
    return _env['REVENUECAT_PUBLIC_SDK_KEY_GOOGLE']?.trim() ?? '';
  }

  static String get revenueCatWebKey {
    const fromDefine = String.fromEnvironment('REVENUECAT_PUBLIC_SDK_KEY_WEB');
    if (fromDefine.isNotEmpty) return fromDefine;
    return _env['REVENUECAT_PUBLIC_SDK_KEY_WEB']?.trim() ?? '';
  }

  static bool get isRevenueCatConfigured =>
      (useRevenueCatTestStore && revenueCatTestStoreKey.isNotEmpty) ||
      revenueCatAppleKey.isNotEmpty ||
      revenueCatGoogleKey.isNotEmpty ||
      revenueCatWebKey.isNotEmpty;

  /// Diagnostic status
  static Map<String, dynamic> get diagnosticStatus => {
    'hasGeminiKey': hasGeminiKey,
    'isSupabaseConfigured': isSupabaseConfigured,
    'isRevenueCatConfigured': isRevenueCatConfigured,
  };
}
