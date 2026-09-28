import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profile_screen.dart';
import 'home_screen.dart';
import 'scenario_hub_screen.dart';
import 'session_replay_screen.dart';
import '../theme/hardsync_theme.dart';

class AppShell extends StatefulWidget {
  final int initialIndex;

  const AppShell({super.key, this.initialIndex = 0});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _currentIndex;

  late final List<Widget?> _screens;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _screens = List<Widget?>.filled(4, null);
    _screens[_currentIndex] = _createScreen(_currentIndex);
  }

  Widget _createScreen(int index) => switch (index) {
    0 => HomeScreen(onOpenPractice: () => _selectTab(1)),
    1 => const ScenarioHubScreen(isEmbedded: true),
    2 => const SessionReplayScreen(),
    3 => const ProfileScreen(),
    _ => const SizedBox.shrink(),
  };

  void _selectTab(int index) {
    setState(() {
      _currentIndex = index;
      _screens[index] ??= _createScreen(index);
    });
  }

  List<Widget> get _loadedScreens => List<Widget>.generate(
    _screens.length,
    (index) => _screens[index] ?? const SizedBox.shrink(),
    growable: false,
  );

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useNavigationRail = constraints.maxWidth >= 720;
        final extendNavigationRail = constraints.maxWidth >= 1180;

        if (!useNavigationRail) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8F6FC),
            body: IndexedStack(index: _currentIndex, children: _loadedScreens),
            bottomNavigationBar: _buildBottomNav(),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8F6FC),
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
            colors: [HardSyncColors.cream, HardSyncColors.cream],
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  _buildNavigationRail(extended: extendNavigationRail),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: HardSyncColors.lilacBorder.withValues(alpha: .7),
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1120),
                        child: IndexedStack(
                          index: _currentIndex,
                          children: _loadedScreens,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavigationRail({required bool extended}) {
    const icons = [
      CupertinoIcons.house,
      CupertinoIcons.mic,
      CupertinoIcons.clock,
      CupertinoIcons.person,
    ];
    const selectedIcons = [
      CupertinoIcons.house_fill,
      CupertinoIcons.mic_fill,
      CupertinoIcons.clock_fill,
      CupertinoIcons.person_fill,
    ];
    const labels = ['Home', 'Practice', 'History', 'You'];

    return NavigationRail(
      extended: extended,
      minWidth: 84,
      minExtendedWidth: 196,
      groupAlignment: -.72,
      backgroundColor: HardSyncColors.surface.withValues(alpha: .94),
      selectedIndex: _currentIndex,
      onDestinationSelected: _selectTab,
      useIndicator: true,
      indicatorColor: HardSyncColors.lilacMist,
      leading: Padding(
        padding: const EdgeInsets.fromLTRB(12, 18, 12, 28),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: HardSyncColors.violet,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: HardSyncColors.violet.withValues(alpha: .22),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Icon(
            CupertinoIcons.bubble_left_bubble_right_fill,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
      selectedIconTheme: const IconThemeData(
        color: HardSyncColors.violet,
        size: 25,
      ),
      unselectedIconTheme: const IconThemeData(
        color: HardSyncColors.inkMuted,
        size: 23,
      ),
      selectedLabelTextStyle: GoogleFonts.plusJakartaSans(
        color: HardSyncColors.violet,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelTextStyle: GoogleFonts.plusJakartaSans(
        color: HardSyncColors.inkMuted,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      destinations: List.generate(
        labels.length,
        (index) => NavigationRailDestination(
          icon: Icon(icons[index]),
          selectedIcon: Icon(selectedIcons[index]),
          label: Text(labels[index]),
          padding: const EdgeInsets.symmetric(vertical: 5),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: HardSyncColors.surface,
        border: Border(
          top: BorderSide(
            color: HardSyncColors.lilacBorder.withValues(alpha: 0.72),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: HardSyncColors.violet.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: CupertinoIcons.house,
                selectedIcon: CupertinoIcons.house_fill,
                label: 'Home',
              ),
              _buildNavItem(
                index: 1,
                icon: CupertinoIcons.mic,
                selectedIcon: CupertinoIcons.mic_fill,
                label: 'Practice',
                prominent: true,
              ),
              _buildNavItem(
                index: 2,
                icon: CupertinoIcons.clock,
                selectedIcon: CupertinoIcons.clock_fill,
                label: 'History',
              ),
              _buildNavItem(
                index: 3,
                icon: CupertinoIcons.person,
                selectedIcon: CupertinoIcons.person_fill,
                label: 'You',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    bool prominent = false,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected
        ? const Color(0xFF7352DD)
        : const Color(0xFF666A80);

    return Expanded(
      child: InkWell(
        onTap: () => _selectTab(index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: prominent && isSelected ? 43 : 34,
                height: prominent && isSelected ? 43 : 34,
                decoration: BoxDecoration(
                  color: isSelected
                      ? HardSyncColors.lilacMist
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  boxShadow: prominent && isSelected
                      ? [
                          BoxShadow(
                            color: HardSyncColors.violet.withValues(alpha: .2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Icon(
                  isSelected ? selectedIcon : icon,
                  size: prominent ? 25 : 22,
                  color: color,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
