import '../providers/simulation_provider.dart';

class CreditPack {
  final String id;
  final String title;
  final int credits;
  final double price;
  final String priceString;
  final String badge;
  final bool popular;

  const CreditPack({
    required this.id,
    required this.title,
    required this.credits,
    required this.price,
    required this.priceString,
    required this.badge,
    this.popular = false,
  });
}

class CreditService {
  CreditService._();
  static final CreditService instance = CreditService._();

  static const double dollarValuePerCredit = 0.10;

  // Exact burn rates
  static const int textCostPerSession = 1;
  static const int voiceCostPerMinute = 1;
  static const int videoCostPerMinute = 6;

  static const List<CreditPack> creditPacks = [
    CreditPack(
      id: 'hardsync_credits_50',
      title: 'Starter Pack',
      credits: 50,
      price: 4.99,
      priceString: '\$4.99',
      badge: '50 Credits',
    ),
    CreditPack(
      id: 'hardsync_credits_150',
      title: 'Pro Pack',
      credits: 150,
      price: 12.99,
      priceString: '\$12.99',
      badge: '150 Credits',
      popular: true,
    ),
    CreditPack(
      id: 'hardsync_credits_500',
      title: 'Premium Pack',
      credits: 500,
      price: 39.99,
      priceString: '\$39.99',
      badge: '500 Credits',
    ),
  ];

  static String formatCreditValue(int credits) {
    final dollars = credits * dollarValuePerCredit;
    return '\$${dollars.toStringAsFixed(2)}';
  }

  static int getEstimatedCost(CallMode mode, {int durationMinutes = 5}) {
    switch (mode) {
      case CallMode.text:
        return textCostPerSession;
      case CallMode.audio:
        return voiceCostPerMinute * durationMinutes;
      case CallMode.video:
        return videoCostPerMinute * durationMinutes;
    }
  }

  static String getRateLabel(CallMode mode) {
    switch (mode) {
      case CallMode.text:
        return '1 credit / session';
      case CallMode.audio:
        return '1 credit / min';
      case CallMode.video:
        return '6 credits / min';
    }
  }

  static bool hasSufficientCredits(int currentBalance, CallMode mode, {int minimumMinutes = 1}) {
    final minimumRequired = getEstimatedCost(mode, durationMinutes: minimumMinutes);
    return currentBalance >= minimumRequired;
  }

  /// Whole minutes `currentBalance` can afford at `mode`'s per-minute rate.
  /// Text is unmetered (always affordable); null means "not time-limited".
  static int? affordableMinutes(int currentBalance, CallMode mode) {
    if (mode == CallMode.text) return null;
    final rate = mode == CallMode.audio ? voiceCostPerMinute : videoCostPerMinute;
    return currentBalance ~/ rate;
  }
}
