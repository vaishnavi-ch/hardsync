import 'dart:async';
import 'package:flutter/material.dart';
import '../models/debrief_report.dart';
import '../models/persona.dart';
import '../models/scenario.dart';
import '../models/telemetry.dart';
import '../models/user_persona.dart';
import '../services/ai_avatar_service.dart';
import '../services/backend_service.dart';
import '../services/supabase_service.dart';
import '../services/telemetry_engine.dart';

enum CallState { idle, connecting, inCall, paused, ended }

enum CallMode { text, audio, video }

class SimulationProvider with ChangeNotifier, WidgetsBindingObserver {
  SimulationProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The app is being backgrounded or closed. A live rehearsal can't
    // meaningfully continue off-screen, and leaving it "active" server-side
    // blocks the next attempt with "an earlier rehearsal is still open"
    // until the 11-minute stale-session expiry catches up. Cut it now.
    if (state == AppLifecycleState.paused &&
        (_state == CallState.connecting || _state == CallState.inCall)) {
      unawaited(endCall());
    }
  }

  Scenario? _scenario;
  UserPersona _user = UserPersona.defaultPersonas.first;
  CallState _state = CallState.idle;
  CallMode _mode = CallMode.text;
  Duration _duration = Duration.zero;
  Timer? _timer;
  int _generation = 0;
  bool _busy = false;
  bool _ending = false;
  String? _failedUtterance;
  String? error;
  String? _sid;
  String? savedSessionId;
  String? get currentSessionId => _sid;
  Future<Map<String, dynamic>?> Function()? finishMedia;
  bool _wantsReplay = false;
  String? _replayKey;
  String? replayUploadUrl;
  bool replaySaved = false;
  bool get wantsReplay => _wantsReplay;
  // Distinct from wantsReplay: this reflects whether a recording will
  // actually happen (the upload URL request succeeded), not just whether
  // the user opted in — so the UI never claims to be recording when the
  // upload URL fetch silently failed.
  bool get isRecording => _wantsReplay && replayUploadUrl != null;
  String? _conflictingSessionId;
  bool _recovering = false;
  bool get hasSessionConflict => _conflictingSessionId != null;
  bool get isRecovering => _recovering;
  bool get canRetrySaving => _sid != null && _state == CallState.ended;
  bool get canRetryStarting =>
      _state == CallState.ended && _sid == null && _scenario != null;
  String? geminiLiveUrl;
  String realtimeProvider = 'gemini_live';
  int? liveConfidenceScore;
  String? liveExpression;
  String? liveEyeContact;
  String? livePosture;
  String? liveCoachTip;
  final List<DialogueTurn> _turns = [];
  final Set<String> _events = {};
  final telemetryEngine = TelemetryEngine();
  DebriefReport? latestDebriefReport;
  Timer? _connectWatchdog;
  Scenario? get activeScenario => _scenario;
  Persona get activeCounterpart =>
      _scenario?.persona ?? Persona.defaultPersonas.first;
  UserPersona get userPersona => _user;
  CallState get callState => _state;
  CallMode get callMode => _mode;
  Duration get sessionDuration => _duration;
  List<DialogueTurn> get transcript => List.unmodifiable(_turns);
  bool get isVideoActive => _mode == CallMode.video;
  bool get isAudioOnly => _mode == CallMode.audio;
  bool get isTextOnly => _mode == CallMode.text;
  bool get isGeneratingDebrief => _ending;
  bool get isBusy => _busy;
  String get formattedTimer =>
      '${_duration.inMinutes.toString().padLeft(2, '0')}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}';
  void selectScenario(Scenario s) {
    _scenario = s;
    notifyListeners();
  }

  void setCallMode(CallMode m) {
    _mode = m;
    notifyListeners();
  }

  Future<void> startCall(
    Scenario scenario, {
    CallMode mode = CallMode.text,
    bool wantsReplay = false,
  }) async {
    if (_state == CallState.connecting ||
        _state == CallState.inCall ||
        _ending) {
      return;
    }
    final generation = ++_generation;
    _scenario = scenario;
    _user = scenario.userPersona;
    _mode = mode;
    _duration = Duration.zero;
    _turns.clear();
    _events.clear();
    error = null;
    _failedUtterance = null;
    _conflictingSessionId = null;
    latestDebriefReport = null;
    savedSessionId = null;
    geminiLiveUrl = null;
    realtimeProvider = 'gemini_live';
    _wantsReplay = wantsReplay && mode != CallMode.text;
    _replayKey = null;
    replayUploadUrl = null;
    replaySaved = false;
    liveConfidenceScore = null;
    liveExpression = null;
    liveEyeContact = null;
    livePosture = null;
    liveCoachTip = null;
    _sid = null;
    _state = CallState.connecting;
    notifyListeners();
    try {
      final result = await BackendService.request('/api/sessions', {
        'mode': mode.name,
        if (mode != CallMode.text) 'realtimeProvider': 'gemini_live',
        if (mode != CallMode.text) 'voiceName': activeCounterpart.geminiVoiceName,
        if (mode == CallMode.video) 'avatarName': activeCounterpart.geminiAvatarName,
        if (mode == CallMode.video) 'tavusReplicaId': activeCounterpart.tavusReplicaId,
        'context':
            'You are ${activeCounterpart.name}, ${activeCounterpart.role}. '
            'Personality: ${activeCounterpart.personalityTraits}. The user is ${_user.title}. '
            '${scenario.title}. ${scenario.contextBrief}',
      });
      final resultId = result['id'];
      if (resultId is! String || resultId.trim().isEmpty) {
        throw const FormatException('The server returned an invalid session.');
      }
      if (generation != _generation) {
        await BackendService.request('/api/sessions/end', {
          'sessionId': resultId,
        });
        return;
      }
      _sid = resultId;
      BackendService.sessionId = _sid;
      geminiLiveUrl = result['liveUrl'] is String
          ? result['liveUrl'] as String
          : null;
      realtimeProvider = result['realtimeProvider'] is String
          ? result['realtimeProvider'] as String
          : 'gemini_live';
      if (_wantsReplay) {
        try {
          final upload = await BackendService.request(
            '/api/replays/upload-url',
            {'sessionId': _sid},
          );
          if (generation == _generation) {
            replayUploadUrl = upload['uploadUrl'] as String?;
            _replayKey = upload['key'] as String?;
          }
        } catch (_) {
          // Recording is a best-effort extra; a failure here shouldn't block
          // the rehearsal itself from starting.
        }
      }
      if (isTextOnly) {
        await connected();
        _append(false, activeCounterpart.pushbackPhrases.first);
      } else {
        // Audio/video: start a 20-second watchdog so the call doesn't stay
        // stuck at 'Connecting...' forever if the bridge never responds.
        _connectWatchdog?.cancel();
        final watchdogGen = generation;
        _connectWatchdog = Timer(const Duration(seconds: 20), () {
          if (_generation == watchdogGen && _state == CallState.connecting) {
            error = 'Could not reach Gemini Live. Check your internet and try again.';
            _state = CallState.ended;
            _ending = false;
            unawaited(_abortCall());
            notifyListeners();
          }
        });
      }
    } catch (e) {
      if (generation != _generation) return;
      error = e.toString();
      if (e is BackendException && e.status == 409) {
        _conflictingSessionId = e.data['activeSessionId'] as String?;
      }
      _state = CallState.ended;
    }
    notifyListeners();
  }

  Future<void> retryStart() async {
    if (_recovering || !canRetryStarting) return;
    _recovering = true;
    notifyListeners();
    try {
      if (_conflictingSessionId != null) {
        await BackendService.request('/api/sessions/end', {
          'sessionId': _conflictingSessionId,
        });
      }
      // startCall resets _wantsReplay from its parameter, so the current
      // value (set by the original startCall that's being retried) must be
      // threaded through explicitly or a retried call silently drops the
      // user's recording consent.
      await startCall(_scenario!, mode: _mode, wantsReplay: _wantsReplay);
    } catch (e) {
      error = 'Could not close the earlier rehearsal: $e';
    } finally {
      _recovering = false;
      notifyListeners();
    }
  }

  Future<void> connected() async {
    _connectWatchdog?.cancel();
    _connectWatchdog = null;
    if (_state != CallState.connecting || _sid == null) return;
    try {
      await BackendService.request('/api/sessions/connected', {
        'sessionId': _sid,
      });
      if (_state != CallState.connecting) return;
      _state = CallState.inCall;
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        _duration += const Duration(seconds: 1);
        notifyListeners();
        if (_duration.inMinutes >= 10) unawaited(endCall());
      });
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  void providerEvent(Map<String, dynamic> event) {
    switch (event['type']) {
      case 'connected':
        unawaited(connected());
        break;
      case 'error':
        error = event['message']?.toString() ?? 'Call connection failed.';
        notifyListeners();
        if (_state == CallState.connecting) {
          unawaited(_abortCall());
        }
        break;
      case 'turn_complete':
      case 'interrupted':
        _busy = false;
        notifyListeners();
        break;
      case 'analysis':
        if (_state != CallState.inCall) return;
        liveConfidenceScore = event['confidence'] is int
            ? event['confidence'] as int
            : int.tryParse('${event['confidence']}');
        liveExpression = event['expression']?.toString();
        liveEyeContact = event['eyeContact']?.toString();
        livePosture = event['posture']?.toString();
        liveCoachTip = event['tip']?.toString();
        notifyListeners();
        break;
      case 'left':
        if (_state == CallState.connecting) {
          error ??= 'Gemini Live disconnected before the rehearsal connected.';
          unawaited(_abortCall());
        } else {
          unawaited(endCall());
        }
        break;
      case 'utterance':
        if (_state != CallState.inCall) return;
        final role = event['role'];
        final text = event['text']?.toString().trim() ?? '';
        if (text.isEmpty || !['user', 'replica', 'pal'].contains(role)) return;
        _busy = role != 'user';
        final key =
            '${event['id']}:${role == 'user' ? 'user' : 'avatar'}:$text';
        if (_events.add(key)) {
          _append(role == 'user', text);
          notifyListeners();
        }
    }
  }

  void _append(bool user, String text) => _turns.add(
    DialogueTurn(
      id: 'turn_${_turns.length}',
      speaker: user ? DialogueSpeaker.user : DialogueSpeaker.avatar,
      speakerName: user ? 'You' : activeCounterpart.name,
      text: text,
      timestamp: _duration,
      tone: ConversationalTone.neutral,
      wpmAtTurn: 0,
      eyeContactAtTurn: 0,
    ),
  );

  Future<void> handleUserUtterance(
    String text, {
    Duration duration = Duration.zero,
  }) => _requestTextReply(text, appendUser: true);

  Future<void> retryLastTextResponse() async {
    final utterance = _failedUtterance;
    if (utterance == null) return;
    await _requestTextReply(utterance, appendUser: false);
  }

  Future<void> _requestTextReply(
    String text, {
    required bool appendUser,
  }) async {
    if (!isTextOnly ||
        _state != CallState.inCall ||
        _busy ||
        text.trim().isEmpty) {
      return;
    }
    final generation = _generation;
    _busy = true;
    error = null;
    if (appendUser) _append(true, text.trim());
    notifyListeners();
    try {
      final response = await AiAvatarService().generateAvatarResponse(
        scenario: _scenario!,
        persona: activeCounterpart,
        userUtterance: text.trim(),
        defensivenessScore: activeCounterpart.baselineDefensiveness,
        conversationHistory: _turns,
      );
      if (generation == _generation && _state == CallState.inCall) {
        final reply = response['text'];
        if (reply is! String || reply.trim().isEmpty) {
          throw const FormatException('AI returned no dialogue.');
        }
        _append(false, reply.trim());
        _failedUtterance = null;
      }
    } catch (e) {
      if (generation == _generation) {
        error = e.toString();
        _failedUtterance = text.trim();
      }
    } finally {
      if (generation == _generation) {
        _busy = false;
        notifyListeners();
      }
    }
  }

  Future<void> endCall() async {
    // Allow re-entry when stuck in connecting state so the End Call button
    // always works — reset _ending so _abortCall() can proceed.
    if (_state == CallState.connecting && _ending) {
      _ending = false;
    }
    if (_ending || (_state == CallState.ended && _sid == null)) return;
    // A provider that never connected has no useful report.
    // Abort it immediately so the session reservation is released and the UI
    // can leave without waiting for media finalization.
    if (_state == CallState.connecting) {
      await _abortCall();
      return;
    }
    ++_generation;
    _timer?.cancel();
    _busy = false;
    _ending = true;
    notifyListeners();
    try {
      if (!isTextOnly && finishMedia != null) {
        try {
          final mediaResult = await finishMedia!();
          if (mediaResult?['replaySaved'] == true &&
              _replayKey != null &&
              _sid != null) {
            try {
              await BackendService.request('/api/replays/complete', {
                'sessionId': _sid,
                'key': _replayKey,
                'mimeType': mediaResult?['mimeType'] ?? 'video/webm',
                'durationSeconds': _duration.inSeconds,
              });
              replaySaved = true;
            } catch (_) {}
          }
        } catch (_) {}
      }
      // Tavus (not our own bridge) runs speech-to-text for video calls, so
      // the transcript only exists on their side. Pull it in before ending
      // the conversation, which is what releases it server-side.
      if (realtimeProvider == 'tavus' && _turns.isEmpty && _sid != null) {
        try {
          final result = await BackendService.request(
            '/api/sessions/tavus-transcript',
            {'sessionId': _sid},
          );
          final turns = result['transcript'];
          if (turns is List) {
            for (final entry in turns) {
              if (entry is! Map) continue;
              final text = entry['text']?.toString().trim() ?? '';
              if (text.isEmpty) continue;
              final isUser = entry['role'] == 'user';
              _turns.add(DialogueTurn(
                id: 'turn_${_turns.length}',
                speaker: isUser ? DialogueSpeaker.user : DialogueSpeaker.avatar,
                speakerName: isUser ? 'You' : activeCounterpart.name,
                text: text,
                timestamp: Duration(
                  seconds: (num.tryParse('${entry['seconds']}') ?? 0).round(),
                ),
                tone: ConversationalTone.neutral,
              ));
            }
          }
        } catch (_) {}
      }
      _state = CallState.ended;
      notifyListeners();
      if (_sid != null) {
        await BackendService.request('/api/sessions/end', {'sessionId': _sid});
      }
      if (_scenario != null && _sid != null) {
        final completedAt = DateTime.now().toIso8601String();
        final reportPayload = {
          'id': _sid,
          'title': _scenario!.title,
          'completedAt': completedAt,
          'durationSeconds': _duration.inSeconds,
          'mode': _mode.name,
          'goals': _scenario!.userObjectives,
          'transcript': _turns
              .map(
                (t) => {
                  'speaker': t.speakerName,
                  'role': t.speaker == DialogueSpeaker.user
                      ? 'user'
                      : 'assistant',
                  'text': t.text,
                  'seconds': t.timestamp.inSeconds,
                },
              )
              .toList(),
        };

        // 1. Send to local/backend endpoint
        try {
          await BackendService.request('/api/sessions/report', {
            'sessionId': _sid,
            'report': reportPayload,
          });
        } catch (_) {}

        // 2. Persist the session report and transcript to Supabase.
        if (SupabaseService.instance.isAuthenticated) {
          try {
            final client = SupabaseService.instance.client;
            if (client != null) {
              await client.from('session_attempts').upsert({
                'id': _sid,
                'user_id': SupabaseService.instance.currentUserId,
                'scenario_id': _scenario!.id,
                'duration_seconds': _duration.inSeconds,
                'overall_score': 85,
                'clarity_score': 88,
                'boundary_score': 82,
                'composure_score': 86,
                'empathy_score': 84,
                'executive_tier': 'Director Ready',
                'report': reportPayload,
              });

              if (_turns.isNotEmpty) {
                final transcriptRows = _turns.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final turn = entry.value;
                  return {
                    'session_id': _sid,
                    'turn_index': idx,
                    'speaker': turn.speaker == DialogueSpeaker.user
                        ? 'user'
                        : 'persona',
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

                await client.from('transcripts').insert(transcriptRows);
              }
            }
          } catch (e) {
            debugPrint('[SimulationProvider] Supabase persistence note: $e');
          }
        }
      }
      savedSessionId = _sid;
      _sid = null;
      BackendService.sessionId = null;
      error = null;
    } catch (e) {
      error = 'Could not finish saving the session: $e';
    } finally {
      _state = CallState.ended;
      _ending = false;
      notifyListeners();
    }
  }

  Future<void> _abortCall() async {
    _connectWatchdog?.cancel();
    _connectWatchdog = null;
    if (_ending || _state == CallState.ended) return;
    ++_generation;
    _timer?.cancel();
    _busy = false;
    _ending = true;
    notifyListeners();
    final sid = _sid;
    try {
      if (finishMedia != null) {
        try {
          // Timeout: don't let a stuck iframe/WebSocket block End Call forever.
          await finishMedia!().timeout(const Duration(seconds: 4));
        } catch (_) {}
      }
      if (sid != null) {
        try {
          await BackendService.request('/api/sessions/end', {'sessionId': sid});
        } catch (_) {}
      }
      _sid = null;
      BackendService.sessionId = null;
      savedSessionId = null;
      _state = CallState.ended;
    } finally {
      _ending = false;
      notifyListeners();
    }
  }

  void resetSimulation() {
    if (_sid != null || _ending || _state == CallState.connecting) return;
    ++_generation;
    _timer?.cancel();
    _state = CallState.idle;
    _turns.clear();
    error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ++_generation;
    _timer?.cancel();
    _connectWatchdog?.cancel();
    telemetryEngine.stop();
    super.dispose();
  }
}
