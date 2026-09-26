import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/hardsync_assets.dart';
import '../theme/hardsync_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.onComplete});
  final VoidCallback? onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  int _currentPage = 0;

  static const _content = [
    (
      'Have Better\nConversations',
      'Build real-world communication skills with your AI practice partner.',
      HardSyncAssets.illusSafeRehearsalRoom,
    ),
    (
      'Learn Your Way',
      'Practice real conversations with HardSync and get clear tips you can use.',
      HardSyncAssets.illusCoachThinking,
    ),
    (
      'Grow With Confidence',
      'Practice, reflect, and build confidence for the conversations ahead.',
      HardSyncAssets.illusPracticeReflectImprove,
    ),
  ];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _finish() {
    final callback = widget.onComplete;
    if (callback != null) {
      callback();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _next() {
    if (_currentPage == _content.length - 1) {
      _finish();
      return;
    }
    _pages.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: HardSyncColors.cream,
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Skip'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pages,
                  itemCount: _content.length,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemBuilder: (context, index) {
                    final page = _content[index];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(28, 14, 28, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            page.$1,
                            style: GoogleFonts.plusJakartaSans(
                              color: HardSyncColors.ink,
                              fontSize: 35,
                              height: 1.12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            page.$2,
                            style: GoogleFonts.plusJakartaSans(
                              color: HardSyncColors.inkMuted,
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Expanded(
                            child: Center(
                              child: TweenAnimationBuilder<double>(
                                key: ValueKey(index),
                                tween: Tween(begin: .92, end: 1),
                                duration: const Duration(milliseconds: 420),
                                curve: Curves.easeOutBack,
                                builder: (context, value, child) => Transform.scale(
                                  scale: value,
                                  child: child,
                                ),
                                child: AppIllustration(
                                  page.$3,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 10, 28, 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _content.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          width: index == _currentPage ? 24 : 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: index == _currentPage
                                ? HardSyncColors.violet
                                : HardSyncColors.lilacBorder,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: HardSyncColors.ink,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                        ),
                        onPressed: _next,
                        child: Text(
                          _currentPage == _content.length - 1
                              ? 'Get Started'
                              : 'Next   ›',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
