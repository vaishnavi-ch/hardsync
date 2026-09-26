import '../models/scenario.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env_config.dart';
import '../models/debrief_report.dart';

class SupabaseService extends ChangeNotifier {
  static final SupabaseService instance = SupabaseService._internal();

  SupabaseService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize Supabase client if configured in EnvConfig
  Future<void> init() async {
    if (_isInitialized) return;

    if (EnvConfig.isSupabaseConfigured) {
      try {
        await Supabase.initialize(
          url: EnvConfig.supabaseUrl,
          // ignore: deprecated_member_use
          anonKey: EnvConfig.supabaseAnonKey,
          debug: kDebugMode,
        );
        _isInitialized = true;
        debugPrint(
          '[SupabaseService] Connected to cloud PostgreSQL instance: ${EnvConfig.supabaseUrl}',
        );

        // Listen to live auth state changes from Supabase (including OAuth redirects)
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
          debugPrint('[SupabaseService] Auth state changed: ${data.event}');
          notifyListeners();
        });
      } catch (e) {
        debugPrint(
          '[SupabaseService] Cloud connection failed: $e. Authentication unavailable.',
        );
        _isInitialized = false;
      }
    } else {
      debugPrint(
        '[SupabaseService] No Supabase credentials in .env. Authentication unavailable.',
      );
      _isInitialized = false;
    }
  }

  SupabaseClient? get client =>
      _isInitialized ? Supabase.instance.client : null;

  bool get isAuthenticated =>
      (_isInitialized && client?.auth.currentSession != null);

  String get currentUserName =>
      client?.auth.currentUser?.userMetadata?['full_name'] as String? ??
      'Guest';

  String get currentUserEmail => client?.auth.currentUser?.email ?? '';

  String? get currentUserId => client?.auth.currentUser?.id;

  Future<Map<String, dynamic>> fetchOwnProfile() async {
    final userId = currentUserId;
    if (client == null || userId == null) {
      throw StateError('Sign in to load your profile.');
    }
    return Map<String, dynamic>.from(
      await client!.from('profiles').select().eq('id', userId).single(),
    );
  }

  Future<void> updateOwnProfile(Map<String, dynamic> changes) async {
    final userId = currentUserId;
    if (client == null || userId == null) {
      throw StateError('Sign in to update your profile.');
    }
    const allowed = {
      'full_name',
      'avatar_url',
      'leadership_role',
      'onboarding_completed',
      'selected_goal_ids',
      'selected_user_persona_id',
      'settings',
    };
    final safe = Map<String, dynamic>.fromEntries(
      changes.entries.where((entry) => allowed.contains(entry.key)),
    );
    if (safe.isEmpty) return;
    await client!.from('profiles').update(safe).eq('id', userId);
    notifyListeners();
  }

  Future<Set<String>> fetchLearningProgress() async {
    final userId = currentUserId;
    if (client == null || userId == null) {
      throw StateError('Sign in to load learning progress.');
    }
    final rows = await client!
        .from('learning_progress')
        .select('course_id,lesson_position')
        .eq('user_id', userId);
    return rows
        .map<String>((row) => '${row['course_id']}:${row['lesson_position']}')
        .toSet();
  }

  Future<void> completeLesson(
    String courseId,
    int lessonPosition, {
    String? reflection,
  }) async {
    final userId = currentUserId;
    if (client == null || userId == null) {
      throw StateError('Sign in to save learning progress.');
    }
    await client!.from('learning_progress').upsert({
      'user_id': userId,
      'course_id': courseId,
      'lesson_position': lessonPosition,
      'completed_at': DateTime.now().toUtc().toIso8601String(),
      if (reflection != null && reflection.trim().isNotEmpty)
        'reflection': reflection.trim(),
    });
  }

  // --- AUTHENTICATION METHODS ---

  Future<void> signInAsDemo({String? name, String? email}) async {
    throw StateError('Demo authentication is unavailable. Please sign in.');
  }

  Future<bool> signInWithEmail(String email, String password) async {
    if (!_isInitialized || client == null) {
      await init();
    }

    if (_isInitialized && client != null) {
      try {
        final response = await client!.auth.signInWithPassword(
          email: email,
          password: password,
        );
        notifyListeners();
        return response.user != null;
      } catch (e) {
        debugPrint('[SupabaseService] Email sign-in failed: $e');
        rethrow;
      }
    } else {
      throw StateError('Authentication is unavailable. Please reconnect.');
    }
  }

  Future<bool> signUpWithEmail(
    String email,
    String password, {
    String? fullName,
    String? leadershipRole,
  }) async {
    if (!_isInitialized || client == null) {
      await init();
    }

    if (_isInitialized && client != null) {
      try {
        final response = await client!.auth.signUp(
          email: email,
          password: password,
          emailRedirectTo: kIsWeb
              ? (Uri.base.origin.isNotEmpty ? Uri.base.origin : null)
              : 'talkbound://login-callback',
          data: {
            'full_name': fullName ?? 'Executive Trainee',
            'leadership_role': leadershipRole ?? 'Engineering Leader',
          },
        );
        debugPrint(
          '[SupabaseService] Sign-up response: user=${response.user?.id}, session=${response.session != null}',
        );
        notifyListeners();
        return response.user != null;
      } catch (e) {
        debugPrint('[SupabaseService] Sign-up failed: $e');
        rethrow;
      }
    } else {
      throw StateError('Authentication is unavailable. Please reconnect.');
    }
  }

  Future<bool> signInWithOAuth(OAuthProvider provider) async {
    if (!_isInitialized || client == null) {
      await init();
    }

    if (_isInitialized && client != null) {
      try {
        // Compute the proper redirect URL
        // On Web: redirect back to current origin (e.g. http://localhost:54321 or your live domain)
        // On Mobile: redirect back via custom deep link scheme
        final redirectUrl = kIsWeb
            ? (Uri.base.origin.isNotEmpty ? Uri.base.origin : null)
            : 'talkbound://login-callback';

        debugPrint(
          '[SupabaseService] Launching OAuth with provider: ${provider.name}, redirectTo: $redirectUrl',
        );
        final success = await client!.auth.signInWithOAuth(
          provider,
          redirectTo: redirectUrl,
          authScreenLaunchMode: LaunchMode.platformDefault,
        );
        return success;
      } catch (e) {
        debugPrint('[SupabaseService] OAuth sign-in failed: $e');
        rethrow;
      }
    } else {
      throw Exception(
        'Supabase client could not connect. Please ensure internet access and that your Supabase credentials are valid.',
      );
    }
  }

  Future<void> signOut() async {
    if (_isInitialized && client != null) {
      try {
        await client!.auth.signOut();
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> sendPasswordReset(String email) async {
    if (!_isInitialized || client == null) await init();
    if (!_isInitialized || client == null) {
      throw StateError('Authentication is unavailable. Please reconnect.');
    }
    await client!.auth.resetPasswordForEmail(
      email,
      redirectTo: kIsWeb ? Uri.base.origin : 'hardsync://reset-password',
    );
  }

  /// Account deletion is performed server-side so the service-role key never
  /// reaches the client. The deployed function should delete the authenticated
  /// user and cascade their private data.
  Future<void> deleteAccount() async {
    if (!_isInitialized || client == null || currentUserId == null) {
      throw StateError('Sign in before deleting your account.');
    }
    final response = await client!.functions.invoke('delete-account');
    if (response.status < 200 || response.status >= 300) {
      throw StateError('Account deletion could not be completed.');
    }
    await signOut();
  }

  // --- DATABASE & SESSION METHODS ---

  Future<String?> saveSessionAttempt({required DebriefReport report}) async {
    if (!_isInitialized || client == null) {
      throw StateError('Sign in before saving a session.');
    }

    try {
      final userId = client!.auth.currentUser?.id;
      if (userId == null) throw StateError('Sign in before saving a session.');

      // Register custom scenarios before inserting their foreign-key reference.
      if (!Scenario.defaultScenarios.any((s) => s.id == report.scenario.id)) {
        final existing = await client!
            .from('scenarios')
            .select('id')
            .eq('id', report.scenario.id)
            .maybeSingle();
        if (existing == null) {
          await client!.from('scenarios').insert({
            'id': report.scenario.id,
            'created_by': userId,
            'is_custom': true,
            'title': report.scenario.title,
            'subtitle': report.scenario.subtitle,
            'category': report.scenario.category,
            'difficulty': report.scenario.difficulty.name,
            'persona_id': report.scenario.persona.id,
            'context_brief': report.scenario.contextBrief,
            'user_objectives': report.scenario.userObjectives,
            'trap_phrases_to_avoid': report.scenario.trapPhrasesToAvoid,
          });
        }
      }

      // 1. Insert the session report. Call media is never stored.
      final sessionRow = await client!
          .from('session_attempts')
          .insert({
            'user_id': userId,
            'scenario_id': report.scenario.id,
            'duration_seconds': report.totalDuration.inSeconds,
            'overall_score': report.overallScore,
            'clarity_score': report.clarityScore,
            'boundary_score': report.boundaryFirmnessScore,
            'composure_score': report.presenceComposureScore,
            'empathy_score': report.empathyScore,
            'executive_tier': report.executiveTier,
            'analysis': {
              'overallScore': report.overallScore,
              'executiveTier': report.executiveTier,
              'executiveSummary': report.aiExecutiveSummary,
              'presenceNotes': report.videoPresenceNotes,
              'isAiGenerated': report.isAiGenerated,
              'blueprint': report.actionableBlueprint
                  .map(
                    (a) => {
                      'focusArea': a.focusArea,
                      'originalPhrasing': a.originalPhrasing,
                      'recommendedPhrasing': a.recommendedPhrasing,
                      'strategicRationale': a.strategicRationale,
                    },
                  )
                  .toList(),
              'keyMoments': report.keyMoments
                  .map(
                    (m) => {
                      'timestamp': m.formattedTimestamp,
                      'isPositive': m.isPositive,
                      'categoryTag': m.categoryTag,
                      'excerpt': m.excerpt,
                      'coachFeedback': m.coachFeedback,
                    },
                  )
                  .toList(),
              'speechMetrics': {
                'averageWpm': report.speechMetrics.averageWpm,
                'fillerCount': report.speechMetrics.fillerCount,
                'hedgingCount': report.speechMetrics.hedgingCount,
                'talkRatio': report.speechMetrics.talkRatio,
                'wordsSpoken': report.speechMetrics.wordsSpoken,
              },
              'visionMetrics': {
                'eyeContact': report.visionMetrics.eyeContactStability,
                'composure': report.visionMetrics.composureScore,
              },
            },
            'report': {
              'title': report.scenario.title,
              'scenarioId': report.scenario.id,
              'durationSeconds': report.totalDuration.inSeconds,
              'completedAt': DateTime.now().toIso8601String(),
            },
          })
          .select('id')
          .single();

      final sessionId = sessionRow['id'] as String;

      // 2. Insert turn transcripts
      if (report.transcript.isNotEmpty) {
        final transcriptRows = report.transcript.asMap().entries.map((entry) {
          final idx = entry.key;
          final turn = entry.value;
          return {
            'session_id': sessionId,
            'turn_index': idx,
            'speaker': turn.speaker.name,
            'speaker_name': turn.speakerName,
            'text': turn.text,
            'timestamp_ms': turn.timestamp.inMilliseconds,
            'tone_tag': turn.isStrongBoundary
                ? 'Firm Boundary'
                : (turn.hasHedging ? 'Hedging' : 'Clear'),
            'is_strong_boundary': turn.isStrongBoundary,
            'has_hedging': turn.hasHedging,
          };
        }).toList();

        await client!.from('transcripts').insert(transcriptRows);
      }

      debugPrint(
        '[SupabaseService] Session saved to PostgreSQL! ID: $sessionId',
      );
      return sessionId;
    } catch (e) {
      debugPrint('[SupabaseService] Failed to persist session attempt: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchUserSessionHistory() async {
    if (!_isInitialized || client == null) {
      return [];
    }

    try {
      final userId = client!.auth.currentUser?.id;
      if (userId == null) return [];

      final rows = await client!
          .from('session_attempts')
          .select('*, scenarios(title)')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      debugPrint('[SupabaseService] Error loading history: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> fetchSessionDetail(String sessionId) async {
    if (!_isInitialized || client == null) return null;
    try {
      final session = await client!
          .from('session_attempts')
          .select('*, scenarios(*)')
          .eq('id', sessionId)
          .maybeSingle();
      if (session == null) return null;

      final turns = await client!
          .from('transcripts')
          .select()
          .eq('session_id', sessionId)
          .order('turn_index');

      return {...session, 'transcript': turns};
    } catch (e) {
      debugPrint('[SupabaseService] Error fetching session detail: $e');
      return null;
    }
  }

}
