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
        return 'Basic text practice and scenario previews';
      case SubscriptionTier.pro:
        return 'Unlimited voice calls with live speaking feedback';
      case SubscriptionTier.ultra:
        return 'Gemini Live video calls with camera-based coaching';
    }
  }

  String get priceDisplay {
    switch (this) {
      case SubscriptionTier.free:
        return '\$0 / month';
      case SubscriptionTier.pro:
        return '\$19.99 / month';
      case SubscriptionTier.ultra:
        return '\$39.99 / month';
    }
  }

  int get monthlyCredits {
    switch (this) {
      case SubscriptionTier.free:
        return 10;
      case SubscriptionTier.pro:
        return 250;
      case SubscriptionTier.ultra:
        return 600;
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
  bool get canUseVideoCalls =>
      this == SubscriptionTier.pro || this == SubscriptionTier.ultra;
  bool get canUseLiveFaceAnalysis => this == SubscriptionTier.ultra;

  List<String> get features {
    switch (this) {
      case SubscriptionTier.free:
        return const [
          'Practice by Text Chat',
          'All Practice Scenarios',
          '10 Free Practice Credits',
          'Basic Session Report',
        ];
      case SubscriptionTier.pro:
        return const [
          '⚡ 250 Monthly Practice Credits',
          '💬 Unlimited Text Practice',
          '🎙️ Live Voice Practice Calls (1 credit/min)',
          '📹 Photorealistic HD Video Calls (6 credits/min)',
          '📊 Live Speaking Feedback (Speed, Fillers, Hedging)',
          '🎯 50+ Workplace Scenarios',
          '🛠️ Custom Scenario Creator',
        ];
      case SubscriptionTier.ultra:
        return const [
          '⚡ 600 Monthly Practice Credits (~2.5x more practice time)',
          '📹 Photorealistic HD Video & Live Voice Calls',
          '🚀 Priority Access for instant video response',
          '🛠️ Unlimited Custom Meeting Scenarios',
          '🏆 Full Presence Check-Up',
          '🧠 Advanced Voice & Camera Report',
        ];
    }
  }
}
