class SpeechMetrics {
  final int wordsSpoken;
  final double currentWpm;
  final double averageWpm;
  final int fillerCount;
  final int hedgingCount;
  final List<String> detectedFillers;
  final int talkTimeSeconds;
  final int listenTimeSeconds;

  const SpeechMetrics({
    this.wordsSpoken = 0,
    this.currentWpm = 0.0,
    this.averageWpm = 0.0,
    this.fillerCount = 0,
    this.hedgingCount = 0,
    this.detectedFillers = const [],
    this.talkTimeSeconds = 0,
    this.listenTimeSeconds = 0,
  });

  double get talkRatio {
    final total = talkTimeSeconds + listenTimeSeconds;
    if (total == 0) return 0.5;
    return talkTimeSeconds / total;
  }

  double get listenRatio => 1.0 - talkRatio;

  SpeechMetrics copyWith({
    int? wordsSpoken,
    double? currentWpm,
    double? averageWpm,
    int? fillerCount,
    int? hedgingCount,
    List<String>? detectedFillers,
    int? talkTimeSeconds,
    int? listenTimeSeconds,
  }) {
    return SpeechMetrics(
      wordsSpoken: wordsSpoken ?? this.wordsSpoken,
      currentWpm: currentWpm ?? this.currentWpm,
      averageWpm: averageWpm ?? this.averageWpm,
      fillerCount: fillerCount ?? this.fillerCount,
      hedgingCount: hedgingCount ?? this.hedgingCount,
      detectedFillers: detectedFillers ?? this.detectedFillers,
      talkTimeSeconds: talkTimeSeconds ?? this.talkTimeSeconds,
      listenTimeSeconds: listenTimeSeconds ?? this.listenTimeSeconds,
    );
  }
}

class VisionMetrics {
  final double
  eyeContactStability; // 0.0 - 1.0 (1.0 = direct camera eye contact)
  final double composureScore; // 0.0 - 1.0 (calm vs fidgeting)
  final double nodCadence; // active listening score
  final bool isLookingDown;
  final bool isCameraActive;

  const VisionMetrics({
    this.eyeContactStability = 0,
    this.composureScore = 0,
    this.nodCadence = 0,
    this.isLookingDown = false,
    this.isCameraActive = false,
  });

  VisionMetrics copyWith({
    double? eyeContactStability,
    double? composureScore,
    double? nodCadence,
    bool? isLookingDown,
    bool? isCameraActive,
  }) {
    return VisionMetrics(
      eyeContactStability: eyeContactStability ?? this.eyeContactStability,
      composureScore: composureScore ?? this.composureScore,
      nodCadence: nodCadence ?? this.nodCadence,
      isLookingDown: isLookingDown ?? this.isLookingDown,
      isCameraActive: isCameraActive ?? this.isCameraActive,
    );
  }
}

enum DialogueSpeaker { user, avatar }

enum ConversationalTone { assertive, neutral, hedging, empathetic, defensive }

class DialogueTurn {
  final String id;
  final DialogueSpeaker speaker;
  final String speakerName;
  final String text;
  final Duration timestamp;
  final ConversationalTone tone;
  final bool isStrongBoundary;
  final bool hasHedging;
  final int wpmAtTurn;
  final double eyeContactAtTurn;

  const DialogueTurn({
    required this.id,
    required this.speaker,
    required this.speakerName,
    required this.text,
    required this.timestamp,
    required this.tone,
    this.isStrongBoundary = false,
    this.hasHedging = false,
    this.wpmAtTurn = 130,
    this.eyeContactAtTurn = 0.85,
  });

  bool get isUser => speaker == DialogueSpeaker.user;

  String get formattedTimestamp {
    final minutes = timestamp.inMinutes.toString().padLeft(2, '0');
    final seconds = (timestamp.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
