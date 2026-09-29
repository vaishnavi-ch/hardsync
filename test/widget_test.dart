import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hardsync/config/env_config.dart';
import 'package:hardsync/main.dart';
import 'package:hardsync/models/persona.dart';
import 'package:hardsync/models/scenario.dart';
import 'package:hardsync/models/subscription_tier.dart';
import 'package:hardsync/models/telemetry.dart';
import 'package:hardsync/models/user_persona.dart';
import 'package:hardsync/providers/subscription_provider.dart';
import 'package:hardsync/services/debrief_generator_service.dart';
import 'package:hardsync/services/supabase_service.dart';
import 'package:hardsync/services/telemetry_engine.dart';
import 'package:hardsync/screens/sign_in_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('new account sees onboarding before authentication', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(414, 896);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: AppLaunchGate()));
    await tester.pumpAndSettle();

    expect(find.text('Have Better\nConversations'), findsOneWidget);
    await tester.tap(find.textContaining('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Learn Your Way'), findsOneWidget);
    await tester.tap(find.textContaining('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Grow With Confidence'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(find.text('HardSync'), findsOneWidget);
    expect(find.text('Continue with Email'), findsOneWidget);
  });

  testWidgets('authentication screens navigate through login and reset', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: SignInScreen()));
    await tester.pumpAndSettle();
    expect(find.text('HardSync'), findsOneWidget);

    await tester.tap(find.text('Continue with Email'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back!'), findsOneWidget);

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(find.text('Reset your password'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Telemetry engine detects filler words and hedging', () {
    final engine = TelemetryEngine();
    engine.startSimulation(initialDefensiveness: 65);

    final result = engine.processUserUtterance(
      "I'm sorry to bother you, but I just feel like maybe we should discuss this um Friday.",
      const Duration(seconds: 4),
    );

    expect(result['hasHedging'], isTrue);
    expect(engine.speechMetrics.fillerCount, greaterThan(0));
    // Hedging should escalate avatar defensiveness
    expect(engine.avatarDefensiveness, greaterThan(65));
  });

  test('Telemetry engine rewards firm boundary phrasing', () {
    final engine = TelemetryEngine();
    engine.startSimulation(initialDefensiveness: 70);

    final result = engine.processUserUtterance(
      "We committed to the client release, and the deadline remains Friday.",
      const Duration(seconds: 3),
    );

    expect(result['hasStrongBoundary'], isTrue);
    // Firm boundary should lower avatar defensiveness
    expect(engine.avatarDefensiveness, lessThan(70));
  });

  test(
    'Scenario catalog includes the core personas and expanded scenarios',
    () {
      final scenarios = Scenario.defaultScenarios;
      expect(scenarios.length, greaterThanOrEqualTo(4));
      expect(scenarios.any((s) => s.persona.name.contains('Alex')), isTrue);
      expect(scenarios.any((s) => s.persona.name.contains('Jordan')), isTrue);
      expect(scenarios.any((s) => s.persona.name.contains('Marcus')), isTrue);
      expect(scenarios.any((s) => s.persona.name.contains('Priya')), isTrue);
    },
  );

  test('EnvConfig has Supabase cloud URL and publishable key configured', () {
    expect(EnvConfig.isSupabaseConfigured, isTrue);
    expect(
      EnvConfig.supabaseUrl,
      equals('https://reqwhdhkpazfvvefvsnv.supabase.co'),
    );
    expect(EnvConfig.supabaseAnonKey.startsWith('sb_publishable_'), isTrue);
  });

  test('Demo sign-in cannot authenticate a user', () async {
    final service = SupabaseService.instance;
    await expectLater(service.signInAsDemo(), throwsStateError);
    expect(service.isAuthenticated, isFalse);
    expect(service.currentUserId, isNull);
  });

  test(
    'DebriefGeneratorService generates dynamic debrief from actual transcript turns',
    () async {
      final generator = DebriefGeneratorService();
      final scenario = Scenario.defaultScenarios.first;
      final transcript = [
        const DialogueTurn(
          id: 'turn-1',
          speaker: DialogueSpeaker.avatar,
          speakerName: 'Alex Bennett',
          text: "I really don't think we need to cut the scope on this.",
          timestamp: Duration(seconds: 4),
          tone: ConversationalTone.defensive,
        ),
        const DialogueTurn(
          id: 'turn-2',
          speaker: DialogueSpeaker.user,
          speakerName: 'You',
          text:
              "I hear your concern, but the client deadline is non-negotiable for Friday.",
          timestamp: Duration(seconds: 10),
          tone: ConversationalTone.assertive,
          isStrongBoundary: true,
        ),
      ];

      final report = await generator.generateLiveReport(
        scenario: scenario,
        sessionDuration: const Duration(seconds: 15),
        transcript: transcript,
        speechMetrics: const SpeechMetrics(
          averageWpm: 132.0,
          fillerCount: 1,
          hedgingCount: 0,
          talkTimeSeconds: 7,
          listenTimeSeconds: 8,
        ),
        visionMetrics: const VisionMetrics(
          eyeContactStability: 0.91,
          composureScore: 0.85,
        ),
        finalDefensiveness: 40,
      );

      expect(report.totalDuration, equals(const Duration(seconds: 15)));
      expect(report.overallScore, 0);
      expect(report.executiveTier, 'Not scored');
      expect(report.keyMoments.isNotEmpty, isTrue);
      expect(
        report.keyMoments.any((m) => m.excerpt.contains('client deadline')),
        isTrue,
      );
      expect(report.actionableBlueprint, isEmpty);
      expect(report.aiExecutiveSummary, isNotNull);
      expect(report.videoPresenceNotes, isNotNull);
    },
  );

  test('SubscriptionTier gates video calls to Ultra only', () {
    // Free: text simulator only, no video calls, no face analysis
    expect(SubscriptionTier.free.canUseVideoCalls, isFalse);
    expect(SubscriptionTier.free.canUseLiveFaceAnalysis, isFalse);
    expect(SubscriptionTier.free.badgeLabel, equals('FREE'));

    // Ultra: live video calls and face analysis
    expect(SubscriptionTier.ultra.canUseVideoCalls, isTrue);
    expect(SubscriptionTier.ultra.canUseLiveFaceAnalysis, isTrue);
    expect(SubscriptionTier.ultra.badgeLabel, equals('ULTRA'));
  });

  test('UserPersona catalog provides 5 executive leadership roles', () {
    final personas = UserPersona.defaultPersonas;
    expect(personas.length, equals(5));

    final engineeringLead = personas.firstWhere((p) => p.id == 'eng_lead');
    expect(engineeringLead.title, contains('Engineering Team Lead'));
    expect(engineeringLead.coreStakes.isNotEmpty, isTrue);

    final founder = personas.firstWhere((p) => p.id == 'startup_founder');
    expect(founder.title, contains('Startup Founder'));
    expect(founder.executiveStandard.isNotEmpty, isTrue);
  });

  test('AI counterparts use distinct dedicated avatar portraits', () {
    final personas = Persona.defaultPersonas;
    final avatarAssets = personas.map((persona) => persona.avatarAsset).toSet();

    expect(avatarAssets.length, personas.length);
    for (final asset in avatarAssets) {
      expect(asset, startsWith('assets/avatars/split/flutter_256/'));
      expect(asset, endsWith('.png'));
    }
  });

  test('Local tier changes cannot unlock paid features', () async {
    SharedPreferences.setMockInitialValues({
      'hardsync_subscription_tier': 'ultra',
    });
    final provider = SubscriptionProvider();
    await provider.setTier(SubscriptionTier.ultra);
    expect(provider.currentTier, SubscriptionTier.free);
    expect(provider.canUseVideoCalls, isFalse);
    provider.dispose();
  });
}
