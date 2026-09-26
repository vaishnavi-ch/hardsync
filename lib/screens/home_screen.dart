import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/supabase_service.dart';
import '../theme/hardsync_assets.dart';
import '../theme/hardsync_theme.dart';
import 'learning_screen.dart';
import 'scenario_hub_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onOpenLearn, this.onOpenPractice});

  final VoidCallback? onOpenLearn;
  final VoidCallback? onOpenPractice;

  @override
  Widget build(BuildContext context) {
    final rawName = SupabaseService.instance.currentUserName.trim();
    final name = rawName.isEmpty ? 'Alex' : rawName.split(' ').first;
    return Scaffold(
      backgroundColor: HardSyncColors.cream,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: wide ? 1080 : 520),
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    wide ? 28 : 20,
                    wide ? 26 : 18,
                    wide ? 28 : 20,
                    32,
                  ),
                  children: [
                    _Header(name: name),
                    const SizedBox(height: 18),
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildProgressColumn(context)),
                          const SizedBox(width: 22),
                          Expanded(child: _buildActionColumn(context)),
                        ],
                      )
                    else ...[
                      _buildProgressColumn(context),
                      const SizedBox(height: 22),
                      _buildActionColumn(context),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProgressColumn(BuildContext context) => Column(
    children: [
      _ProgressHero(
        onTap: onOpenLearn ?? () => _open(context, const LearningScreen()),
      ),
      const SizedBox(height: 14),
      const Row(
        children: [
          Expanded(
            child: _Metric(
              icon: HardSyncAssets.gamifyPracticeStreakFlame,
              value: '0',
              label: 'Day streak',
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: _Metric(
              icon: HardSyncAssets.iconBookOpen,
              value: '0',
              label: 'Lessons',
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: _Metric(
              icon: HardSyncAssets.iconStopwatchSpeed,
              value: '0',
              label: 'Practice',
            ),
          ),
        ],
      ),
    ],
  );

  Widget _buildActionColumn(BuildContext context) => Column(
    children: [
      _SectionTitle(
        title: 'Start learning',
        action: 'Explore',
        onTap: onOpenLearn,
      ),
      const SizedBox(height: 10),
      _ContinueCard(
        onTap: onOpenLearn ?? () => _open(context, const LearningScreen()),
      ),
      const SizedBox(height: 18),
      _SectionTitle(
        title: "Today's focus",
        action: 'Practice',
        onTap: onOpenPractice,
      ),
      const SizedBox(height: 10),
      _PracticeCard(
        onTap:
            onOpenPractice ?? () => _open(context, const ScenarioHubScreen()),
      ),
      const SizedBox(height: 14),
      const _Encouragement(),
    ],
  );

  static void _open(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const AppAvatar(HardSyncAssets.avatarCurrentUser, size: 54),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good morning,',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: HardSyncColors.inkMuted),
            ),
            Text(
              '$name!',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
      _CircleButton(
        icon: CupertinoIcons.bell,
        onTap: () => ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('You are all caught up.'))),
      ),
    ],
  );
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: HardSyncColors.surface,
    shape: const CircleBorder(side: BorderSide(color: HardSyncColors.border)),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox(
        width: 46,
        height: 46,
        child: Icon(icon, color: HardSyncColors.ink, size: 22),
      ),
    ),
  );
}

class _ProgressHero extends StatelessWidget {
  const _ProgressHero({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 360;
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          height: compact ? 360 : 390,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: HardSyncColors.oliveMist,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: HardSyncColors.lilacBorder),
          ),
          child: Stack(
            children: [
              const Positioned(
                right: -18,
                bottom: -12,
                width: 270,
                height: 238,
                child: AppIllustration(
                  HardSyncAssets.illusManagerJourneyMap,
                  fit: BoxFit.contain,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR MANAGER PATH',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: HardSyncColors.violet,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Lead with\nconfidence',
                      style: GoogleFonts.newsreader(
                        fontSize: compact ? 30 : 40,
                        height: .95,
                        fontWeight: FontWeight.w700,
                        color: HardSyncColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your leadership journey',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    Container(
                      width: 185,
                      padding: EdgeInsets.all(compact ? 10 : 13),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .88),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Build your skills',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          if (compact)
                            Text(
                              'Learn at your own pace',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            )
                          else ...[
                            const SizedBox(height: 8),
                            Text(
                              'Learn at your own pace',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value, required this.label});
  final String icon;
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    height: 126,
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
    decoration: BoxDecoration(
      color: HardSyncColors.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: HardSyncColors.border),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppIcon(icon, size: 28),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        Text(
          label,
          maxLines: 1,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: HardSyncColors.inkMuted),
        ),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.action, this.onTap});
  final String title;
  final String action;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      TextButton(onPressed: onTap, child: Text(action)),
    ],
  );
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => _FeatureCard(
    onTap: onTap,
    tint: HardSyncColors.lilacMist,
    illustration: HardSyncAssets.illusActiveListening,
    eyebrow: 'START LEARNING',
    title: 'Make your 1:1 useful',
    subtitle: 'Set a goal, hear what matters, and agree on a next step.',
  );
}

class _PracticeCard extends StatelessWidget {
  const _PracticeCard({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => _FeatureCard(
    onTap: onTap,
    tint: HardSyncColors.apricotMist,
    illustration: HardSyncAssets.illusToughFeedbackMoment,
    eyebrow: '5–7 MIN · INTERMEDIATE',
    title: 'Give constructive feedback',
    subtitle: 'Rehearse a clear, kind conversation with a teammate.',
  );
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.onTap,
    required this.tint,
    required this.illustration,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });
  final VoidCallback onTap;
  final Color tint;
  final String illustration;
  final String eyebrow;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 330;
      final largeArtwork = constraints.maxWidth >= 420;
      return Material(
        color: tint,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            height: compact ? 174 : (largeArtwork ? 186 : 152),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: HardSyncColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: compact ? 76 : (largeArtwork ? 148 : 92),
                  height: compact ? 94 : (largeArtwork ? 156 : 102),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .55),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: AppIllustration(illustration),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        eyebrow,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: HardSyncColors.violet,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        maxLines: 2,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  CupertinoIcons.chevron_right,
                  size: 19,
                  color: HardSyncColors.inkMuted,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _Encouragement extends StatelessWidget {
  const _Encouragement();
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 330;
      return Container(
        height: compact ? 152 : 152,
        padding: EdgeInsets.only(right: compact ? 12 : 18),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: HardSyncColors.oliveMist,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            SizedBox(
              width: compact ? 100 : 125,
              child: const AppIllustration(
                HardSyncAssets.gamifyCoachCelebration,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Small steps lead to big growth.',
                    style: GoogleFonts.newsreader(
                      fontSize: compact ? 18 : 20,
                      height: 1.05,
                      fontWeight: FontWeight.w700,
                      color: HardSyncColors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Keep your momentum going.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
