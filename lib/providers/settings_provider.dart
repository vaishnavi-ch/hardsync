import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  bool _cameraEnabled = true;
  bool _micEnabled = true;

  bool get cameraEnabled => _cameraEnabled;
  bool get micEnabled => _micEnabled;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in [
      'liveavatar_api_key',
      'heygen_api_key',
      'gemini_api_key',
      'is_sandbox_mode',
      'use_live_cloud_ai',
    ]) {
      await prefs.remove(key);
    }
    _cameraEnabled = prefs.getBool('camera_enabled') ?? true;
    _micEnabled = prefs.getBool('mic_enabled') ?? true;
    notifyListeners();
  }

  Future<void> toggleCamera() async {
    _cameraEnabled = !_cameraEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('camera_enabled', _cameraEnabled);
    notifyListeners();
  }

  Future<void> toggleMic() async {
    _micEnabled = !_micEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mic_enabled', _micEnabled);
    notifyListeners();
  }
}
