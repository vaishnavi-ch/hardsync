import 'scenario.dart';
import 'telemetry.dart';

class TimestampedMoment {
  final Duration timestamp;
  final bool
  isPositive; // true = Strong Boundary / High Impact, false = Weak Phrasing / Hesitation
  final String
  categoryTag; // e.g. "Strong Boundary", "Weak Phrasing", "Empathetic Bridge"
  final String excerpt;
  final String coachFeedback;

  const TimestampedMoment({
    required this.timestamp,
    required this.isPositive,
    required this.categoryTag,
    required this.excerpt,
    required this.coachFeedback,
  });

  String get formattedTimestamp {
    final minutes = timestamp.inMinutes.toString().padLeft(2, '0');
    final seconds = (timestamp.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class ActionableCoachingAdvice {
  final String focusArea;
  final String originalPhrasing;
  final String recommendedPhrasing;
  final String strategicRationale;

  const ActionableCoachingAdvice({
    required this.focusArea,
    required this.originalPhrasing,
    required this.recommendedPhrasing,
    required this.strategicRationale,
  });
}

class DebriefReport {
  final String id;
  final Scenario scenario;
  final DateTime completedAt;
  final Duration totalDuration;
  final int overallScore; // 0 - 100
  final String executiveTier; // e.g., "Level 2: Executive Ready"
  final int clarityScore; // 0 - 100
  final int empathyScore; // 0 - 100
  final int boundaryFirmnessScore; // 0 - 100
  final int presenceComposureScore; // 0 - 100
  final List<TimestampedMoment> keyMoments;
  final List<ActionableCoachingAdvice> actionableBlueprint;
  final List<DialogueTurn> transcript;
  final SpeechMetrics speechMetrics;
  final VisionMetrics visionMetrics;
  final String? videoSnapshotBase64;
  final String? aiExecutiveSummary;
  final String? videoPresenceNotes;
  final bool isAiGenerated;

  const DebriefReport({
    required this.id,
    required this.scenario,
    required this.completedAt,
    required this.totalDuration,
    required this.overallScore,
    required this.executiveTier,
    required this.clarityScore,
    required this.empathyScore,
    required this.boundaryFirmnessScore,
    required this.presenceComposureScore,
    required this.keyMoments,
    required this.actionableBlueprint,
    required this.transcript,
    required this.speechMetrics,
    required this.visionMetrics,
    this.videoSnapshotBase64,
    this.aiExecutiveSummary,
    this.videoPresenceNotes,
    this.isAiGenerated = false,
  });

  String get formattedDuration {
    final minutes = totalDuration.inMinutes.toString().padLeft(2, '0');
    final seconds = (totalDuration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
