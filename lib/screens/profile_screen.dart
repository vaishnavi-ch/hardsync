import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/supabase_service.dart';
import '../theme/hardsync_assets.dart';
import '../theme/hardsync_theme.dart';
import 'sign_in_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    SupabaseService.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    SupabaseService.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (SupabaseService.instance.isAuthenticated) {
      return const AccountScreen(embedded: true);
    }
    return Scaffold(
      backgroundColor: HardSyncColors.cream,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            final illustration = Container(
              height: wide ? 430 : 220,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    HardSyncColors.lilacMist,
                    HardSyncColors.apricotMist,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const AppIllustration(
                HardSyncAssets.illusPracticeReflectImprove,
              ),
            );
            final details = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Your Profile',
                  style: GoogleFonts.newsreader(
                    fontSize: wide ? 40 : 32,
                    fontWeight: FontWeight.w700,
                    color: HardSyncColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Keep your practice history and progress in one place.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    height: 1.45,
                    color: HardSyncColors.inkMuted,
                  ),
                ),
                if (!wide) ...[const SizedBox(height: 18), illustration],
                const SizedBox(height: 18),
                const _ProfileBenefit(
                  asset: HardSyncAssets.iconCloudUpload,
                  title: 'Sync your practice history',
                  subtitle: 'Continue from any supported device.',
                ),
                const SizedBox(height: 10),
                const _ProfileBenefit(
                  asset: HardSyncAssets.iconTrophyCup,
                  title: 'Track your growth',
                  subtitle: 'Keep progress, feedback, and milestones together.',
                ),
                const SizedBox(height: 10),
                const _ProfileBenefit(
                  asset: HardSyncAssets.iconShieldVerified,
                  title: 'Protect your progress',
                  subtitle:
                      'Your account keeps your personal learning record secure.',
                ),
                const SizedBox(height: 22),
                SizedBox(
                  height: 54,
                  child: FilledButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignInScreen()),
                    ),
                    child: const Text('Sign in or create account'),
                  ),
                ),
              ],
            );
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: wide ? 980 : 440),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    wide ? 28 : 22,
                    wide ? 32 : 22,
                    wide ? 28 : 22,
                    28,
                  ),
                  children: [
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: illustration),
                          const SizedBox(width: 34),
                          Expanded(child: details),
                        ],
                      )
                    else
                      details,
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileBenefit extends StatelessWidget {
  final String asset;
  final String title;
  final String subtitle;
  const _ProfileBenefit({
    required this.asset,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: HardSyncColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: HardSyncColors.border),
    ),
    child: Row(
      children: [
        AppIcon(asset, size: 34),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: HardSyncColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  color: HardSyncColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
