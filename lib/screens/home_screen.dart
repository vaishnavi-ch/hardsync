import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/practice_stats.dart';
import '../services/session_history.dart';
import '../services/supabase_service.dart';
import '../theme/hardsync_assets.dart';
import '../theme/hardsync_theme.dart';
import 'scenario_hub_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onOpenPractice});

  final VoidCallback? onOpenPractice;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<PracticeStats> _stats;

  @override
  void initState() {
    super.initState();
    _stats = _loadStats();
  }

  Future<PracticeStats> _loadStats() async {
    final sessions = await SessionHistoryService.fetchAll();
    return PracticeStats.fromSessions(sessions);
  }

  VoidCallback? get onOpenPractice => widget.onOpenPractice;

  @override
  Widget build(BuildContext context) {
    final rawName = SupabaseService.instance.currentUserName.trim();
    final name = rawName.isEmpty ? 'Alex' : rawName.split(' ').first;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FC),
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

  Widget _buildProgressColumn(BuildContext context) => FutureBuilder<PracticeStats>(
    future: _stats,
    builder: (context, snapshot) {
      final stats = snapshot.data;
      return Column(
        children: [
          _ProgressHero(
            stats: stats,
            onTap:
                onOpenPractice ??
                () => _open(context, const ScenarioHubScreen()),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  icon: HardSyncAssets.gamifyPracticeStreakFlame,
                  value: '${stats?.dayStreak ?? 0}',
                  label: 'Day streak',
                  tint: HardSyncColors.coralMist,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Metric(
                  icon: HardSyncAssets.iconBookOpen,
                  value: '${stats?.sessionCount ?? 0}',
                  label: 'Sessions done',
                  tint: HardSyncColors.lilacMist,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Metric(
                  icon: HardSyncAssets.iconHourglassTimer,
                  value: stats == null
                      ? '0h'
                      : '${(stats.totalMinutes / 60).toStringAsFixed(1)}h',
                  label: 'Time spent',
                  tint: HardSyncColors.sunMist,
                ),
              ),
            ],
          ),
        ],
      );
    },
  );

  Widget _buildActionColumn(BuildContext context) => FutureBuilder<PracticeStats>(
    future: _stats,
    builder: (context, snapshot) {
      final stats = snapshot.data;
      return Column(
        children: [
          _SectionTitle(
            title: 'Continue practicing',
            action: 'See all',
            onTap: onOpenPractice,
          ),
          const SizedBox(height: 10),
          _ContinueCard(
            badge: stats?.nextBadge,
            onTap:
                onOpenPractice ??
                () => _open(context, const ScenarioHubScreen()),
          ),
          const SizedBox(height: 14),
          const _Encouragement(),
        ],
      );
    },
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
        child: Text(
          'Hey, $name!',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      _CircleButton(
        icon: CupertinoIcons.search,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ScenarioHubScreen()),
        ),
      ),
      const SizedBox(width: 10),
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
  const _ProgressHero({required this.onTap, required this.stats});
  final VoidCallback onTap;
  final PracticeStats? stats;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 360;
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          height: compact ? 260 : 290,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE9E2FB).withValues(alpha: .4),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: AppIllustration(
            HardSyncAssets.illusVoiceRoleplay,
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
          ),
        ),
      );
    },
  );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.value,
    required this.label,
    required this.tint,
  });
  final String icon;
  final String value;
  final String label;
  final Color tint;
  @override
  Widget build(BuildContext context) => Container(
    height: 170,
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
    decoration: BoxDecoration(
      color: HardSyncColors.surface,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .05),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
          padding: const EdgeInsets.all(12),
          child: AppIcon(icon, size: 44),
        ),
        const SizedBox(height: 8),
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
  const _ContinueCard({required this.onTap, required this.badge});
  final VoidCallback onTap;
  final EarnedBadge? badge;
  @override
  Widget build(BuildContext context) {
    final title = badge?.label ?? 'Keep practicing';
    final subtitle = badge == null
        ? 'All rehearsal badges earned'
        : '${badge!.count} / ${badge!.target} rehearsals';
    final fraction = badge == null
        ? 1.0
        : (badge!.count / badge!.target).clamp(0.0, 1.0);
    return Material(
      color: HardSyncColors.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: HardSyncColors.lilacMist,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.book_fill,
                  color: HardSyncColors.violet,
                  size: 34,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 6,
                        backgroundColor: HardSyncColors.lilacMist,
                        valueColor: const AlwaysStoppedAnimation(
                          HardSyncColors.violet,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
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
  }
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
