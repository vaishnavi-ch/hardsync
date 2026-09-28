import '../theme/hardsync_assets.dart';

class EarnedBadge {
  final String id;
  final String label;
  final String description;
  final String asset;
  final bool earned;
  final int count;
  final int target;

  const EarnedBadge({
    required this.id,
    required this.label,
    required this.description,
    required this.asset,
    required this.earned,
    this.count = 0,
    this.target = 2,
  });
}

class PracticeStats {
  final int sessionCount;
  final int dayStreak;
  final int? averageScore;
  final int totalMinutes;
  final List<EarnedBadge> badges;

  const PracticeStats({
    required this.sessionCount,
    required this.dayStreak,
    required this.averageScore,
    required this.totalMinutes,
    required this.badges,
  });

  int get progressPercent {
    if (badges.isEmpty) return 0;
    final earned = badges.where((b) => b.earned).length;
    return ((earned / badges.length) * 100).round();
  }

  EarnedBadge? get nextBadge {
    for (final badge in badges) {
      if (!badge.earned) return badge;
    }
    return null;
  }

  static const _badgeCategoryGroups = <String, List<String>>{
    'clear_communicator': ['communication basics'],
    'conflict_navigator': ['conflict and alignment'],
    'empathy_leader': ['listening'],
    'feedback_builder': ['feedback'],
    'team_builder': ['delegation'],
    'one_on_one_champion': ['one-to-ones', 'repair and reflection', 'peer transition'],
    'executive_presence': ['managing up', 'leading change', 'negotiations', 'direct reports'],
  };

  static const _badgeMeta = <String, (String, String, String)>{
    'clear_communicator': (
      'Clear Communicator',
      'Complete 2 Communication Basics scenarios',
      HardSyncAssets.badgeClearCommunicatorBadge,
    ),
    'conflict_navigator': (
      'Conflict Navigator',
      'Complete 2 Conflict & Alignment scenarios',
      HardSyncAssets.badgeConflictNavigatorBadge,
    ),
    'empathy_leader': (
      'Empathy Leader',
      'Complete 2 Listening scenarios',
      HardSyncAssets.badgeEmpathyLeaderBadge,
    ),
    'feedback_builder': (
      'Feedback Builder',
      'Complete 2 Feedback scenarios',
      HardSyncAssets.badgeFeedbackBuilderBadge,
    ),
    'team_builder': (
      'Team Builder',
      'Complete 2 Delegation scenarios',
      HardSyncAssets.badgeTeamBuilderBadge,
    ),
    'one_on_one_champion': (
      '1:1 Champion',
      'Complete 2 one-to-one style scenarios',
      HardSyncAssets.badgeOneononeChampionBadge,
    ),
    'executive_presence': (
      'Executive Presence',
      'Complete 2 Managing Up / Leading Change scenarios',
      HardSyncAssets.badgeExecutivePresenceBadge,
    ),
  };

  static PracticeStats fromSessions(List<Map<String, dynamic>> sessions) {
    final categoryCounts = <String, int>{};
    final dates = <DateTime>{};
    final scores = <num>[];
    var totalSeconds = 0;

    for (final session in sessions) {
      final createdAt = session['created_at'];
      if (createdAt is String) {
        final parsed = DateTime.tryParse(createdAt)?.toLocal();
        if (parsed != null) {
          dates.add(DateTime(parsed.year, parsed.month, parsed.day));
        }
      }
      final score = session['overall_score'];
      if (score is num) scores.add(score);

      final duration = session['duration_seconds'];
      if (duration is num) totalSeconds += duration.round();

      final category = session['scenarios'] is Map
          ? (session['scenarios']['category']?.toString().toLowerCase() ?? '')
          : '';
      if (category.isNotEmpty) {
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      }
    }

    final badges = _badgeCategoryGroups.entries.map((entry) {
      final count = entry.value.fold<int>(
        0,
        (sum, category) => sum + (categoryCounts[category] ?? 0),
      );
      final meta = _badgeMeta[entry.key]!;
      return EarnedBadge(
        id: entry.key,
        label: meta.$1,
        description: meta.$2,
        asset: meta.$3,
        earned: count >= 2,
        count: count,
      );
    }).toList();

    return PracticeStats(
      sessionCount: sessions.length,
      dayStreak: _computeStreak(dates),
      averageScore: scores.isEmpty
          ? null
          : (scores.reduce((a, b) => a + b) / scores.length).round(),
      totalMinutes: (totalSeconds / 60).round(),
      badges: badges,
    );
  }

  static int _computeStreak(Set<DateTime> dates) {
    if (dates.isEmpty) return 0;
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    final yesterdayKey = todayKey.subtract(const Duration(days: 1));

    var cursor = dates.contains(todayKey)
        ? todayKey
        : (dates.contains(yesterdayKey) ? yesterdayKey : null);
    if (cursor == null) return 0;

    var streak = 0;
    while (dates.contains(cursor)) {
      streak++;
      cursor = cursor!.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
