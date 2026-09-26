import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/hardsync_theme.dart';

class CircularScoreRing extends StatelessWidget {
  final int score;
  final double size;
  final double strokeWidth;
  final String label;

  const CircularScoreRing({
    super.key,
    required this.score,
    this.size = 130,
    this.strokeWidth = 10,
    this.label = 'OVERALL SCORE',
  });

  @override
  Widget build(BuildContext context) {
    Color ringColor = HardSyncColors.primary;
    if (score >= 85) {
      ringColor = HardSyncColors.green;
    } else if (score >= 70) {
      ringColor = HardSyncColors.primary;
    } else if (score >= 55) {
      ringColor = HardSyncColors.amber;
    } else {
      ringColor = HardSyncColors.crimson;
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Ring
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: strokeWidth,
              color: HardSyncColors.border,
            ),
          ),
          // Filled Score Ring
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: (score / 100.0).clamp(0.0, 1.0),
              strokeWidth: strokeWidth,
              strokeCap: StrokeCap.round,
              color: ringColor,
            ),
          ),
          // Score Label
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score%',
                style: GoogleFonts.newsreader(
                  fontSize: size * 0.28,
                  fontWeight: FontWeight.bold,
                  color: HardSyncColors.dark,
                  letterSpacing: -1,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: size * 0.08,
                  fontWeight: FontWeight.w700,
                  color: HardSyncColors.muted,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
