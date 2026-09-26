import 'package:flutter/material.dart';
import '../services/camera_service.dart';
import '../theme/hardsync_theme.dart';

class PipCameraWidget extends StatelessWidget {
  final double eyeContactStability;
  final bool isLookingDown;
  final VoidCallback onToggleGaze;
  final CameraVisionService? cameraService;
  final VoidCallback? onToggleCamera;

  const PipCameraWidget({
    super.key,
    required this.eyeContactStability,
    required this.isLookingDown,
    required this.onToggleGaze,
    this.cameraService,
    this.onToggleCamera,
  });

  @override
  Widget build(BuildContext context) {
    final eyePercent = (eyeContactStability * 100).round();
    final bool goodEyeContact = eyeContactStability >= 0.75;
    final bool isRealCamStreaming = cameraService?.isStreaming ?? false;

    return Container(
      width: 130,
      height: 170,
      decoration: BoxDecoration(
        color: HardSyncColors.dark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: goodEyeContact
              ? HardSyncColors.primary.withValues(alpha: 0.8)
              : HardSyncColors.amber.withValues(alpha: 0.8),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Local camera feed (Real Hardware Video or Portrait Fallback)
            if (isRealCamStreaming && cameraService != null)
              cameraService!.buildCameraView(fallback: _buildFallbackImage())
            else
              _buildFallbackImage(),

            // Subtle dark gradient vignette for readable badges
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),

            // Top Status: "You" + Live Camera Toggle
            Positioned(
              top: 6,
              left: 6,
              right: 6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isRealCamStreaming
                              ? Icons.videocam
                              : Icons.videocam_off,
                          size: 10,
                          color: isRealCamStreaming
                              ? const Color(0xFF4CAF50)
                              : Colors.white70,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          isRealCamStreaming ? 'Live' : 'You',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onToggleCamera != null)
                    GestureDetector(
                      onTap: onToggleCamera,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: isRealCamStreaming
                              ? HardSyncColors.primary.withValues(alpha: 0.8)
                              : Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isRealCamStreaming
                              ? Icons.camera_alt
                              : Icons.camera_alt_outlined,
                          size: 11,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Bottom Gaze HUD Pill (Interactive Gaze Shift)
            Positioned(
              bottom: 8,
              left: 6,
              right: 6,
              child: GestureDetector(
                onTap: onToggleGaze,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: goodEyeContact
                        ? HardSyncColors.primary.withValues(alpha: 0.9)
                        : HardSyncColors.amber.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(9999),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        goodEyeContact
                            ? Icons.visibility
                            : Icons.visibility_off,
                        size: 11,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isLookingDown ? 'Gaze Down' : '$eyePercent% Gaze',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackImage() {
    return Image.asset(
      'assets/avatars/split/flutter_256/avatar_01.png',
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: const Color(0xFF263238),
          child: const Center(
            child: Icon(Icons.person, color: Colors.white70, size: 40),
          ),
        );
      },
    );
  }
}
