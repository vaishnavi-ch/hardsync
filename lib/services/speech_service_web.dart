// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:js' as js;
import 'package:flutter/foundation.dart';

class SpeechRecognitionService {
  bool _isListening = false;
  Function(String text)? onTranscript;
  Function(String partial)? onPartialTranscript;
  Function(int wpm)? onWpmUpdate;
  Function(String filler)? onFillerDetected;
  int _wordCount = 0;
  DateTime? _speechStartTime;
  dynamic _recognitionInstance;

  Timer? _silenceTimer;
  String _pendingUtterance = '';
  String _lastDispatched = '';

  bool get isListening => _isListening;

  void startListening({
    required Function(String text) onResult,
    Function(int wpm)? onWpm,
    Function(String filler)? onFiller,
    Function(String partial)? onPartial,
  }) {
    onTranscript = onResult;
    onPartialTranscript = onPartial;
    onWpmUpdate = onWpm;
    onFillerDetected = onFiller;
    _wordCount = 0;
    _speechStartTime = DateTime.now();

    try {
      final hasRecognition =
          js.context.hasProperty('webkitSpeechRecognition') ||
          js.context.hasProperty('SpeechRecognition');

      if (hasRecognition) {
        final recognitionClass =
            js.context['webkitSpeechRecognition'] ??
            js.context['SpeechRecognition'];
        final recognition = js.JsObject(recognitionClass as js.JsFunction);
        _recognitionInstance = recognition;

        recognition['continuous'] = true;
        recognition['interimResults'] = true;
        recognition['lang'] = 'en-US';

        recognition['onresult'] = (dynamic event) {
          final results = event['results'];
          final length = results['length'] as int;
          if (length > 0) {
            final lastResult = results[length - 1];
            final transcript = (lastResult[0]['transcript'] as String).trim();
            final isFinal = lastResult['isFinal'] == true;

            _handleWords(transcript);
            onPartialTranscript?.call(transcript);

            if (isFinal && transcript.isNotEmpty) {
              _silenceTimer?.cancel();
              _dispatchUtterance(transcript);
            } else if (transcript.isNotEmpty) {
              _pendingUtterance = transcript;
              _silenceTimer?.cancel();
              _silenceTimer = Timer(const Duration(milliseconds: 1400), () {
                if (_pendingUtterance.isNotEmpty) {
                  _dispatchUtterance(_pendingUtterance);
                }
              });
            }
          }
        };

        bool hadError = false;

        recognition['onerror'] = (dynamic error) {
          hadError = true;
          _isListening = false;
          debugPrint('[SpeechRecognitionService] error (quieted): $error');
        };

        recognition['onend'] = (dynamic _) {
          if (_isListening && !hadError) {
            Timer(const Duration(milliseconds: 800), () {
              if (_isListening && !hadError) {
                try {
                  recognition.callMethod('start');
                } catch (_) {}
              }
            });
          }
        };

        hadError = false;
        recognition.callMethod('start');
        _isListening = true;
      }
    } catch (e) {
      debugPrint('[SpeechRecognitionService] init error: $e');
    }
  }

  DateTime? _lastDispatchedTime;

  void _dispatchUtterance(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return;
    if (clean == _lastDispatched &&
        _lastDispatchedTime != null &&
        DateTime.now().difference(_lastDispatchedTime!).inMilliseconds < 1200) {
      return;
    }
    _lastDispatched = clean;
    _lastDispatchedTime = DateTime.now();
    _pendingUtterance = '';
    debugPrint('[SpeechRecognitionService] Finalized utterance: $clean');
    onTranscript?.call(clean);
  }

  void _handleWords(String transcript) {
    final words = transcript.trim().split(RegExp(r'\s+'));
    _wordCount += words.length;

    if (_speechStartTime != null) {
      final elapsedSeconds = DateTime.now()
          .difference(_speechStartTime!)
          .inSeconds;
      if (elapsedSeconds > 3) {
        final elapsedMinutes = elapsedSeconds / 60.0;
        final wpm = (_wordCount / elapsedMinutes).round().clamp(60, 240);
        onWpmUpdate?.call(wpm);
      }
    }

    final lower = transcript.toLowerCase();
    for (final filler in ['um', 'uh', 'like', 'sort of', 'you know', 'sorry']) {
      if (lower.contains(filler)) {
        onFillerDetected?.call(filler);
      }
    }
  }

  void stopListening() {
    _silenceTimer?.cancel();
    try {
      if (_recognitionInstance != null) {
        _recognitionInstance.callMethod('stop');
      }
    } catch (_) {}
    _isListening = false;
  }
}
