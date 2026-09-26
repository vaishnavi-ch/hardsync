import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/learning_course.dart';
import '../services/supabase_service.dart';
import '../theme/hardsync_assets.dart';
import '../theme/hardsync_theme.dart';
import 'learning_screen.dart';
import 'session_detail_screen.dart';
import 'scenario_hub_screen.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late Future<List<Map<String, dynamic>>> _history;
  Set<String> _learningDone = {};

  @override
  void initState() {
    super.initState();
    _history = SupabaseService.instance.fetchUserSessionHistory();
    SharedPreferences.getInstance().then((prefs) {
      if (mounted) {
        setState(
          () => _learningDone =
              prefs.getStringList('learning_progress')?.toSet() ?? {},
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: HardSyncColors.cream,
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
                _history = SupabaseService.instance.fetchUserSessionHistory();
              }),
            );
          }
          final sessions = snapshot.data ?? const [];
          if (sessions.isEmpty) return _emptyState(context);
          final scores = sessions
              .map((session) => session['overall_score'])
              .whereType<num>()
              .toList();
          final average = scores.isEmpty
              ? null
              : (scores.reduce((a, b) => a + b) / scores.length).round();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              Text(
                'Your roadmap',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Small steps to handle real manager conversations with more confidence.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              _roadmapHero(context),
              const SizedBox(height: 17),
              Text(
                'Your learning journey',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              ...LearningCatalog.paths.indexed.map(
                (entry) => _pathCard(context, entry.$2, entry.$1),
              ),
              const SizedBox(height: 22),
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
                  Expanded(child: _statCard('Sessions', '${sessions.length}')),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      'Average score',
                      average == null ? 'No score' : '$average%',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Recent practice',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              ...sessions.map((session) {
                final scenario = session['scenarios'];
                final title = scenario is Map
                    ? scenario['title']?.toString() ?? 'Practice session'
                    : 'Practice session';
                final score = session['overall_score'];
                return Card(
                  color: HardSyncColors.surface,
                  child: ListTile(
                    title: Text(title),
                    subtitle: Text(
                      score is num
                          ? 'Saved score: ${score.round()}%'
                          : 'Session saved',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      final id = session['id']?.toString();
                      if (id != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SessionDetailScreen(sessionId: id),
                          ),
                        );
                      }
                    },
                  ),
                );
              }),
            ],
          );
        },
      ),
    ),
  );

  Widget _emptyState(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
    children: [
      Text('Your roadmap', style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 6),
      Text(
        'Small steps to handle real manager conversations with more confidence.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 16),
      _roadmapHero(context),
      const SizedBox(height: 17),
      Text(
        'Your learning journey',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 10),
      ...LearningCatalog.paths.indexed.map(
        (entry) => _pathCard(context, entry.$2, entry.$1),
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

  Widget _roadmapHero(BuildContext context) => Container(
    height: 300,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: HardSyncColors.lilacMist,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Stack(
      children: [
        const Positioned(
          right: 0,
          bottom: -5,
          width: 210,
          height: 190,
          child: AppIllustration(HardSyncAssets.illusManagerJourneyMap),
        ),
        Padding(
          padding: const EdgeInsets.all(18),
          child: SizedBox(
            width: 210,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR LEADERSHIP ROADMAP',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .8,
                    color: HardSyncColors.violet,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  'Build skills\none conversation at a time.',
                  style: GoogleFonts.newsreader(
                    fontSize: 25,
                    height: 1.02,
                    fontWeight: FontWeight.w700,
                    color: HardSyncColors.ink,
                  ),
                ),
                const Spacer(),
                Text(
                  'Learn · practise · reflect',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: HardSyncColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _pathCard(BuildContext context, LearningPath path, int index) {
    final courses = path.courseIds.map(LearningCatalog.byId).toList();
    final total = courses.fold<int>(
      0,
      (sum, course) => sum + course.lessons.length,
    );
    final done = courses.fold<int>(
      0,
      (sum, course) =>
          sum +
          course.lessons.indexed
              .where(
                (lesson) => _learningDone.contains('${course.id}:${lesson.$1}'),
              )
              .length,
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HardSyncColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LearningScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 67,
                height: 67,
                decoration: BoxDecoration(
                  color: HardSyncColors.lilacMist,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: AppIllustration(path.illustration),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      path.title,
                      style: GoogleFonts.newsreader(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: HardSyncColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$done of $total quick bytes · ${courses.length} topics',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: total == 0 ? 0 : done / total,
                        minHeight: 5,
                        color: HardSyncColors.violet,
                        backgroundColor: HardSyncColors.lilacMist,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: HardSyncColors.violet,
              ),
            ],
          ),
        ),
      ),
    );
  }

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
