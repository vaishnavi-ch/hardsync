import 'backend_service.dart';
import 'supabase_service.dart';

/// Sessions can be persisted through two paths: the client writes directly to
/// Supabase's `session_attempts` table (has score + scenario category, used
/// for streaks/badges), while the backend's call lifecycle writes to its own
/// `practice_sessions` table (has transcript/duration but no score/category).
/// This normalizes both into the shape `PracticeStats` and the history/
/// performance screens expect, so a session started either way shows up
/// consistently everywhere.
class SessionHistoryService {
  static Future<List<Map<String, dynamic>>> fetchAll() async {
    if (SupabaseService.instance.isAuthenticated) {
      try {
        final rows = await SupabaseService.instance.fetchUserSessionHistory();
        if (rows.isNotEmpty) return rows;
      } catch (_) {}
    }
    try {
      final res = await BackendService.request('/api/history');
      final reports = res['reports'];
      if (reports is List) {
        return reports.whereType<Map>().map((report) {
          return <String, dynamic>{
            'id': report['id'],
            'created_at': report['completedAt'],
            'duration_seconds': report['durationSeconds'],
            'overall_score': report['overallScore'],
            'scenarios': {
              'title': report['title'],
              'category': report['category'],
            },
          };
        }).toList();
      }
    } catch (_) {}
    return [];
  }
}
