// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

class TtsService {
  void speak(String text, {double pitch = 1.0, double rate = 1.0}) {
    try {
      final synth = html.window.speechSynthesis;
      if (synth == null) return;
      synth.cancel();

      final utterance = html.SpeechSynthesisUtterance(text)
        ..rate = rate
        ..pitch = pitch
        ..lang = 'en-US';

      final voices = synth.getVoices();
      if (voices.isNotEmpty) {
        final enVoice = voices.firstWhere(
          (v) => (v.lang?.startsWith('en') ?? false),
          orElse: () => voices.first,
        );
        utterance.voice = enVoice;
      }

      synth.speak(utterance);
    } catch (_) {}
  }

  void stop() {
    try {
      html.window.speechSynthesis?.cancel();
    } catch (_) {}
  }
}
