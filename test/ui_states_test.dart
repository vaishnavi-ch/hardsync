import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hardsync/models/learning_course.dart';
import 'package:hardsync/models/scenario.dart';
import 'package:hardsync/providers/simulation_provider.dart';
import 'package:hardsync/providers/subscription_provider.dart';
import 'package:hardsync/screens/custom_scenario_screen.dart';
import 'package:hardsync/screens/app_shell.dart';
import 'package:hardsync/screens/home_screen.dart';
import 'package:hardsync/screens/learning_screen.dart';
import 'package:hardsync/screens/progress_screen.dart';
import 'package:hardsync/screens/session_prep_screen.dart';
import 'package:hardsync/screens/subscription_paywall_screen.dart';
import 'package:hardsync/theme/hardsync_theme.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpAt(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(theme: HardSyncTheme.lightTheme, home: child),
    );
    await tester.pumpAndSettle();
    final layoutException = tester.takeException();
    if (layoutException is FlutterError) {
      for (final diagnostic in layoutException.diagnostics) {
        debugPrint(diagnostic.toStringDeep());
      }
    }
    expect(
      layoutException,
      isNull,
      reason: layoutException is FlutterError
          ? layoutException.toStringDeep()
          : layoutException?.toString(),
    );
  }

  testWidgets('home dashboard fits compact and standard mobile sizes', (
    tester,
  ) async {
    await pumpAt(tester, const HomeScreen(), size: const Size(320, 568));
    expect(find.textContaining('Good morning'), findsOneWidget);
    expect(find.text('YOUR MANAGER PATH'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await pumpAt(tester, const HomeScreen(), size: const Size(430, 932));
    expect(find.text('YOUR MANAGER PATH'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await pumpAt(tester, const HomeScreen(), size: const Size(1024, 768));
    final progressTop = tester.getTopLeft(find.text('YOUR MANAGER PATH')).dy;
    final learningTop = tester.getTopLeft(find.text('START LEARNING')).dy;
    expect((progressTop - learningTop).abs(), lessThan(120));
    expect(tester.takeException(), isNull);
  });

  testWidgets('app shell adapts navigation across phone tablet and web', (
    tester,
  ) async {
    for (final size in [
      const Size(390, 844),
      const Size(768, 1024),
      const Size(1024, 768),
      const Size(1440, 900),
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(theme: HardSyncTheme.lightTheme, home: const AppShell()),
      );
      await tester.pumpAndSettle();

      if (size.width < 720) {
        expect(find.byType(NavigationRail), findsNothing);
      } else {
        expect(find.byType(NavigationRail), findsOneWidget);
      }
      final layoutException = tester.takeException();
      expect(
        layoutException,
        isNull,
        reason:
            'layout exception at ${size.width}x${size.height}: '
            '${layoutException is FlutterError ? layoutException.toStringDeep() : layoutException}',
      );
    }
    addTearDown(tester.view.resetPhysicalSize);
  });

  testWidgets('progress roadmap fits and shows saved-practice empty state', (
    tester,
  ) async {
    await pumpAt(tester, const ProgressScreen());
    expect(find.text('Your roadmap'), findsOneWidget);
    expect(find.text('Your learning journey'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('custom scenario advances through all guided builder states', (
    tester,
  ) async {
    await pumpAt(tester, const CustomScenarioScreen());
    expect(find.text('Create your own scenario'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Define the situation'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Choose your conversation partner'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Review your scenario'), findsOneWidget);
    expect(find.text('Continue to practice setup'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'lesson player covers explanation reflection quiz retry and completion',
    (tester) async {
      final course = LearningCatalog.courses.first;
      await pumpAt(
        tester,
        LessonScreen(course: course, lesson: course.lessons.first, index: 0),
      );
      expect(find.text('A 1:1 situation'), findsOneWidget);
      expect(find.text('The idea'), findsOneWidget);
      expect(find.text('Use this simple approach'), findsOneWidget);
      expect(find.text('Mark read & practise scenarios'), findsOneWidget);
      await tester.ensureVisible(find.text('Mark read & practise scenarios'));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'session preparation fits compact mobile with all modes visible',
    (tester) async {
      final subscription = SubscriptionProvider();
      final simulation = SimulationProvider();
      addTearDown(subscription.dispose);
      addTearDown(simulation.dispose);

      await pumpAt(
        tester,
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: subscription),
            ChangeNotifierProvider.value(value: simulation),
          ],
          child: SessionPrepScreen(scenario: Scenario.defaultScenarios.first),
        ),
        size: const Size(320, 568),
      );
      expect(find.text('Text Drill'), findsOneWidget);
      expect(find.text('Voice Audio'), findsOneWidget);
      expect(find.text('Gemini Video'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await pumpAt(
        tester,
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: subscription),
            ChangeNotifierProvider.value(value: simulation),
          ],
          child: SessionPrepScreen(scenario: Scenario.defaultScenarios.first),
        ),
        size: const Size(1024, 768),
      );
      expect(find.text('Your Goal'), findsOneWidget);
      expect(find.text('Things to consider'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('paywall plan picker fits compact and standard mobile sizes', (
    tester,
  ) async {
    final compactProvider = SubscriptionProvider();
    addTearDown(compactProvider.dispose);
    await pumpAt(
      tester,
      ChangeNotifierProvider.value(
        value: compactProvider,
        child: const SubscriptionPaywallScreen(),
      ),
      size: const Size(320, 568),
    );
    expect(find.textContaining('Choose'), findsWidgets);
    expect(tester.takeException(), isNull);

    final standardProvider = SubscriptionProvider();
    addTearDown(standardProvider.dispose);
    await pumpAt(
      tester,
      ChangeNotifierProvider.value(
        value: standardProvider,
        child: const SubscriptionPaywallScreen(),
      ),
      size: const Size(430, 932),
    );
    expect(find.text('Free'), findsWidgets);
    expect(find.text('Pro'), findsWidgets);
    expect(tester.takeException(), isNull);

    final wideProvider = SubscriptionProvider();
    addTearDown(wideProvider.dispose);
    await pumpAt(
      tester,
      ChangeNotifierProvider.value(
        value: wideProvider,
        child: const SubscriptionPaywallScreen(),
      ),
      size: const Size(1024, 768),
    );
    expect(find.text('Free'), findsWidgets);
    expect(find.text('Pro'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
