import 'dart:math';
import '../models/telemetry.dart';

class TelemetryEngine {
  SpeechMetrics _speechMetrics = const SpeechMetrics();
  VisionMetrics _visionMetrics = const VisionMetrics();
  int _avatarDefensiveness =
      65; // 0 (fully yielding) to 100 (hostile/skeptical)

  SpeechMetrics get speechMetrics => _speechMetrics;
  VisionMetrics get visionMetrics => _visionMetrics;
  int get avatarDefensiveness => _avatarDefensiveness;

  // Filler & Hedging Lexicon
  static const List<String> fillerWords = [
    'um',
    'uh',
    'er',
    'ah',
    'like',
    'you know',
    'honestly',
    'basically',
    'literally',
  ];

  static const List<String> hedgingPhrases = [
    'i just feel like',
    'maybe we could',
    'sorry to bother you',
    'i was kind of thinking',
    'if that makes any sense',
    'i am not totally sure but',
    'sorry,',
    'sorry if',
  ];

  static const List<String> boundaryPhrases = [
    'we committed to',
    'the expectation is',
    'i need you to',
    'the deadline remains',
    'friday is firm',
    'let us focus on',
    'i understand your point, but',
    'what we agreed upon',
  ];

  void startSimulation({required int initialDefensiveness}) {
    _avatarDefensiveness = initialDefensiveness;
    _speechMetrics = const SpeechMetrics();
    _visionMetrics = const VisionMetrics();
  }

  void stop() {}

  /// Process new speech transcription turn from user
  Map<String, dynamic> processUserUtterance(
    String text,
    Duration utteranceDuration,
  ) {
    final lower = text.toLowerCase().trim();
    if (lower.isEmpty) {
      return {'fillers': 0, 'hedges': false, 'boundary': false};
    }

    final words = lower.split(RegExp(r'\s+'));
    final wordCount = words.length;

    // 1. Calculate WPM for this turn
    final double seconds = max(1.0, utteranceDuration.inMilliseconds / 1000.0);
    final double turnWpm = (wordCount / seconds) * 60.0;

    // 2. Detect Filler Words
    int detectedFillersInTurn = 0;
    final List<String> foundFillers = [];

    for (var word in words) {
      // Strip punctuation
      final clean = word.replaceAll(RegExp(r'[^\w\s]'), '');
      if (fillerWords.contains(clean)) {
        detectedFillersInTurn++;
        foundFillers.add(clean);
      }
    }

    // 3. Detect Hedging Phrases
    bool hasHedging = false;
    int hedges = 0;
    for (var hedge in hedgingPhrases) {
      if (lower.contains(hedge)) {
        hasHedging = true;
        hedges++;
        foundFillers.add(hedge);
      }
    }

    // 4. Detect Strong Boundary Signals
    bool hasStrongBoundary = false;
    for (var boundary in boundaryPhrases) {
      if (lower.contains(boundary)) {
        hasStrongBoundary = true;
        break;
      }
    }

    // 5. Update cumulative speech metrics
    final totalWords = _speechMetrics.wordsSpoken + wordCount;
    final totalTalkSeconds = _speechMetrics.talkTimeSeconds + seconds.toInt();
    final double avgWpm = totalTalkSeconds > 0
        ? (totalWords / totalTalkSeconds) * 60.0
        : turnWpm;

    final updatedFillerList = List<String>.from(_speechMetrics.detectedFillers)
      ..addAll(foundFillers);

    _speechMetrics = _speechMetrics.copyWith(
      wordsSpoken: totalWords,
      currentWpm: turnWpm,
      averageWpm: avgWpm,
      fillerCount: _speechMetrics.fillerCount + detectedFillersInTurn,
      hedgingCount: _speechMetrics.hedgingCount + hedges,
      detectedFillers: updatedFillerList,
      talkTimeSeconds: totalTalkSeconds,
    );

    // 6. Closed-Loop Avatar Defensiveness Modulation
    _updateClosedLoopReactivity(
      hasHedging: hasHedging,
      hasStrongBoundary: hasStrongBoundary,
      turnWpm: turnWpm,
      eyeContact: _visionMetrics.eyeContactStability,
      fillerCount: detectedFillersInTurn,
    );

    return {
      'wordCount': wordCount,
      'turnWpm': turnWpm,
      'fillersDetected': detectedFillersInTurn,
      'hasHedging': hasHedging,
      'hasStrongBoundary': hasStrongBoundary,
    };
  }

  void recordAvatarSpeaking(Duration duration) {
    final int sec = max(1, duration.inSeconds);
    _speechMetrics = _speechMetrics.copyWith(
      listenTimeSeconds: _speechMetrics.listenTimeSeconds + sec,
    );
  }

  void recordManualGazeState({required bool lookingAtCamera}) {
    _visionMetrics = _visionMetrics.copyWith(
      eyeContactStability: lookingAtCamera ? 0.94 : 0.42,
      isLookingDown: !lookingAtCamera,
    );

    if (!lookingAtCamera) {
      // Looking down or away escalates avatar defensiveness
      _avatarDefensiveness = (_avatarDefensiveness + 6).clamp(10, 100);
    } else {
      // Looking back into the camera recovers presence
      _avatarDefensiveness = (_avatarDefensiveness - 4).clamp(10, 100);
    }
  }

  void _updateClosedLoopReactivity({
    required bool hasHedging,
    required bool hasStrongBoundary,
    required double turnWpm,
    required double eyeContact,
    required int fillerCount,
  }) {
    int delta = 0;

    // Escalate if user hedges or shows low eye contact
    if (hasHedging) delta += 14;
    if (fillerCount >= 2) delta += 8;
    if (eyeContact < 0.65) delta += 10;
    if (turnWpm > 165) delta += 6; // Rushed, sounds nervous
    if (turnWpm < 95) delta += 6; // Stalling, lacks authority

    // De-escalate and yield if user is firm, centered, and articulate
    if (hasStrongBoundary) delta -= 18;
    if (eyeContact >= 0.80 &&
        fillerCount == 0 &&
        (turnWpm >= 115 && turnWpm <= 150)) {
      delta -= 12; // Perfect executive composure
    }

    _avatarDefensiveness = (_avatarDefensiveness + delta).clamp(10, 100);
  }
}
