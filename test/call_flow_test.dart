import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hardsync/models/scenario.dart';
import 'package:hardsync/models/telemetry.dart';
import 'package:hardsync/providers/simulation_provider.dart';
import 'package:hardsync/services/backend_service.dart';

void main() {
  final original = BackendService.transport;
  late SimulationProvider sim;
  late List<http.Request> requests;
  setUp(() {
    sim = SimulationProvider();
    requests = [];
    BackendService.baseUriOverride = Uri.parse('http://localhost');
    BackendService.transport = MockClient((r) async {
      requests.add(r);
      if (r.url.path == '/api/sessions') {
        return http.Response(
          jsonEncode({
            'id': 'session',
            'realtimeProvider': 'gemini_live',
            'liveUrl': 'wss://test.example/api/gemini-live?signature=signed',
          }),
          200,
        );
      }
      return http.Response('{}', 200);
    });
  });
  tearDown(() {
    sim.dispose();
    BackendService.transport = original;
    BackendService.sessionId = null;
    BackendService.baseUriOverride = null;
  });
  test(
    'Gemini video waits for connection and deduplicates alias events',
    () async {
      await sim.startCall(
        Scenario.defaultScenarios.first,
        mode: CallMode.video,
      );
      final startRequest = requests.singleWhere(
        (r) => r.url.path == '/api/sessions',
      );
      expect(jsonDecode(startRequest.body)['realtimeProvider'], 'gemini_live');
      expect(sim.geminiLiveUrl, startsWith('wss://test.example/'));
      expect(sim.callState, CallState.connecting);
      expect(sim.transcript, isEmpty);
      await sim.connected();
      expect(sim.callState, CallState.inCall);
      for (final role in ['pal', 'replica']) {
        sim.providerEvent({
          'type': 'utterance',
          'role': role,
          'text': 'Hello',
          'id': 'same-turn',
        });
      }
      expect(sim.transcript.length, 1);
      await sim.handleUserUtterance('Must not start a competing AI loop');
      expect(requests.where((r) => r.url.path == '/api/generate'), isEmpty);
      await sim.endCall();
      expect(sim.callState, CallState.ended);
      expect(
        requests.where((r) => r.url.path == '/api/sessions/report').length,
        1,
      );
    },
  );
  test(
    'late text responses cannot append after ending and prompts are not duplicated',
    () async {
      final pending = Completer<http.Response>();
      BackendService.transport = MockClient((r) async {
        requests.add(r);
        if (r.url.path == '/api/sessions') {
          return http.Response('{"id":"session"}', 200);
        }
        if (r.url.path == '/api/generate') return pending.future;
        return http.Response('{}', 200);
      });
      await sim.startCall(Scenario.defaultScenarios.first, mode: CallMode.text);
      final reply = sim.handleUserUtterance('Friday is firm.');
      await Future<void>.delayed(Duration.zero);
      await sim.handleUserUtterance('Concurrent turn');
      final req = requests.singleWhere((r) => r.url.path == '/api/generate');
      final contents = jsonDecode(req.body)['payload']['contents'] as List;
      expect(
        contents
            .where((c) => c['parts'][0]['text'] == 'Friday is firm.')
            .length,
        1,
      );
      expect(
        sim.transcript.where((t) => t.speaker == DialogueSpeaker.user).length,
        1,
      );
      await sim.endCall();
      pending.complete(
        http.Response(
          '{"candidates":[{"content":{"parts":[{"text":"Late answer"}]}}]}',
          200,
        ),
      );
      await reply;
      expect(sim.transcript.any((t) => t.text == 'Late answer'), isFalse);
      expect(sim.isBusy, isFalse);
    },
  );
  test(
    'call end waits for recording finalization before saving its report',
    () async {
      final media = Completer<void>();
      await sim.startCall(
        Scenario.defaultScenarios.first,
        mode: CallMode.video,
      );
      await sim.connected();
      sim.finishMedia = () => media.future;
      final ending = sim.endCall();
      await Future<void>.delayed(Duration.zero);
      expect(sim.isGeneratingDebrief, isTrue);
      expect(sim.callState, CallState.inCall);
      expect(
        requests.where((r) => r.url.path == '/api/sessions/report'),
        isEmpty,
      );
      media.complete();
      await ending;
      expect(sim.savedSessionId, 'session');
      expect(sim.callState, CallState.ended);
      final report = jsonDecode(
        requests.singleWhere((r) => r.url.path == '/api/sessions/report').body,
      )['report'];
      expect(report['goals'], isNotEmpty);
    },
  );
  test('failed session creation never reports an active call', () async {
    BackendService.transport = MockClient(
      (_) async => http.Response('{"error":"Provider unavailable"}', 503),
    );
    await sim.startCall(Scenario.defaultScenarios.first, mode: CallMode.audio);
    expect(sim.callState, CallState.ended);
    expect(sim.error, contains('Provider unavailable'));
    expect(sim.geminiLiveUrl, isNull);
  });
  test(
    'ending a call that never connected aborts without saving a report',
    () async {
      await sim.startCall(
        Scenario.defaultScenarios.first,
        mode: CallMode.audio,
      );
      expect(sim.callState, CallState.connecting);
      await sim.endCall();
      expect(sim.callState, CallState.ended);
      expect(sim.savedSessionId, isNull);
      expect(BackendService.sessionId, isNull);
      expect(
        requests.where((r) => r.url.path == '/api/sessions/end').length,
        1,
      );
      expect(
        requests.where((r) => r.url.path == '/api/sessions/report'),
        isEmpty,
      );
    },
  );
  test(
    'session conflict can close the exact earlier call and retry without saving a phantom report',
    () async {
      var starts = 0;
      BackendService.transport = MockClient((r) async {
        requests.add(r);
        if (r.url.path == '/api/sessions') {
          starts++;
          if (starts == 1) {
            return http.Response(
              '{"error":"Earlier call is open","activeSessionId":"old-session"}',
              409,
            );
          }
          return http.Response(
            '{"id":"new-session","conversationUrl":"https://test.daily.co/new"}',
            200,
          );
        }
        return http.Response('{}', 200);
      });
      await sim.startCall(
        Scenario.defaultScenarios.first,
        mode: CallMode.audio,
      );
      expect(sim.hasSessionConflict, isTrue);
      expect(sim.canRetrySaving, isFalse);
      expect(sim.canRetryStarting, isTrue);
      await sim.retryStart();
      expect(sim.callState, CallState.connecting);
      expect(sim.callMode, CallMode.audio);
      expect(sim.error, isNull);
      final end = requests.singleWhere(
        (r) => r.url.path == '/api/sessions/end',
      );
      expect(jsonDecode(end.body)['sessionId'], 'old-session');
      expect(
        requests.where((r) => r.url.path == '/api/sessions/report'),
        isEmpty,
      );
    },
  );

  test(
    'failed recovery does not reserve another call or discard the conflict',
    () async {
      BackendService.transport = MockClient((r) async {
        requests.add(r);
        if (r.url.path == '/api/sessions') {
          return http.Response(
            '{"error":"Open call","activeSessionId":"old-session"}',
            409,
          );
        }
        return http.Response('{"error":"Provider unavailable"}', 502);
      });
      await sim.startCall(
        Scenario.defaultScenarios.first,
        mode: CallMode.video,
      );
      await sim.retryStart();
      expect(sim.hasSessionConflict, isTrue);
      expect(sim.isRecovering, isFalse);
      expect(sim.canRetrySaving, isFalse);
      expect(requests.where((r) => r.url.path == '/api/sessions').length, 1);
      expect(sim.error, contains('Could not close'));
    },
  );
}
