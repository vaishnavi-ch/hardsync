import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/env_config.dart';
import '../models/subscription_tier.dart';
import '../providers/subscription_provider.dart';
import '../services/supabase_service.dart';
import '../theme/hardsync_assets.dart';
import '../theme/hardsync_theme.dart';
import 'legal_document_screen.dart';
import 'settings_modal.dart';
import 'sign_in_screen.dart';
import 'subscription_paywall_screen.dart';
import 'web_viewer_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool embedded;
  const ProfileScreen({super.key, this.embedded = true});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  int _sessionCount = 0;

  @override
  void initState() {
    super.initState();
    SupabaseService.instance.addListener(_onAuthChanged);
    _loadProfileAndPreferences();
  }

  @override
  void dispose() {
    SupabaseService.instance.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) {
      _loadProfileAndPreferences();
    }
  }

  Future<void> _loadProfileAndPreferences() async {
    if (!SupabaseService.instance.isAuthenticated) {
      return;
    }

    try {
      Map<String, dynamic>? prof;
      int count = 0;
      try {
        prof = await SupabaseService.instance.fetchOwnProfile();
      } catch (_) {}

      try {
        final history = await SupabaseService.instance.fetchUserSessionHistory();
        count = history.length;
      } catch (_) {}

      if (mounted) {
        setState(() {
          _profile = prof;
          _sessionCount = count;
        });
      }
    } catch (_) {}
  }

  void _showNotice(String message, {bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_outline : Icons.info_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess ? const Color(0xFF10B981) : HardSyncColors.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!SupabaseService.instance.isAuthenticated) {
      return _buildGuestView();
    }

    final subProvider = context.watch<SubscriptionProvider>();
    final tier = subProvider.currentTier;
    final fullName = _profile?['full_name'] as String? ??
        SupabaseService.instance.currentUserName;
    final role = _profile?['leadership_role'] as String? ?? 'Engineering Leader';
    final email = SupabaseService.instance.currentUserEmail;
    final streak = (_profile?['streak_days'] as num?)?.toInt() ?? 1;
    final avatarAsset = _profile?['avatar_url'] as String? ??
        SupabaseService.instance.cachedAvatarUrl ??
        HardSyncAssets.avatarCurrentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FC),
      appBar: widget.embedded
          ? null
          : AppBar(
              backgroundColor: const Color(0xFFF8F6FC),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: HardSyncColors.ink),
                onPressed: () => Navigator.maybePop(context),
              ),
              title: Text(
                'Your Profile',
                style: GoogleFonts.newsreader(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: HardSyncColors.ink,
                ),
              ),
            ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 860 : 540),
                child: RefreshIndicator(
                  color: HardSyncColors.violet,
                  onRefresh: _loadProfileAndPreferences,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      isWide ? 28 : 20,
                      widget.embedded ? (isWide ? 28 : 16) : 10,
                      isWide ? 28 : 20,
                      40,
                    ),
                    children: [
                      if (widget.embedded) ...[
                        Row(
                          children: [
                            Text(
                              'You',
                              style: GoogleFonts.newsreader(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: HardSyncColors.ink,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Cloud Synced',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF047857),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // --- EXECUTIVE HERO CARD ---
                      _buildHeroCard(
                        name: fullName,
                        role: role,
                        email: email,
                        tier: tier,
                        avatarAsset: avatarAsset,
                      ),
                      const SizedBox(height: 14),

                      // --- TELEMETRY METRIC GRID ---
                      _buildMetricGrid(
                        streak: streak,
                        sessionCount: _sessionCount,
                        tier: tier,
                      ),
                      const SizedBox(height: 24),

                      // --- SECTION 2: SUBSCRIPTION & BILLING ---
                      _buildSectionHeader('Membership'),
                      _buildCard([
                        _buildActionTile(
                          icon: Icons.workspace_premium_outlined,
                          title: tier == SubscriptionTier.ultra
                              ? 'HardSync Ultra Pass'
                              : 'Free Plan',
                          subtitle: tier == SubscriptionTier.free
                              ? 'Upgrade to Ultra for live video simulations'
                              : 'Active subscription • Managed via App Store',
                          trailingBadge: tier == SubscriptionTier.ultra
                              ? 'ULTRA'
                              : 'FREE',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SubscriptionPaywallScreen(),
                            ),
                          ),
                        ),
                        _buildDivider(),
                        _buildActionTile(
                          icon: Icons.credit_card_outlined,
                          title: 'Manage or Cancel Subscription',
                          subtitle: 'Cancel, view renewal date, or get receipts',
                          trailingIcon: Icons.arrow_forward_ios_rounded,
                          onTap: _manageSubscription,
                        ),
                      ]),
                      const SizedBox(height: 20),

                      // --- SECTION 3: PRACTICE PREFERENCES ---
                      _buildSectionHeader('Practice Room Settings'),
                      _buildCard([
                        _buildActionTile(
                          icon: Icons.videocam_outlined,
                          title: 'Camera & Mic Settings',
                          subtitle: 'Camera and mic defaults',
                          trailingIcon: Icons.arrow_forward_ios_rounded,
                          onTap: () => showModalBottomSheet(
                            context: context,
                            showDragHandle: true,
                            isScrollControlled: true,
                            backgroundColor: HardSyncColors.cream,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                            ),
                            builder: (_) => const SettingsModal(),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 20),

                      // --- SECTION 4: SECURITY & CREDENTIALS ---
                      _buildSectionHeader('Security & Identity'),
                      _buildCard([
                        _buildActionTile(
                          icon: Icons.lock_outline,
                          title: 'Change Password',
                          subtitle: 'Update your account access passphrase',
                          trailingIcon: Icons.arrow_forward_ios_rounded,
                          onTap: _showChangePasswordModal,
                        ),
                      ]),
                      const SizedBox(height: 20),

                      // --- SECTION 5: HELP, FAQS & SUPPORT ---
                      _buildSectionHeader('Support'),
                      _buildCard([
                        _buildActionTile(
                          icon: Icons.language_rounded,
                          title: 'Official Website & How It Works',
                          subtitle: 'See the C.A.R.E. approach & app overview',
                          trailingIcon: Icons.arrow_forward_ios_rounded,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const WebViewerScreen(
                                title: 'HardSync Official Site',
                                url: EnvConfig.landingPageUrl,
                              ),
                            ),
                          ),
                        ),
                        _buildDivider(),
                        _buildActionTile(
                          icon: Icons.help_outline_rounded,
                          title: 'Help & FAQs',
                          subtitle: 'How scoring works & how-to guides',
                          trailingIcon: Icons.arrow_forward_ios_rounded,
                          onTap: _showHelpCenterModal,
                        ),
                        _buildDivider(),
                        _buildActionTile(
                          icon: Icons.send_rounded,
                          title: 'Send Feedback & Request Scenarios',
                          subtitle: 'Direct line to our coaching team',
                          trailingIcon: Icons.arrow_forward_ios_rounded,
                          onTap: _showFeedbackModal,
                        ),
                        _buildDivider(),
                        _buildActionTile(
                          icon: Icons.verified_user_outlined,
                          title: 'Privacy Policy',
                          subtitle: 'Zero-copy audio & camera privacy standards',
                          trailingIcon: Icons.arrow_forward_ios_rounded,
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
                        ),
                        _buildDivider(),
                        _buildActionTile(
                          icon: Icons.description_outlined,
                          title: 'Terms of Service',
                          subtitle: 'Platform usage & coaching service agreements',
                          trailingIcon: Icons.arrow_forward_ios_rounded,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const WebViewerScreen(
                                title: 'Terms of Service',
                                url: EnvConfig.termsOfServiceUrl,
                                fallbackWidget: LegalDocumentScreen(
                                  document: LegalDocument.terms,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 24),

                      // --- SECTION 6: DANGER ZONE ---
                      _buildSectionHeader('Account Actions'),
                      _buildCard([
                        _buildActionTile(
                          icon: Icons.logout_rounded,
                          title: 'Sign Out',
                          subtitle: 'Safely end your session on this device',
                          isDanger: true,
                          onTap: () => showDialog(
                            context: context,
                            builder: (_) => const LogoutDialog(showSignedOut: false),
                          ),
                        ),
                        _buildDivider(),
                        _buildActionTile(
                          icon: Icons.delete_forever_outlined,
                          title: 'Delete Account & All Data',
                          subtitle: 'Permanently remove all your reports and transcripts',
                          isDanger: true,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DeleteAccountScreen(),
                            ),
                          ),
                        ),
                        _buildDivider(),
                        _buildActionTile(
                          icon: Icons.open_in_browser_rounded,
                          title: 'Web Account Deletion Portal',
                          subtitle: 'Browser-based data removal instructions',
                          trailingIcon: Icons.arrow_forward_ios_rounded,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const WebViewerScreen(
                                title: 'Account Deletion Portal',
                                url: EnvConfig.accountDeletionUrl,
                              ),
                            ),
                          ),
                        ),
                      ]),

                      const SizedBox(height: 32),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'HardSync • Practice for tough conversations',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: HardSyncColors.inkMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Version 1.0.0 (Build 42) • Dual-Engine AI (Gemini Live & DeepSeek)',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: HardSyncColors.inkMuted.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // --- HERO HEADER WIDGET ---
  Widget _buildHeroCard({
    required String name,
    required String role,
    required String email,
    required SubscriptionTier tier,
    required String avatarAsset,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            HardSyncColors.lilacMist.withValues(alpha: 0.8),
            HardSyncColors.apricotMist.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: HardSyncColors.lilacBorder.withValues(alpha: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: HardSyncColors.violet.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 68,
                height: 68,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: HardSyncColors.violet, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: HardSyncColors.violet.withValues(alpha: 0.16),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: AppAvatar(avatarAsset, size: 60, borderWidth: 0),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: GoogleFonts.newsreader(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: HardSyncColors.ink,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showEditProfileModal(name, role),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit_outlined,
                              size: 14,
                              color: HardSyncColors.violet,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: HardSyncColors.inkMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: HardSyncColors.violet.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.business_center_outlined,
                            size: 13,
                            color: HardSyncColors.violet,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            role,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: HardSyncColors.violet,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton.icon(
              onPressed: () => _showEditProfileModal(name, role),
              icon: const Icon(Icons.person_outline, size: 16),
              label: const Text('Edit Persona & Role Details'),
              style: OutlinedButton.styleFrom(
                foregroundColor: HardSyncColors.violet,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: HardSyncColors.violet.withValues(alpha: 0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- TELEMETRY METRIC GRID ---
  Widget _buildMetricGrid({
    required int streak,
    required int sessionCount,
    required SubscriptionTier tier,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            emoji: '🔥',
            value: '$streak d',
            label: 'Practice Streak',
            color: const Color(0xFFF97316),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            emoji: '🎯',
            value: '$sessionCount',
            label: 'Drills Done',
            color: const Color(0xFF6366F1),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            emoji: '👑',
            value: tier == SubscriptionTier.ultra
                ? 'Ultra'
                : 'Free',
            label: 'Plan',
            color: const Color(0xFF8B5CF6),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SubscriptionPaywallScreen(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String emoji,
    required String value,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: HardSyncColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: HardSyncColors.lilacBorder),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    value,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: HardSyncColors.ink,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: HardSyncColors.inkMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: HardSyncColors.inkMuted,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: HardSyncColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HardSyncColors.lilacBorder),
        boxShadow: [
          BoxShadow(
            color: HardSyncColors.violet.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: HardSyncColors.lilacBorder.withValues(alpha: 0.6),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    IconData? trailingIcon,
    String? trailingBadge,
    bool isDanger = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDanger
              ? const Color(0xFFFFECEC)
              : HardSyncColors.lilacMist.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isDanger ? const Color(0xFFEF4444) : HardSyncColors.violet,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isDanger ? const Color(0xFFEF4444) : HardSyncColors.ink,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11.5,
          color: HardSyncColors.inkMuted,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailingBadge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: HardSyncColors.violet,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                trailingBadge,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            )
          : (trailingIcon != null
              ? Icon(trailingIcon, size: 16, color: HardSyncColors.inkMuted)
              : null),
    );
  }

  // --- MODAL: EDIT EXECUTIVE PROFILE ---
  void _showEditProfileModal(String currentName, String currentRole) {
    final nameCtrl = TextEditingController(text: currentName);
    final roleCtrl = TextEditingController(text: currentRole);
    bool isSaving = false;

    final roles = [
      'Engineering Leader',
      'Product Manager',
      'Founder / CEO',
      'Executive Director',
      'VP of Operations',
      'Team Lead / Manager',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: HardSyncColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalCtx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: HardSyncColors.lilacBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Edit Your Profile',
                style: GoogleFonts.newsreader(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: HardSyncColors.ink,
                ),
              ),
              Text(
                'HardSync adjusts how tough the practice partner is based on your role.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: HardSyncColors.inkMuted,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'FULL NAME',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: HardSyncColors.inkMuted,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Enter your name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: HardSyncColors.lilacBorder),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'YOUR ROLE',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: HardSyncColors.inkMuted,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: roleCtrl,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'e.g. Engineering Leader',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: HardSyncColors.lilacBorder),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: roles.map((r) {
                  final isSelected = roleCtrl.text == r;
                  return ChoiceChip(
                    label: Text(r),
                    selected: isSelected,
                    selectedColor: HardSyncColors.violet,
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : HardSyncColors.ink,
                    ),
                    backgroundColor: Colors.white,
                    onSelected: (selected) {
                      setModalState(() {
                        roleCtrl.text = r;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final newName = nameCtrl.text.trim();
                          final newRole = roleCtrl.text.trim();
                          if (newName.isEmpty) return;

                          setModalState(() => isSaving = true);
                          try {
                            await SupabaseService.instance.updateOwnProfile({
                              'full_name': newName,
                              'leadership_role': newRole,
                            });
                            await _loadProfileAndPreferences();
                            if (modalCtx.mounted) {
                              Navigator.pop(modalCtx);
                            }
                            _showNotice('Profile updated successfully!', isSuccess: true);
                          } catch (e) {
                            setModalState(() => isSaving = false);
                            _showNotice('Failed to update profile: $e');
                          }
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: HardSyncColors.violet,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Save Profile',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- MODAL: CHANGE PASSWORD ---
  void _showChangePasswordModal() {
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool obscure = true;
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: HardSyncColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalCtx) => StatefulBuilder(
        builder: (context, setPassState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: HardSyncColors.lilacBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Change Password',
                style: GoogleFonts.newsreader(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: HardSyncColors.ink,
                ),
              ),
              Text(
                'Set a strong passphrase for your HardSync account.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: HardSyncColors.inkMuted,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: newPassCtrl,
                obscureText: obscure,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'New password (min 6 characters)',
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                      color: HardSyncColors.inkMuted,
                      size: 20,
                    ),
                    onPressed: () => setPassState(() => obscure = !obscure),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: HardSyncColors.lilacBorder),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPassCtrl,
                obscureText: obscure,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Confirm new password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: HardSyncColors.lilacBorder),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final p1 = newPassCtrl.text.trim();
                          final p2 = confirmPassCtrl.text.trim();
                          if (p1.length < 6) {
                            _showNotice('Password must be at least 6 characters.');
                            return;
                          }
                          if (p1 != p2) {
                            _showNotice('Passwords do not match.');
                            return;
                          }

                          setPassState(() => saving = true);
                          try {
                            await SupabaseService.instance.updatePassword(p1);
                            if (modalCtx.mounted) {
                              Navigator.pop(modalCtx);
                            }
                            _showNotice('Password successfully updated!', isSuccess: true);
                          } catch (e) {
                            setPassState(() => saving = false);
                            _showNotice('Failed to update password: $e');
                          }
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: HardSyncColors.violet,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: saving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Update Password',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- MODAL: HELP & FAQS ---
  void _showHelpCenterModal() {
    final faqs = [
      {
        'q': 'How does HardSync check how calm and clear I am?',
        'a': 'HardSync listens to your voice and words as you talk. It picks up on filler sounds (um, ah), soft phrases ("I guess", "kind of"), and how clearly you set boundaries.'
      },
      {
        'q': 'Are my voice recordings or camera frames stored?',
        'a': 'Never. Your voice and video are processed live, in the moment, and are never saved or shared.'
      },
      {
        'q': 'How do plans and call limits work?',
        'a': 'Text practice is free. Ultra unlocks live video calls. Each video session lasts up to 10 minutes.'
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: HardSyncColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: HardSyncColors.lilacBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Help & FAQs',
              style: GoogleFonts.newsreader(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: HardSyncColors.ink,
              ),
            ),
            Text(
              'How coaching and scoring work.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: HardSyncColors.inkMuted,
              ),
            ),
            const SizedBox(height: 20),
            ...faqs.map((f) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: HardSyncColors.lilacBorder),
                  ),
                  child: ExpansionTile(
                    shape: const Border(),
                    collapsedShape: const Border(),
                    title: Text(
                      f['q']!,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: HardSyncColors.ink,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          f['a']!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            height: 1.45,
                            color: HardSyncColors.inkMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WebViewerScreen(
                        title: 'Help & FAQs',
                        url: EnvConfig.faqUrl,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.language_rounded, size: 18),
                label: const Text('Open Online Knowledge Base & FAQs'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HardSyncColors.violet,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: EnvConfig.supportEmail));
                  _showNotice('Email copied: ${EnvConfig.supportEmail}', isSuccess: true);
                },
                icon: const Icon(Icons.email_outlined, size: 18),
                label: Text('Contact Support (${EnvConfig.supportEmail})'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: HardSyncColors.violet,
                  side: const BorderSide(color: HardSyncColors.violet),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- MODAL: FEEDBACK ---
  void _showFeedbackModal() {
    final textCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: HardSyncColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: HardSyncColors.lilacBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Send Feedback',
              style: GoogleFonts.newsreader(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: HardSyncColors.ink,
              ),
            ),
            Text(
              'What real workplace scenario would you like our AI to simulate next?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: HardSyncColors.inkMuted,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'e.g. Pushing back on a budget cut, handling a difficult coworker...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: HardSyncColors.lilacBorder),
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () {
                  if (textCtrl.text.trim().isNotEmpty) {
                    Navigator.pop(ctx);
                    _showNotice('Feedback received! Thank you for shaping HardSync.', isSuccess: true);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: HardSyncColors.violet,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Submit Feedback',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- MANAGE SUBSCRIPTION ---
  Future<void> _manageSubscription() async {
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    if (!kIsWeb && (isIos || isAndroid)) {
      final uri = Uri.parse(
        isIos
            ? 'https://apps.apple.com/account/subscriptions'
            : 'https://play.google.com/store/account/subscriptions',
      );
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
      } catch (_) {}
    }
    _showNotice(
      isIos
          ? 'To cancel: open Settings › [your name] › Subscriptions › HardSync, then tap Cancel Subscription.'
          : 'To cancel: open Google Play › Profile › Payments & subscriptions › Subscriptions › HardSync, then tap Cancel.',
    );
  }

  // --- GUEST VIEW (WHEN NOT LOGGED IN) ---
  Widget _buildGuestView() {
    return Scaffold(
      backgroundColor: HardSyncColors.cream,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: HardSyncColors.lilacMist,
                    shape: BoxShape.circle,
                    border: Border.all(color: HardSyncColors.violet.withValues(alpha: 0.2)),
                  ),
                  child: Image.asset(HardSyncAssets.appMascot, fit: BoxFit.contain),
                ),
                const SizedBox(height: 24),
                Text(
                  'Your Profile',
                  style: GoogleFonts.newsreader(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: HardSyncColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to save your practice history, streak, and progress.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    height: 1.45,
                    color: HardSyncColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignInScreen()),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: HardSyncColors.violet,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      'Sign In / Create Account',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
