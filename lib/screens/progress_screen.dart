import 'package:flutter/material.dart';

import '../services/practice_stats.dart';
import '../services/session_history.dart';
import '../theme/hardsync_assets.dart';
import '../theme/hardsync_theme.dart';
import 'scenario_hub_screen.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late Future<List<Map<String, dynamic>>> _history;

  @override
  void initState() {
    super.initState();
    _history = SessionHistoryService.fetchAll();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8F6FC),
    body: SafeArea(
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _history,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _messageState(
              context,
              'Progress could not be loaded',
              'Check your connection and try again.',
              onRetry: () => setState(() {
                _history = SessionHistoryService.fetchAll();
              }),
            );
          }
          final sessions = snapshot.data ?? const [];
          if (sessions.isEmpty) return _emptyState(context);
          final stats = PracticeStats.fromSessions(sessions);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              Text(
                'Your performance',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Track how your rehearsals are going over time.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Text(
                'Practice progress',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Based on your saved practice sessions.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _statCard('Day streak', '${stats.dayStreak}'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard('Sessions', '${stats.sessionCount}'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      'Average score',
                      stats.averageScore == null
                          ? 'No score'
                          : '${stats.averageScore}%',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Badges',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Earned by completing rehearsals in each skill area.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              _badgesGrid(stats.badges),
            ],
          );
        },
      ),
    ),
  );

  Widget _emptyState(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
    children: [
      Text(
        'Your performance',
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      const SizedBox(height: 6),
      Text(
        'Track how your rehearsals are going over time.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: HardSyncColors.border),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 72,
              height: 72,
              child: AppIllustration(HardSyncAssets.illusSafeRehearsalRoom),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your practice results will show here',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Try a 1:1 scenario and come back to see what is improving.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ScenarioHubScreen(),
                      ),
                    ),
                    child: const Text('Choose a scenario'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _messageState(
    BuildContext context,
    String title,
    String message, {
    required VoidCallback? onRetry,
  }) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.insights_outlined,
            size: 52,
            color: HardSyncColors.violet,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          if (onRetry != null)
            OutlinedButton(onPressed: onRetry, child: const Text('Try again'))
          else
            FilledButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScenarioHubScreen()),
              ),
              child: const Text('Start a rehearsal'),
            ),
        ],
      ),
    ),
  );

  Widget _badgesGrid(List<EarnedBadge> badges) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: badges.length,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.82,
    ),
    itemBuilder: (context, index) {
      final badge = badges[index];
      return Opacity(
        opacity: badge.earned ? 1 : 0.35,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: HardSyncColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: HardSyncColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: AppIllustration(badge.asset, fit: BoxFit.contain),
              ),
              const SizedBox(height: 6),
              Text(
                badge.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _statCard(String label, String value) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: HardSyncColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: HardSyncColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: HardSyncColors.inkMuted)),
        const SizedBox(height: 6),
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
      ],
    ),
  );
}
