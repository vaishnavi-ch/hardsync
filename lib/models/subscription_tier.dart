import 'package:flutter/material.dart';

enum SubscriptionTier {
  free,
  pro,
  ultra;

  String get displayName {
    switch (this) {
      case SubscriptionTier.free:
        return 'Free Practice';
      case SubscriptionTier.pro:
        return 'HardSync Pro';
      case SubscriptionTier.ultra:
        return 'HardSync Ultra';
    }
  }

  String get badgeLabel {
    switch (this) {
      case SubscriptionTier.free:
        return 'FREE';
      case SubscriptionTier.pro:
        return 'PRO';
      case SubscriptionTier.ultra:
        return 'ULTRA';
    }
  }

  String get tagline {
    switch (this) {
      case SubscriptionTier.free:
        return 'Foundational text rehearsals & scenario previews';
      case SubscriptionTier.pro:
        return 'Unlimited Gemini Live audio calls & real-time vocal telemetry';
      case SubscriptionTier.ultra:
        return 'Gemini Live video calls with camera-based coaching';
    }
  }

  String get priceDisplay {
    switch (this) {
      case SubscriptionTier.free:
        return '\$0 / month';
      case SubscriptionTier.pro:
        return '\$19 / month';
      case SubscriptionTier.ultra:
        return '\$39 / month';
    }
  }

  Color get primaryColor {
    switch (this) {
      case SubscriptionTier.free:
        return const Color(0xFF6B7280);
      case SubscriptionTier.pro:
        return const Color(0xFF2E6347);
      case SubscriptionTier.ultra:
        return const Color(0xFF8B5CF6);
    }
  }

  Color get badgeBgColor {
    switch (this) {
      case SubscriptionTier.free:
        return const Color(0xFFF3F4F6);
      case SubscriptionTier.pro:
        return const Color(0xFFE8F5E9);
      case SubscriptionTier.ultra:
        return const Color(0xFFF3E8FF);
    }
  }

  bool get canUseAudioCalls =>
      this == SubscriptionTier.pro || this == SubscriptionTier.ultra;
  bool get canUseVideoCalls => this == SubscriptionTier.ultra;
  bool get canUseLiveFaceAnalysis => this == SubscriptionTier.ultra;

  List<String> get features {
    switch (this) {
      case SubscriptionTier.free:
        return const [
          'Interactive Text Chat Simulator',
          'Complete Scenario Catalog',
          'Basic Transcript Debrief',
          'No audio calls',
          'No Gemini Live video practice',
        ];
      case SubscriptionTier.pro:
        return const [
          '🎙️ Gemini Live high-fidelity audio calls',
          '📊 Real-Time Vocal Telemetry (WPM, Fillers, Hedging)',
          '⏱️ Talk vs. Listen Ratio Tracking',
          '🧠 Gemini 2.0 Speech Leadership Debrief',
          '⚡ Custom Scenario Creator',
          '🔒 Video Calls & Face Analysis (Ultra Only)',
        ];
      case SubscriptionTier.ultra:
        return const [
          '📹 Gemini Live conversational video calls',
          '🎙️ Gemini Live low-latency audio and video',
          '👁️ Live Face & Eye-Contact Stability Analysis',
          '🧘 Head Composure & Posture Telemetry',
          '📸 Multimodal Visual Frame Inspection',
          '🧠 Gemini 2.0 Multimodal Vision & Speech Debrief',
          '🚀 Priority Model Inference Latency',
        ];
    }
  }
}
