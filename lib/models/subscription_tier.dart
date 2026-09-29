import 'package:flutter/material.dart';

enum SubscriptionTier {
  free,
  ultra;

  String get displayName {
    switch (this) {
      case SubscriptionTier.free:
        return 'Free Practice';
      case SubscriptionTier.ultra:
        return 'HardSync Ultra';
    }
  }

  String get badgeLabel {
    switch (this) {
      case SubscriptionTier.free:
        return 'FREE';
      case SubscriptionTier.ultra:
        return 'ULTRA';
    }
  }

  String get tagline {
    switch (this) {
      case SubscriptionTier.free:
        return 'Basic text practice and scenario previews';
      case SubscriptionTier.ultra:
        return 'Live video calls with camera-based coaching';
    }
  }

  String get priceDisplay {
    switch (this) {
      case SubscriptionTier.free:
        return '\$0 / month';
      case SubscriptionTier.ultra:
        return '\$39.99 / month';
    }
  }

  Color get primaryColor {
    switch (this) {
      case SubscriptionTier.free:
        return const Color(0xFF6B7280);
      case SubscriptionTier.ultra:
        return const Color(0xFF8B5CF6);
    }
  }

  Color get badgeBgColor {
    switch (this) {
      case SubscriptionTier.free:
        return const Color(0xFFF3F4F6);
      case SubscriptionTier.ultra:
        return const Color(0xFFF3E8FF);
    }
  }

  bool get canUseVideoCalls => this == SubscriptionTier.ultra;
  bool get canUseLiveFaceAnalysis => this == SubscriptionTier.ultra;

  List<String> get features {
    switch (this) {
      case SubscriptionTier.free:
        return const [
          'Practice by Text Chat',
          'All Practice Scenarios',
          'Unlimited Text Practice',
          'Basic Session Report',
        ];
      case SubscriptionTier.ultra:
        return const [
          '📹 Video Calls with AI (up to 10 min each)',
          '🚀 Priority Access for instant video response',
          '🛠️ Unlimited Custom Meeting Scenarios',
          '🏆 Full Presence Check-Up',
          '🧠 Advanced Voice & Camera Report',
        ];
    }
  }
}
