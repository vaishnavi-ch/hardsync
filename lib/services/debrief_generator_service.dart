import '../models/debrief_report.dart';
import '../models/scenario.dart';
import '../models/telemetry.dart';

/// Transcript observations only. No numerical performance score or camera inference.
class DebriefGeneratorService {
  Future<DebriefReport> generateLiveReport({
    required Scenario scenario,
    required Duration sessionDuration,
    required List<DialogueTurn> transcript,
    required SpeechMetrics speechMetrics,
    required VisionMetrics visionMetrics,
    required int finalDefensiveness,
    String? videoSnapshotBase64,
    String? geminiApiKey,
  }) async => generateReport(
    scenario: scenario,
    sessionDuration: sessionDuration,
    transcript: transcript,
    speechMetrics: speechMetrics,
    visionMetrics: visionMetrics,
    finalDefensiveness: finalDefensiveness,
  );

  DebriefReport generateReport({
    required Scenario scenario,
    required Duration sessionDuration,
    required List<DialogueTurn> transcript,
    required SpeechMetrics speechMetrics,
    required VisionMetrics visionMetrics,
    required int finalDefensiveness,
    String? videoSnapshotBase64,
  }) {
    final userTurns = transcript
        .where((t) => t.speaker == DialogueSpeaker.user)
        .toList();
    return DebriefReport(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      scenario: scenario,
      completedAt: DateTime.now(),
      totalDuration: sessionDuration,
      overallScore: 0,
      executiveTier: 'Not scored',
      clarityScore: 0,
      empathyScore: 0,
      boundaryFirmnessScore: 0,
      presenceComposureScore: 0,
      keyMoments: userTurns
          .where((t) => t.isStrongBoundary || t.hasHedging)
          .map(
            (t) => TimestampedMoment(
              timestamp: t.timestamp,
              isPositive: t.isStrongBoundary,
              categoryTag: 'Phrasing observation',
              excerpt: t.text,
              coachFeedback:
                  'Review this wording in the context of your conversation.',
            ),
          )
          .toList(),
      actionableBlueprint: const [],
      transcript: List.unmodifiable(transcript),
      speechMetrics: speechMetrics,
      visionMetrics: const VisionMetrics(isCameraActive: false),
      aiExecutiveSummary: userTurns.isEmpty
          ? 'No conversation was recorded, so there\'s not enough to give feedback on.'
          : '${userTurns.length} turns recorded. Check the transcript against what you wanted to practice.',
      videoPresenceNotes: 'Camera presence was not measured.',
      isAiGenerated: false,
    );
  }
}
