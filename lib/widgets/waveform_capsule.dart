import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/ai_avatar_service.dart';
import '../theme/hardsync_theme.dart';

class WaveformCapsule extends StatefulWidget {
  final String statusText;
  final AvatarVisualState visualState;

  const WaveformCapsule({
    super.key,
    required this.statusText,
    required this.visualState,
  });

  @override
  State<WaveformCapsule> createState() => _WaveformCapsuleState();
}

class _WaveformCapsuleState extends State<WaveformCapsule>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isSpeaking =
        widget.visualState == AvatarVisualState.speaking ||
        widget.visualState == AvatarVisualState.skeptical ||
        widget.visualState == AvatarVisualState.yielding;

    Color badgeColor = HardSyncColors.primary;
    if (widget.visualState == AvatarVisualState.skeptical) {
      badgeColor = HardSyncColors.amber;
    } else if (widget.visualState == AvatarVisualState.yielding) {
      badgeColor = HardSyncColors.green;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(9999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Waveform Bars
              AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return Row(
                    children: List.generate(4, (index) {
                      final double heightMultiplier = isSpeaking
                          ? (0.4 +
                                0.6 *
                                    ((_animController.value + (index * 0.25)) %
                                        1.0))
                          : 0.3;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        width: 3,
                        height: 14 * heightMultiplier,
                        decoration: BoxDecoration(
                          color: isSpeaking ? badgeColor : Colors.white60,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  );
                },
              ),
              const SizedBox(width: 10),

              // Status Label
              Flexible(
                child: Text(
                  widget.statusText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
