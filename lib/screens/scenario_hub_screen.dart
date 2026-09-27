import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/scenario.dart';
import '../theme/hardsync_assets.dart';
import '../theme/hardsync_theme.dart';
import 'custom_scenario_screen.dart';
import 'session_prep_screen.dart';
import 'settings_modal.dart';

class ScenarioHubScreen extends StatefulWidget {
  final bool isEmbedded;
  const ScenarioHubScreen({super.key, this.isEmbedded = false});

  @override
  State<ScenarioHubScreen> createState() => _ScenarioHubScreenState();
}

class _ScenarioHubScreenState extends State<ScenarioHubScreen> {
  String _selectedCategory = 'All';
  static const _categories = [
    'All',
    'Feedback',
    'Conflict',
    'Delegation',
    'Boundaries',
    'Leadership',
  ];

  @override
  Widget build(BuildContext context) {
    final scenarios = Scenario.defaultScenarios;
    final filtered = scenarios
        .where((item) => _matchesCategory(item, _selectedCategory))
        .toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: wide ? 1120 : 520),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                      sliver: SliverToBoxAdapter(child: _buildHeader(context)),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
                      sliver: SliverToBoxAdapter(
                        child: _buildHero(context, scenarios.first),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          'Choose a rehearsal',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(child: _buildFilters()),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 2),
                      sliver: SliverToBoxAdapter(
                        child: _buildCustomScenarioCard(context),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
                      sliver: SliverGrid.builder(
                        itemCount: filtered.length,
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 540,
                          mainAxisExtent: wide ? 220 : 154,
                          crossAxisSpacing: 14,
                        ),
                        itemBuilder: (context, index) =>
                            _buildScenarioCard(context, filtered[index], index),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  bool _matchesCategory(Scenario item, String selected) {
    if (selected == 'All') return true;
    final category = item.category.toLowerCase();
    return switch (selected) {
      'Feedback' => category.contains('feedback'),
      'Conflict' => category.contains('conflict') || category.contains('alignment') || category.contains('negotiat'),
      'Delegation' => category.contains('delegat'),
      'Boundaries' => category.contains('boundar') || category.contains('workload'),
      'Leadership' => category.contains('managing up') || category.contains('change') || category.contains('peer'),
      _ => false,
    };
  }

  Widget _buildCustomScenarioCard(BuildContext context) {
    return Material(
      color: HardSyncColors.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CustomScenarioScreen()),
        ),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          constraints: const BoxConstraints(minHeight: 124),
          padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: HardSyncColors.lilacBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 96,
                height: 104,
                decoration: BoxDecoration(
                  color: HardSyncColors.lilacMist,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const AppIllustration(
                  HardSyncAssets.illusConversationBlueprint,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: constraints.maxWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _eyebrow('BUILD YOUR OWN'),
                          const SizedBox(height: 4),
                          Text(
                            'Create a custom scenario',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.newsreader(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: HardSyncColors.ink,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Shape the situation, goal, and partner.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: HardSyncColors.inkMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Practice',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        Material(
          color: HardSyncColors.surface,
          shape: const CircleBorder(
            side: BorderSide(color: HardSyncColors.border),
          ),
          child: InkWell(
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const SettingsModal(),
            ),
            customBorder: const CircleBorder(),
            child: const SizedBox(
              width: 46,
              height: 46,
              child: Icon(
                Icons.tune_rounded,
                size: 21,
                color: HardSyncColors.ink,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHero(BuildContext context, Scenario scenario) {
    return Container(
      constraints: const BoxConstraints(minHeight: 172),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: HardSyncColors.lilacMist,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(17, 14, 4, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _eyebrow('TRY A QUICK PRACTICE'),
                  const SizedBox(height: 6),
                  Text(
                    scenario.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.newsreader(
                      fontSize: 21,
                      height: 1.02,
                      fontWeight: FontWeight.w700,
                      color: HardSyncColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rehearse a real 1:1 before it happens.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => _openScenario(context, scenario),
                    icon: const Icon(Icons.play_arrow_rounded, size: 17),
                    label: const Text('Start'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            width: 126,
            height: 158,
            child: AppIllustration(HardSyncAssets.illusSafeRehearsalRoom),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          return ChoiceChip(
            selected: category == _selectedCategory,
            showCheckmark: false,
            label: Text(category),
            onSelected: (_) => setState(() => _selectedCategory = category),
          );
        },
      ),
    );
  }

  Widget _buildScenarioCard(
    BuildContext context,
    Scenario scenario,
    int index,
  ) {
    final palette = _cardPalettes[index % _cardPalettes.length];
    return LayoutBuilder(
      builder: (context, constraints) {
        final largeArtwork = constraints.maxHeight >= 190;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: palette.$1,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              onTap: () => _openScenario(context, scenario),
              borderRadius: BorderRadius.circular(22),
              child: Container(
                height: largeArtwork ? 208 : 142,
                padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: palette.$2),
                ),
                child: Row(
                  children: [
                    Container(
                      width: largeArtwork ? 172 : 104,
                      height: largeArtwork ? 180 : 112,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .52),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: AppIllustration(
                        Scenario.illustrationFor(scenario.id),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            scenario.category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: HardSyncColors.inkMuted),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            scenario.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.newsreader(
                              fontSize: largeArtwork ? 23 : 20,
                              height: 1.05,
                              fontWeight: FontWeight.w700,
                              color: HardSyncColors.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            scenario.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _eyebrow(String label) => Text(
    label,
    style: GoogleFonts.plusJakartaSans(
      fontSize: 10,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.1,
      color: HardSyncColors.violet,
    ),
  );

  void _openScenario(BuildContext context, Scenario scenario) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SessionPrepScreen(scenario: scenario)),
    );
  }

  static const _cardPalettes = <(Color, Color)>[
    (Color(0xFFF1EDFF), Color(0xFFE2D8FF)),
    (Color(0xFFFFF2DC), Color(0xFFF8DFC0)),
    (Color(0xFFFFEDE6), Color(0xFFF6D8CC)),
    (Color(0xFFEDF4E8), Color(0xFFDCE8D4)),
  ];
}
