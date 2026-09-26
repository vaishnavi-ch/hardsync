import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/env_config.dart';
import 'providers/settings_provider.dart';
import 'providers/simulation_provider.dart';
import 'providers/subscription_provider.dart';
import 'screens/app_shell.dart';
import 'screens/onboarding_screen.dart';
import 'screens/sign_in_screen.dart';
import 'services/revenuecat_service.dart';
import 'services/supabase_service.dart';
import 'theme/hardsync_assets.dart';
import 'theme/hardsync_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsBinding.instance.ensureSemantics();
  runApp(const HardSyncApp());
}

class HardSyncApp extends StatefulWidget {
  const HardSyncApp({super.key});

  @override
  State<HardSyncApp> createState() => _HardSyncAppState();
}

class _HardSyncAppState extends State<HardSyncApp> {
  late final Future<void> _coreReady = _initializeCore();

  Future<void> _initializeCore() async {
    final splashStarted = DateTime.now();
    // Supabase restores the persisted login locally and is the only service
    // required before deciding which launch screen to show.
    await SupabaseService.instance.init();

    final splashRemaining =
        const Duration(milliseconds: 1100) -
        DateTime.now().difference(splashStarted);
    if (splashRemaining > Duration.zero) {
      await Future<void>.delayed(splashRemaining);
    }

    SupabaseService.instance.addListener(_syncRevenueCatIdentity);

    // Runtime configuration and billing are warmed after the first frame.
    // Neither should hold the entire application behind a network request.
    unawaited(_initializeOptionalServices());
  }

  Future<void> _initializeOptionalServices() async {
    await EnvConfig.init();
    await RevenueCatService.instance.init(
      appUserId: SupabaseService.instance.currentUserId,
    );
  }

  void _syncRevenueCatIdentity() {
    unawaited(
      RevenueCatService.instance.identify(
        SupabaseService.instance.currentUserId,
      ),
    );
  }

  @override
  void dispose() {
    SupabaseService.instance.removeListener(_syncRevenueCatIdentity);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => SimulationProvider()),
      ],
      child: MaterialApp(
        title: 'HardSync — Leadership Flight Simulator',
        debugShowCheckedModeBanner: false,
        theme: HardSyncTheme.lightTheme,
        home: FutureBuilder<void>(
          future: _coreReady,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const _LaunchScreen();
            }
            return const AppLaunchGate();
          },
        ),
      ),
    );
  }
}

class _LaunchScreen extends StatefulWidget {
  const _LaunchScreen();

  @override
  State<_LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<_LaunchScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HardSyncColors.cream,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _motion,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, -8 * _motion.value),
                child: Transform.rotate(
                  angle: (_motion.value - .5) * .07,
                  child: child,
                ),
              ),
              child: Container(
                width: 208,
                height: 208,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: HardSyncColors.lilacMist,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: HardSyncColors.violet.withValues(alpha: .12),
                      blurRadius: 36,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: const AppIllustration(
                  HardSyncAssets.illusCoachThinking,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text('HardSync', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 14),
            const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}

class AppLaunchGate extends StatefulWidget {
  const AppLaunchGate({super.key});

  @override
  State<AppLaunchGate> createState() => _AppLaunchGateState();
}

class _AppLaunchGateState extends State<AppLaunchGate> {
  bool _hasSeenOnboarding = false;
  bool _loadingOnboardingState = true;

  @override
  void initState() {
    super.initState();
    SupabaseService.instance.addListener(_authChanged);
    _loadOnboardingState();
  }

  Future<void> _completeOnboarding() async {
    if (mounted) setState(() => _hasSeenOnboarding = true);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('has_seen_onboarding', true);
  }

  Future<void> _loadOnboardingState() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _hasSeenOnboarding = preferences.getBool('has_seen_onboarding') ?? false;
      _loadingOnboardingState = false;
    });
  }

  void _authChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    SupabaseService.instance.removeListener(_authChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (SupabaseService.instance.isAuthenticated) {
      return const AppShell();
    }
    if (_loadingOnboardingState) {
      return const _LaunchScreen();
    }
    if (!_hasSeenOnboarding) {
      return OnboardingScreen(onComplete: _completeOnboarding);
    }
    return const SignInScreen();
  }
}
