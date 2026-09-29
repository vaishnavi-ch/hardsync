import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../config/env_config.dart';
import '../models/scenario.dart';
import '../models/subscription_tier.dart';
import '../providers/subscription_provider.dart';
import '../services/revenuecat_service.dart';
import '../theme/hardsync_assets.dart';
import '../theme/hardsync_theme.dart';
import 'legal_document_screen.dart';
import 'session_prep_screen.dart';
import 'web_viewer_screen.dart';

class SubscriptionPaywallScreen extends StatefulWidget {
  const SubscriptionPaywallScreen({super.key});

  @override
  State<SubscriptionPaywallScreen> createState() =>
      _SubscriptionPaywallScreenState();
}

class _SubscriptionPaywallScreenState extends State<SubscriptionPaywallScreen> {
  SubscriptionTier _selectedTier = SubscriptionTier.ultra;
  bool _isProcessing = false;
  bool _showPlanPicker = false;
  Offerings? _offerings;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
    // Default selected tier to Ultra or the user's current tier
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final current = Provider.of<SubscriptionProvider>(
        context,
        listen: false,
      ).currentTier;
      setState(() {
        _selectedTier = current == SubscriptionTier.free
            ? SubscriptionTier.ultra
            : current;
      });
    });
  }

  Future<void> _loadOfferings() async {
    final offerings = await RevenueCatService.instance.getOfferings();
    if (mounted) setState(() => _offerings = offerings);
  }

  // Matches on both the package id and the store product id, by tier name
  // only (never generic words like "monthly"/"annual", which every tier's
  // package can contain and which made Pro resolve to the Ultra package).
  Package? _packageByKeyword(List<String> keywords, {String? exclude}) {
    final packages =
        _offerings?.current?.availablePackages ?? const <Package>[];
    for (final keyword in keywords) {
      for (final package in packages) {
        final id =
            '${package.identifier} ${package.storeProduct.identifier}'
                .toLowerCase();
        if (exclude != null && id.contains(exclude)) continue;
        if (id.contains(keyword)) return package;
      }
    }
    return null;
  }

  // Only the Ultra plan is sold. Match its package by identifier and never
  // fall back to an arbitrary package: guessing is how a package for a
  // different product (wrong price) ends up displayed under the Ultra label.
  Package? _packageFor(SubscriptionTier tier) {
    if (tier != SubscriptionTier.ultra) return null;
    return _packageByKeyword(['ultra']);
  }

  String _storePrice(SubscriptionTier tier) =>
      _packageFor(tier)?.storeProduct.priceString ?? 'See store price';

  @override
  Widget build(BuildContext context) {
    final subProvider = context.watch<SubscriptionProvider>();
    final activeTier = subProvider.currentTier;
    final isSubscribed = activeTier != SubscriptionTier.free;

    Widget content;
    if (_isProcessing) {
      content = _buildProcessingView();
    } else if (isSubscribed && !_showPlanPicker) {
      content = _buildActiveExecutivePassView(context, subProvider, activeTier);
    } else {
      content = _buildPlanPickerView(context, subProvider, activeTier);
    }

    return Scaffold(
      backgroundColor: HardSyncColors.cream,
      body: SafeArea(
        // Every card, table, and footer below is laid out for a phone-width
        // column (fixed ~22-24px padding, no per-breakpoint reflow), so on a
        // wide iPad screen it must stay capped at that same width and
        // centered rather than stretched edge to edge, which is what made
        // everything look sparse and the fine print look tiny at the sides.
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: content,
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingView() {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => setState(() => _isProcessing = false),
                icon: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: HardSyncColors.lilacMist,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: HardSyncColors.inkMuted,
                  ),
                ),
              ),
              Text(
                'Confirming Your Plan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: HardSyncColors.ink,
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: HardSyncColors.violet,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, size: 16, color: Colors.white),
              ),
            ],
          ),
        ),
        const Spacer(),
        // Center Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE1EAE4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Circular Progress Shield
                SizedBox(
                  width: 72,
                  height: 72,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const SizedBox(
                        width: 72,
                        height: 72,
                        child: CircularProgressIndicator(
                          strokeWidth: 3.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            HardSyncColors.violet,
                          ),
                          backgroundColor: HardSyncColors.lilacMist,
                        ),
                      ),
                      Container(
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(
                          color: HardSyncColors.lilacMist,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          size: 26,
                          color: HardSyncColors.violet,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Activating Your Plan...',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.newsreader(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: HardSyncColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Confirming your purchase with the app store. This only takes a moment.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: HardSyncColors.inkMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Checklist Items
                _buildVerificationItem(
                  icon: Icons.check_circle_rounded,
                  iconColor: HardSyncColors.violet,
                  text: 'Purchase verified',
                  isCompleted: true,
                ),
                const SizedBox(height: 12),
                _buildVerificationItem(
                  icon: Icons.check_circle_rounded,
                  iconColor: HardSyncColors.violet,
                  text: 'All scenarios unlocked',
                  isCompleted: true,
                ),
                const SizedBox(height: 12),
                _buildVerificationItem(
                  icon: Icons.sync_rounded,
                  iconColor: HardSyncColors.violet,
                  text: 'Setting up your coach feedback...',
                  isCompleted: false,
                ),
                const SizedBox(height: 24),
                const Divider(height: 1, color: Color(0xFFEDE8DE)),
                const SizedBox(height: 14),

                // Footer security badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 13,
                      color: HardSyncColors.inkMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '256-bit encrypted',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: HardSyncColors.inkMuted,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '\u2022',
                        style: TextStyle(color: Color(0xFFCBD6D0)),
                      ),
                    ),
                    const Icon(
                      Icons.verified_outlined,
                      size: 13,
                      color: HardSyncColors.inkMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'StoreKit 2 Secure',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: HardSyncColors.inkMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Please keep HardSync open while finalizing',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    color: HardSyncColors.lightMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildVerificationItem({
    required IconData icon,
    required Color iconColor,
    required String text,
    bool isCompleted = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w500,
              color: HardSyncColors.ink,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveExecutivePassView(
    BuildContext context,
    SubscriptionProvider subProvider,
    SubscriptionTier activeTier,
  ) {
    final isUltra = activeTier == SubscriptionTier.ultra;
    final managingFormerPeer = Scenario.defaultScenarios.firstWhere(
      (s) => s.id == 'scenario_managing_former_peer',
      orElse: () => Scenario.defaultScenarios.first,
    );

    return Column(
      children: [
        // Top Header with Leaf & Pass title & Close button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isUltra
                          ? HardSyncColors.violetDark
                          : HardSyncColors.violet,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isUltra ? Icons.eco : Icons.graphic_eq_rounded,
                      size: 18,
                      color: HardSyncColors.lilacMist,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HardSync',
                        style: GoogleFonts.newsreader(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: HardSyncColors.ink,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        '${activeTier.badgeLabel} MEMBER',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: isUltra
                              ? HardSyncColors.inkMuted
                              : HardSyncColors.violetDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: HardSyncColors.lilacMist,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: HardSyncColors.inkMuted,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Scrollable Body
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 6),
                // Hero Emblem
                Center(
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isUltra
                                ? const Color(0xFFE5EFE8)
                                : const Color(0xFFE3EDF7),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (isUltra
                                            ? HardSyncColors.violet
                                            : const Color(0xFF2563EB))
                                        .withValues(alpha: 0.15),
                                blurRadius: 18,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 60,
                          height: 60,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isUltra
                                ? HardSyncColors.ink
                                : const Color(0xFF1E3A5F),
                            shape: BoxShape.circle,
                          ),
                          child: AppIllustration(
                            isUltra
                                ? HardSyncAssets.illusSafeVideoRoleplay
                                : HardSyncAssets.illusLeadershipCompass,
                            fit: BoxFit.contain,
                          ),
                        ),
                        // Top right badge
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: isUltra
                                  ? const Color(0xFFFBE8E2)
                                  : const Color(0xFFFEF3C7),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isUltra ? Icons.auto_awesome : Icons.bolt_rounded,
                              size: 13,
                              color: isUltra
                                  ? const Color(0xFFD47055)
                                  : const Color(0xFFD97706),
                            ),
                          ),
                        ),
                        // Bottom left star
                        Positioned(
                          bottom: 6,
                          left: 6,
                          child: Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: isUltra
                                ? HardSyncColors.violet
                                : const Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Pill: UNLIMITED ACCESS UNLOCKED vs PRO AUDIO ACCESS UNLOCKED
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isUltra
                        ? HardSyncColors.lilacMist
                        : const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isUltra
                          ? HardSyncColors.lilacBorder
                          : const Color(0xFFBAE6FD),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: isUltra
                            ? HardSyncColors.violetDark
                            : const Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${activeTier.badgeLabel} PLAN ACTIVE',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: isUltra
                              ? HardSyncColors.violetDark
                              : const Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Heading
                Text(
                  'You’re on ${activeTier.displayName}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.newsreader(
                    fontSize: 27,
                    fontWeight: FontWeight.w600,
                    color: HardSyncColors.ink,
                    height: 1.18,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isUltra
                      ? 'Practice with live video calls, any time.'
                      : 'Upgrade to Ultra to practice with live video calls.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: HardSyncColors.inkMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // Card 1: Active Membership Details
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2EDE5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${activeTier.displayName} Member',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: HardSyncColors.ink,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Icon(
                                Icons.verified,
                                size: 16,
                                color: Color(0xFF257BE3),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5F5EC),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Active',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: HardSyncColors.violetDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Active Ultra subscription • Renewal is managed by your app store',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: HardSyncColors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1, color: Color(0xFFEDF2EE)),
                      const SizedBox(height: 14),

                      // Bullet points specific to tier
                      if (isUltra) ...[
                        _buildBenefitBullet('Video practice calls'),
                        const SizedBox(height: 9),
                        _buildBenefitBullet('Live camera coaching'),
                        const SizedBox(height: 9),
                        _buildBenefitBullet('Real-time speaking feedback'),
                        const SizedBox(height: 9),
                        _buildBenefitBullet('Feedback report after every session'),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Card 2: Recommended Next Practice
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2EDE5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'RECOMMENDED NEXT PRACTICE',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: HardSyncColors.inkMuted,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isUltra
                                  ? const Color(0xFFFDECE8)
                                  : const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Video Practice',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isUltra
                                    ? const Color(0xFFC44F3C)
                                    : const Color(0xFF0369A1),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Alex scenario preview row
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/avatars/alex_avatar.jpg',
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2EDE5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: HardSyncColors.violetDark,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Managing a Former Peer',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: HardSyncColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Alex \u2022 Product Strategy Lead',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: HardSyncColors.inkMuted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Live Video ready',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: HardSyncColors.lightMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Quote callout box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDF6F0),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFDBEBE0)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.bubble_chart_outlined,
                                size: 15,
                                color: HardSyncColors.violet,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '"Focus on acknowledging their past contributions before establishing the new project cadence."',
                                style: GoogleFonts.newsreader(
                                  fontSize: 12.5,
                                  fontStyle: FontStyle.italic,
                                  color: HardSyncColors.ink,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // CTA Button: Start Rehearsing Now ->
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isUltra
                          ? HardSyncColors.ink
                          : HardSyncColors.violetDark,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shadowColor: const Color(
                        0xFF204633,
                      ).withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              SessionPrepScreen(scenario: managingFormerPeer),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const AppIcon(
                          HardSyncAssets.iconRocketLaunch,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Start Practicing Now',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Manage Subscription link
                InkWell(
                  onTap: () => setState(() => _showPlanPicker = true),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Manage Subscription',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: HardSyncColors.inkMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'View your localized renewal price and cancel anytime in your app store subscription settings.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    color: HardSyncColors.lightMuted,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitBullet(String text) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle_rounded,
          size: 17,
          color: HardSyncColors.violet,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: HardSyncColors.ink,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanPickerView(
    BuildContext context,
    SubscriptionProvider subProvider,
    SubscriptionTier activeTier,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 760;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
              child: Row(
                children: [
                  _paywallCircleButton(
                    Icons.arrow_back,
                    () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: compact ? 230 : 270,
                      child: Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          Positioned(
                            top: -2,
                            right: -164,
                            width: 280,
                            height: compact ? 280 : 310,
                            child: Opacity(
                              opacity: 0.96,
                              child: Image.asset(
                                HardSyncAssets.illusSafeRehearsalRoom,
                                fit: BoxFit.contain,
                                alignment: Alignment.topRight,
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: constraints.maxWidth * 0.52,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: SizedBox(
                                  width: constraints.maxWidth * 0.52,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Choose\nyour Plan',
                                        style: GoogleFonts.newsreader(
                                          fontSize: compact ? 36 : 40,
                                          fontWeight: FontWeight.w600,
                                          color: HardSyncColors.ink,
                                          height: 1.05,
                                          letterSpacing: -0.7,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Keep building\na better you.',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 16,
                                          color: const Color(0xFF4E5054),
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _mockPlanCard(
                      title: 'Free',
                      price: '\$0',
                      period: '/ month',
                      color: HardSyncColors.olive,
                      selected: _selectedTier == SubscriptionTier.free,
                      popular: false,
                      illustration: HardSyncAssets.illusRechargeRitual,
                      benefits: const [
                        'Interactive text scenarios',
                        'Complete scenario catalog',
                        'Unlimited text practice',
                      ],
                      onTap: () =>
                          setState(() => _selectedTier = SubscriptionTier.free),
                    ),
                    const SizedBox(height: 14),
                    _mockPlanCard(
                      title: 'Ultra',
                      price: _storePrice(SubscriptionTier.ultra),
                      period: _packageFor(SubscriptionTier.ultra) == null
                          ? ''
                          : '/ billing period',
                      color: HardSyncColors.violet,
                      selected: _selectedTier == SubscriptionTier.ultra,
                      popular: true,
                      illustration: HardSyncAssets.illusSafeVideoRoleplay,
                      benefits: const [
                        'Video Calls with AI (10 min)',
                        'Live camera & speaking feedback',
                        'Priority Access for Faster Calls',
                        'Full Presence Check-Up',
                      ],
                      onTap: () => setState(
                        () => _selectedTier = SubscriptionTier.ultra,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildComparisonMatrix(),
                  ],
                ),
              ),
            ),
            _mockPaywallFooter(context, subProvider),
          ],
        );
      },
    );
  }

  Widget _paywallCircleButton(IconData icon, VoidCallback onTap) => Material(
    color: const Color(0xFFFFFBF7),
    shape: const CircleBorder(),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(icon, color: HardSyncColors.ink, size: 22),
      ),
    ),
  );

  Widget _mockPlanCard({
    required String title,
    required String price,
    required String period,
    required Color color,
    required bool selected,
    required bool popular,
    required String illustration,
    required List<String> benefits,
    required VoidCallback onTap,
  }) {
    final background = popular
        ? const Color(0xFFF7F2FC)
        : const Color(0xFFFFFDFC);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 248,
        padding: const EdgeInsets.fromLTRB(24, 18, 14, 14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? color : const Color(0xFFE9E6E4),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Stack(
          children: [
            if (popular)
              Positioned(
                right: 8,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8DDF6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Most Popular',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF7656B5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            Positioned(
              right: 0,
              top: popular ? 52 : 38,
              width: 132,
              height: 120,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: ColoredBox(
                  color: popular
                      ? const Color(0xFFFFF0D8)
                      : const Color(0xFFFFF1E4),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Image.asset(illustration, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.newsreader(
                    fontSize: 27,
                    fontWeight: FontWeight.w600,
                    color: HardSyncColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: price,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 27,
                          fontWeight: FontWeight.w600,
                          color: HardSyncColors.ink,
                        ),
                      ),
                      if (period.isNotEmpty)
                        TextSpan(
                          text: ' $period',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: const Color(0xFF8A8990),
                          ),
                        ),
                    ],
                  ),
                ),
                const Spacer(),
                ...benefits.map(
                  (label) => Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 13,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              color: HardSyncColors.inkMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _mockPaywallFooter(
    BuildContext context,
    SubscriptionProvider subProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 10),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: HardSyncColors.ink,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const StadiumBorder(),
              ),
              onPressed: _isProcessing
                  ? null
                  : () => _handleActivateTier(subProvider),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _selectedTier == SubscriptionTier.free
                        ? 'Continue'
                        : 'Continue',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 9),
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 6,
            children: [
              Text(
                'Cancel anytime',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF929196),
                ),
              ),
              InkWell(
                onTap: _isProcessing ? null : () => _handleRestore(subProvider),
                child: Text(
                  'Restore purchases',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: HardSyncColors.inkMuted,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WebViewerScreen(
                      title: 'Terms of Use (EULA)',
                      url: EnvConfig.termsOfServiceUrl,
                      fallbackWidget: LegalDocumentScreen(
                        document: LegalDocument.terms,
                      ),
                    ),
                  ),
                ),
                child: Text(
                  'Terms of Use (EULA)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: HardSyncColors.inkMuted,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WebViewerScreen(
                      title: 'Privacy Policy',
                      url: EnvConfig.privacyPolicyUrl,
                      fallbackWidget: LegalDocumentScreen(
                        document: LegalDocument.privacy,
                      ),
                    ),
                  ),
                ),
                child: Text(
                  'Privacy Policy',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: HardSyncColors.inkMuted,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Payment is charged to your store account upon confirmation. Subscriptions renew automatically unless canceled at least 24 hours prior to the end of the current period. Manage or cancel anytime in your account settings.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              height: 1.35,
              color: const Color(0xFF9E9CA3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonMatrix() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E3DA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What\'s Included',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: HardSyncColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          _buildMatrixRow('Text Practice', free: true, ultra: true),
          const Divider(height: 14, color: Color(0xFFF0EBE3)),
          _buildMatrixRow('Video Calls with AI', free: false, ultra: true),
          const Divider(height: 14, color: Color(0xFFF0EBE3)),
          _buildMatrixRow('Live Speaking Feedback', free: false, ultra: true),
          const Divider(height: 14, color: Color(0xFFF0EBE3)),
          _buildMatrixRow(
            'VIP Priority GPU Pipeline',
            free: false,
            ultra: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMatrixRow(
    String feature, {
    required bool free,
    required bool ultra,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            feature,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: HardSyncColors.inkMuted,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Center(
            child: Icon(
              free ? Icons.check : Icons.close,
              size: 15,
              color: free ? HardSyncColors.violetDark : Colors.black26,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Center(
            child: Icon(
              ultra ? Icons.check : Icons.close,
              size: 15,
              color: ultra ? const Color(0xFF8B5CF6) : Colors.black26,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleActivateTier(SubscriptionProvider subProvider) async {
    if (_selectedTier == SubscriptionTier.free) {
      await subProvider.setTier(SubscriptionTier.free);
      await subProvider.refresh();
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _showPlanPicker = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Switched to Free Practice.')),
        );
      }
      return;
    }

    setState(() => _isProcessing = true);
    try {
      if (!RevenueCatService.instance.isConfigured) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Purchases are not available on this platform right now.',
              ),
            ),
          );
        }
        return;
      }

      final offerings = await RevenueCatService.instance.getOfferings();
      if (offerings == null ||
          offerings.current == null ||
          offerings.current!.availablePackages.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No subscription plans are available right now. Please try again later.',
              ),
              duration: Duration(seconds: 6),
            ),
          );
        }
        return;
      }

      // Reuse the same resolver the plan picker's price labels use, so what
      // gets purchased always matches what was shown and priced on screen.
      _offerings = offerings;
      final packageToBuy = _packageFor(_selectedTier);
      if (packageToBuy == null) {
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'The ${_selectedTier.displayName} plan is not available right now. Please try again later.',
              ),
              duration: const Duration(seconds: 6),
            ),
          );
        }
        return;
      }

      final success = await RevenueCatService.instance.purchasePackage(
        packageToBuy,
      );
      // A fresh purchase can take a few seconds to show up as an active
      // entitlement in RevenueCat and on the server, so re-check a few times
      // before reporting a missing entitlement. The server still decides the
      // tier; a client-authored change must never unlock paid access.
      await subProvider.refresh();
      for (var attempt = 0;
          attempt < 4 && subProvider.currentTier.index < _selectedTier.index;
          attempt++) {
        await Future<void>.delayed(const Duration(seconds: 2));
        await RevenueCatService.instance.refreshCustomerInfo();
        await subProvider.refresh();
      }
      if (success || subProvider.currentTier.index >= _selectedTier.index) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _showPlanPicker = false;
          });
          final activated =
              subProvider.currentTier.index >= _selectedTier.index;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                activated
                    ? '${_selectedTier.displayName} activated successfully!'
                    : 'Purchase completed, but the ${_selectedTier.displayName} entitlement is not active. Check the RevenueCat product mapping.',
              ),
              backgroundColor: activated
                  ? HardSyncColors.violet
                  : const Color(0xFF844335),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'The purchase completed without an active HardSync entitlement. Check the offering and entitlement mapping.',
            ),
          ),
        );
      }
    } on PlatformException catch (e) {
      if (mounted) {
        final cancelled =
            PurchasesErrorHelper.getErrorCode(e) ==
            PurchasesErrorCode.purchaseCancelledError;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              cancelled
                  ? 'Purchase cancelled. No charge was made.'
                  : 'The store could not complete the purchase. Please try again.',
            ),
            backgroundColor: cancelled
                ? HardSyncColors.inkMuted
                : const Color(0xFF844335),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'The purchase could not be completed. Please try again.',
            ),
            backgroundColor: Color(0xFF844335),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleRestore(SubscriptionProvider subProvider) async {
    setState(() => _isProcessing = true);
    try {
      final restored = await RevenueCatService.instance.restorePurchases();
      if (restored) {
        await subProvider.refresh();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              restored
                  ? 'Subscriptions restored successfully! Account status refreshed.'
                  : 'No active subscriptions found for this account.',
            ),
            backgroundColor: HardSyncColors.violetDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore note: $e'),
            backgroundColor: const Color(0xFF844335),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
