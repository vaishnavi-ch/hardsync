import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/debrief_report.dart';
import '../models/telemetry.dart';
import '../providers/simulation_provider.dart';
import '../theme/hardsync_theme.dart';
import '../widgets/circular_score_ring.dart';
import 'session_prep_screen.dart';
import 'session_replay_screen.dart';
import '../theme/hardsync_assets.dart';

class DebriefReportScreen extends StatelessWidget {
  const DebriefReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final simulation = Provider.of<SimulationProvider>(context);
    final report = simulation.latestDebriefReport;

    if (report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Debrief Report')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No recent simulation debrief found.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Return to Hub'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: HardSyncColors.cream,
      appBar: AppBar(
        title: Text(
          'Your practice results',
          style: GoogleFonts.newsreader(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: HardSyncColors.dark,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: HardSyncColors.muted),
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(
                  text: report.transcript
                      .map((t) => '${t.speakerName}: ${t.text}')
                      .join('\n'),
                ),
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Transcript copied to clipboard.'),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              children: [
                // 1. Overall Score & Tier Hero Card
                _buildScoreHeroCard(context, report),
                const SizedBox(height: 16),

                // 2. 4-Metric Heuristic Scorecard
                _buildHeuristicScorecard(context, report),
                const SizedBox(height: 16),

                // 3. Live Multimodal Telemetry Breakdown (Webcam + Voice)
                _buildMultimodalTelemetryCard(context, report),
                const SizedBox(height: 16),

                // 4. Timestamped Conversational Moments
                _buildKeyMomentsSection(context, report),
                const SizedBox(height: 16),

                // 5. Leadership Actionable Blueprint
                _buildActionableBlueprint(context, report),
                const SizedBox(height: 16),

                // 6. Full Turn-by-Turn Transcript Inspection
                _buildTranscriptSection(context, report),
                const SizedBox(height: 20),

                // Review Video & Audio Replay (Stitch Session Replay Screen)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C5CE7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SessionReplayScreen(report: report),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_circle_outline, size: 20),
                    label: Text(
                      'Review transcript',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Bottom CTA Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          simulation.resetSimulation();
                          Navigator.pop(context);
                        },
                        child: const Text('Return to Hub'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final currentScenario = report.scenario;

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  SessionPrepScreen(scenario: currentScenario),
                            ),
                          );
                        },
                        child: const Text('Practice Again'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreHeroCard(BuildContext context, DebriefReport report) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: HardSyncColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: HardSyncColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: HardSyncColors.primarySubtle,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      report.executiveTier.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: HardSyncColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (report.isAiGenerated) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C5CE7).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(
                          color: const Color(0xFF7C5CE7).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AppIcon(
                            HardSyncAssets.iconSparkleStarsMagic,
                            size: 11,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'GEMINI LIVE',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF7C5CE7),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                'Duration: ${report.formattedDuration}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: HardSyncColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Illustrated Confidence Gauge Stage
          const AppIllustration(
            HardSyncAssets.confidenceGaugeEmpowerment,
            height: 95,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 12),

          // Circular Score Ring
          CircularScoreRing(
            score: report.overallScore,
            size: 130,
            strokeWidth: 10,
          ),
          const SizedBox(height: 14),

          Text(
            report.scenario.title,
            style: GoogleFonts.newsreader(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: HardSyncColors.dark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Partner: ${report.scenario.persona.name} (${report.scenario.persona.role})',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: HardSyncColors.muted,
            ),
          ),

          if (report.aiExecutiveSummary != null &&
              report.aiExecutiveSummary!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: HardSyncColors.primarySubtle,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: HardSyncColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppIcon(HardSyncAssets.iconTargetBullseye, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      report.aiExecutiveSummary!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: HardSyncColors.dark,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeuristicScorecard(BuildContext context, DebriefReport report) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HardSyncColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HardSyncColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How it went',
            style: GoogleFonts.newsreader(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: HardSyncColors.dark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'A few things to notice in this conversation.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: HardSyncColors.muted,
            ),
          ),
          const SizedBox(height: 16),

          _buildMetricProgressBar(
            title: 'Clear message',
            score: report.clarityScore,
            benchmark: 'out of 100',
            description: 'Was your main point easy to understand?',
            color: HardSyncColors.primary,
          ),
          const SizedBox(height: 14),

          _buildMetricProgressBar(
            title: 'Clear limits',
            score: report.boundaryFirmnessScore,
            benchmark: 'out of 100',
            description: 'Did you explain what you could and could not do?',
            color: HardSyncColors.accent,
          ),
          const SizedBox(height: 14),

          _buildMetricProgressBar(
            title: 'Steady under pressure',
            score: report.presenceComposureScore,
            benchmark: 'out of 100',
            description: 'Did you take a moment and answer the concern?',
            color: HardSyncColors.green,
          ),
          const SizedBox(height: 14),

          _buildMetricProgressBar(
            title: 'Listening',
            score: report.empathyScore,
            benchmark: 'out of 100',
            description:
                'Did you show that you understood their point of view?',
            color: HardSyncColors.dark,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricProgressBar({
    required String title,
    required int score,
    required String benchmark,
    required String description,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: HardSyncColors.dark,
              ),
            ),
            Row(
              children: [
                Text(
                  benchmark,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: HardSyncColors.lightMuted,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$score%',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(9999),
          child: LinearProgressIndicator(
            value: (score / 100.0).clamp(0.0, 1.0),
            backgroundColor: HardSyncColors.borderSubtle,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            color: HardSyncColors.muted,
          ),
        ),
      ],
    );
  }

  Widget _buildMultimodalTelemetryCard(
    BuildContext context,
    DebriefReport report,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HardSyncColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HardSyncColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.sensors, size: 18, color: Color(0xFF7C5CE7)),
                  const SizedBox(width: 8),
                  Text(
                    'Multimodal Sensor Telemetry',
                    style: GoogleFonts.newsreader(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: HardSyncColors.dark,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C5CE7).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  'LIVE SENSORS',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF7C5CE7),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Direct measurements captured via real-time camera & microphone telemetry',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: HardSyncColors.muted,
            ),
          ),
          const SizedBox(height: 16),

          // 1. Webcam Video Presence Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: HardSyncColors.cream,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: HardSyncColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.videocam_outlined,
                          size: 16,
                          color: HardSyncColors.dark,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Webcam Presence & Gaze Engagement',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: HardSyncColors.dark,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${(report.visionMetrics.eyeContactStability * 100).round()}% lens focus',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: HardSyncColors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildSensorStatBox(
                        label: 'Eye Contact',
                        value:
                            '${(report.visionMetrics.eyeContactStability * 100).round()}%',
                        subtext: 'Benchmark: >80%',
                        isGood:
                            report.visionMetrics.eyeContactStability >= 0.75,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSensorStatBox(
                        label: 'Gaze Alignment',
                        value: report.visionMetrics.isLookingDown
                            ? 'Downward Tilt'
                            : 'Direct Lens',
                        subtext: report.visionMetrics.isLookingDown
                            ? 'Fidget detected'
                            : 'Composed posture',
                        isGood: !report.visionMetrics.isLookingDown,
                      ),
                    ),
                  ],
                ),
                if (report.videoPresenceNotes != null &&
                    report.videoPresenceNotes!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    report.videoPresenceNotes!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: HardSyncColors.muted,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. Vocal Cadence & Speech Dynamics Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: HardSyncColors.cream,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: HardSyncColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.record_voice_over_outlined,
                          size: 16,
                          color: HardSyncColors.dark,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Vocal Cadence & Speech Dynamics',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: HardSyncColors.dark,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${report.speechMetrics.averageWpm.round()} WPM',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: HardSyncColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildSensorStatBox(
                        label: 'Words Spoken',
                        value: '${report.speechMetrics.wordsSpoken}',
                        subtext:
                            '${report.transcript.where((t) => t.speaker == DialogueSpeaker.user).length} verbal turns',
                        isGood: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSensorStatBox(
                        label: 'Filler Words',
                        value: '${report.speechMetrics.fillerCount}',
                        subtext: report.speechMetrics.fillerCount == 0
                            ? 'Zero fillers'
                            : 'um/uh/like',
                        isGood: report.speechMetrics.fillerCount <= 2,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSensorStatBox(
                        label: 'Talk / Listen',
                        value:
                            '${(report.speechMetrics.talkRatio * 100).round()}% / ${(report.speechMetrics.listenRatio * 100).round()}%',
                        subtext: 'Target: 45 / 55%',
                        isGood:
                            (report.speechMetrics.talkRatio - 0.45).abs() < 0.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorStatBox({
    required String label,
    required String value,
    required String subtext,
    required bool isGood,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: HardSyncColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              color: HardSyncColors.lightMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isGood ? HardSyncColors.dark : HardSyncColors.crimson,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5,
              color: HardSyncColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMomentsSection(BuildContext context, DebriefReport report) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HardSyncColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HardSyncColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timestamped Moments',
            style: GoogleFonts.newsreader(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: HardSyncColors.dark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Critical turning points in the simulated conversation',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: HardSyncColors.muted,
            ),
          ),
          const SizedBox(height: 14),

          Column(
            children: report.keyMoments.map((m) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: m.isPositive
                      ? HardSyncColors.primarySubtle
                      : HardSyncColors.crimsonSubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: m.isPositive
                        ? HardSyncColors.primary.withValues(alpha: 0.3)
                        : HardSyncColors.crimson.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${m.formattedTimestamp} • ${m.categoryTag}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: m.isPositive
                                ? HardSyncColors.primary
                                : HardSyncColors.crimson,
                          ),
                        ),
                        Icon(
                          m.isPositive
                              ? Icons.check_circle
                              : Icons.warning_amber_rounded,
                          size: 15,
                          color: m.isPositive
                              ? HardSyncColors.primary
                              : HardSyncColors.crimson,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '"${m.excerpt}"',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: HardSyncColors.dark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      m.coachFeedback,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: HardSyncColors.muted,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionableBlueprint(BuildContext context, DebriefReport report) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HardSyncColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HardSyncColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const AppIcon(HardSyncAssets.iconLightbulbIdea, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Actionable Coaching Blueprint',
                    style: GoogleFonts.newsreader(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: HardSyncColors.dark,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:
                      (report.isAiGenerated
                              ? const Color(0xFF7C5CE7)
                              : HardSyncColors.primary)
                          .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (report.isAiGenerated) ...[
                      const AppIcon(
                        HardSyncAssets.iconSparkleStarsMagic,
                        size: 10,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      report.isAiGenerated ? 'GEMINI AI' : 'LIVE TELEMETRY',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: report.isAiGenerated
                            ? const Color(0xFF7C5CE7)
                            : HardSyncColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Blueprint Map Stage
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            child: const AppIllustration(
              HardSyncAssets.coachingBlueprintMap,
              height: 65,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            report.isAiGenerated
                ? 'Personalized phrasing alternatives generated directly from your speech & video'
                : 'Concrete phrasing alternatives dynamically targeted to your conversational turns',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: HardSyncColors.muted,
            ),
          ),
          const SizedBox(height: 14),

          Column(
            children: report.actionableBlueprint.map((b) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: HardSyncColors.cream,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: HardSyncColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.focusArea,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: HardSyncColors.dark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.close,
                          size: 14,
                          color: HardSyncColors.crimson,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            b.originalPhrasing,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: HardSyncColors.crimson,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppIcon(
                          HardSyncAssets.iconSparkleStarsMagic,
                          size: 13,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            b.recommendedPhrasing,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: HardSyncColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      b.strategicRationale,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: HardSyncColors.muted,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptSection(BuildContext context, DebriefReport report) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HardSyncColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HardSyncColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Full Session Transcript',
                style: GoogleFonts.newsreader(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: HardSyncColors.dark,
                ),
              ),
              Text(
                '${report.transcript.length} turns',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  color: HardSyncColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: report.transcript.length,
            separatorBuilder: (_, __) =>
                const Divider(color: HardSyncColors.border, height: 16),
            itemBuilder: (context, index) {
              final turn = report.transcript[index];
              final isUser = turn.speaker == DialogueSpeaker.user;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? HardSyncColors.primary.withValues(alpha: 0.15)
                          : HardSyncColors.dark.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isUser ? 'YOU' : turn.speakerName.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isUser
                            ? HardSyncColors.primary
                            : HardSyncColors.dark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          turn.text,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            color: HardSyncColors.dark,
                            height: 1.4,
                          ),
                        ),
                        if (turn.isStrongBoundary || turn.hasHedging) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: turn.isStrongBoundary
                                  ? HardSyncColors.greenSubtle
                                  : HardSyncColors.amberSubtle,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              turn.isStrongBoundary
                                  ? '✓ Firm Boundary Held'
                                  : 'Hedging Qualifier Detected',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: turn.isStrongBoundary
                                    ? HardSyncColors.green
                                    : HardSyncColors.amber,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    turn.formattedTimestamp,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: HardSyncColors.lightMuted,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
