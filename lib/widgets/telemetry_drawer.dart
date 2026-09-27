import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/telemetry.dart';
import '../theme/hardsync_theme.dart';

class TelemetryDrawer extends StatelessWidget {
  final SpeechMetrics speechMetrics;
  final VisionMetrics visionMetrics;
  final int avatarDefensiveness;
  final VoidCallback onClose;

  const TelemetryDrawer({
    super.key,
    required this.speechMetrics,
    required this.visionMetrics,
    required this.avatarDefensiveness,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final double avgWpm = speechMetrics.averageWpm > 0
        ? speechMetrics.averageWpm
        : 128.0;
    final int fillerCount = speechMetrics.fillerCount;
    final double eyeContact = visionMetrics.eyeContactStability * 100;
    final double talkRatio = speechMetrics.talkRatio * 100;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: HardSyncColors.dark.withValues(alpha: 0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Handle & Close
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: HardSyncColors.primary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: HardSyncColors.primary.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Voice & Camera Readings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white70,
                      size: 20,
                    ),
                    onPressed: onClose,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 1. Cadence & WPM
              _buildTelemetryRow(
                title: 'Speaking Speed',
                value: '${avgWpm.round()} WPM',
                subtitle: avgWpm > 160
                    ? '⚠️ Rushed (>160 WPM)'
                    : avgWpm < 105
                    ? '⚠️ Hesitant (<105 WPM)'
                    : '✓ Good pace (120-145 WPM)',
                statusColor: (avgWpm >= 115 && avgWpm <= 150)
                    ? HardSyncColors.green
                    : HardSyncColors.amber,
                progress: (avgWpm / 200).clamp(0.0, 1.0),
              ),
              const SizedBox(height: 12),

              // 2. Filler & Hedging Counter
              _buildTelemetryRow(
                title: 'Filler Words',
                value: '$fillerCount detected',
                subtitle: fillerCount <= 2
                    ? '✓ Clear, confident wording'
                    : 'Soft phrases detected ("sorry", "just feel like")',
                statusColor: fillerCount <= 2
                    ? HardSyncColors.green
                    : HardSyncColors.crimson,
                progress: (fillerCount / 8).clamp(0.0, 1.0),
              ),
              const SizedBox(height: 12),

              // 3. Eye Contact & Presence Stability
              _buildTelemetryRow(
                title: 'Eye Contact & Presence',
                value: '${eyeContact.round()}% steady',
                subtitle: eyeContact >= 75
                    ? '✓ Direct camera gaze held'
                    : 'Eyes averted down (avoids conflict)',
                statusColor: eyeContact >= 75
                    ? HardSyncColors.green
                    : HardSyncColors.amber,
                progress: visionMetrics.eyeContactStability,
              ),
              const SizedBox(height: 12),

              // 4. Talk-to-Listen Ratio
              _buildTelemetryRow(
                title: 'Talk-to-Listen Ratio',
                value:
                    '${talkRatio.round()}% User / ${(100 - talkRatio).round()}% Avatar',
                subtitle: (talkRatio >= 40 && talkRatio <= 55)
                    ? '✓ Balanced dialogue (Target: 45/55)'
                    : talkRatio > 65
                    ? '⚠️ Dominating conversation (>65%)'
                    : 'Passive (<40% contribution)',
                statusColor: (talkRatio >= 38 && talkRatio <= 58)
                    ? HardSyncColors.green
                    : HardSyncColors.amber,
                progress: (talkRatio / 100).clamp(0.0, 1.0),
              ),
              const SizedBox(height: 12),

              // 4. Closed-Loop Avatar Defensiveness
              _buildTelemetryRow(
                title: 'How Defensive They Are',
                value: '$avatarDefensiveness%',
                subtitle: avatarDefensiveness < 45
                    ? '✓ Avatar is de-escalating & yielding'
                    : avatarDefensiveness > 70
                    ? '⚠️ Avatar is actively pushing back'
                    : 'Testing your boundaries',
                statusColor: avatarDefensiveness < 45
                    ? HardSyncColors.green
                    : avatarDefensiveness > 70
                    ? HardSyncColors.crimson
                    : HardSyncColors.amber,
                progress: avatarDefensiveness / 100.0,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTelemetryRow({
    required String title,
    required String value,
    required String subtitle,
    required Color statusColor,
    required double progress,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: statusColor,
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            minHeight: 5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }
}
