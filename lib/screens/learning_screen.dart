import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/learning_course.dart';
import '../models/scenario.dart';
import '../theme/hardsync_assets.dart';
import '../theme/hardsync_theme.dart';
import 'session_prep_screen.dart';

const _learningTints = [
  HardSyncColors.lilacMist,
  HardSyncColors.apricotMist,
  HardSyncColors.oliveMist,
  HardSyncColors.coralMist,
  HardSyncColors.sunMist,
];

Color _learningTint(String seed) =>
    _learningTints[seed.codeUnits.fold<int>(0, (sum, item) => sum + item) %
        _learningTints.length];

List<LearningCourse> _roadmapCourses(LearningPath path) =>
    path.courseIds.map(LearningCatalog.byId).toList();

Iterable<(LearningCourse, int, LearningLesson)> _roadmapBytes(
  LearningPath path,
) sync* {
  for (final course in _roadmapCourses(path)) {
    for (final entry in course.lessons.indexed) {
      yield (course, entry.$1, entry.$2);
    }
  }
}

class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  Set<String> _completed = {};
  String _selectedTopic = 'All';
  static const _topics = ['All', 'People', 'Communication', 'Leadership'];

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(
        () => _completed =
            prefs.getStringList('learning_progress')?.toSet() ?? {},
      );
    }
  }

  double _courseProgress(LearningCourse course) {
    final done = course.lessons.indexed
        .where((e) => _completed.contains('${course.id}:${e.$1}'))
        .length;
    return done / course.lessons.length;
  }

  Future<void> _openQuickByte(LearningCourse course) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CourseDetailScreen(course: course)),
    );
    if (mounted) _loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HardSyncColors.cream,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: wide ? 1120 : 560),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                      sliver: SliverToBoxAdapter(
                        child: _LearningHeader(wide: wide),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          'Explore topics',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(child: _topicFilters()),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                      sliver: SliverList.separated(
                        itemCount: _visibleCourses.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 11),
                        itemBuilder: (context, index) {
                          final course = _visibleCourses[index];
                          final done = course.lessons.indexed
                              .where(
                                (entry) => _completed.contains(
                                  '${course.id}:${entry.$1}',
                                ),
                              )
                              .length;
                          return _BrowseCourseCard(
                            course: course,
                            completedBytes: done,
                            onTap: () => _openQuickByte(course),
                          );
                        },
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

  List<LearningCourse> get _visibleCourses {
    if (_selectedTopic == 'All') return LearningCatalog.courses;
    const topics = {
      'People': {'coaching', 'feedback', 'performance', 'listening'},
      'Communication': {'clarity', 'listening', 'feedback', 'boundaries'},
      'Leadership': {'manage_up', 'presence', 'conflict', 'negotiation'},
    };
    final ids = topics[_selectedTopic] ?? <String>{};
    return LearningCatalog.courses
        .where((course) => ids.contains(course.id))
        .toList();
  }

  Widget _topicFilters() => SizedBox(
    height: 43,
    child: ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      scrollDirection: Axis.horizontal,
      itemCount: _topics.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final topic = _topics[index];
        final selected = topic == _selectedTopic;
        return ChoiceChip(
          selected: selected,
          showCheckmark: false,
          label: Text(topic),
          onSelected: (_) => setState(() => _selectedTopic = topic),
          backgroundColor: Colors.white,
          selectedColor: HardSyncColors.violet,
          side: BorderSide(
            color: selected ? HardSyncColors.violet : HardSyncColors.border,
          ),
          labelStyle: TextStyle(
            color: selected ? Colors.white : HardSyncColors.inkMuted,
            fontWeight: FontWeight.w700,
          ),
        );
      },
    ),
  );
}

class _LearningHeader extends StatelessWidget {
  final bool wide;
  const _LearningHeader({required this.wide});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(3, 8, 2, 12),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Learn', style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 3),
              Text(
                'Small lessons for the real moments managers face.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        SizedBox(
          width: 82,
          height: 72,
          child: AppIllustration(HardSyncAssets.illusMicroLearningStack),
        ),
        const SizedBox(width: 8),
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            CupertinoIcons.search,
            color: HardSyncColors.inkMuted,
          ),
        ),
      ],
    ),
  );
}

class _PathHero extends StatelessWidget {
  final LearningPath path;
  final int courses;
  const _PathHero({required this.path, required this.courses});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 700;
      return Container(
        height: wide ? 390 : 320,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [HardSyncColors.oliveMist, HardSyncColors.apricotMist],
          ),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  wide ? 28 : 12,
                  wide ? 16 : 8,
                  wide ? 28 : 12,
                  0,
                ),
                child: AppIllustration(path.illustration),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                wide ? 26 : 18,
                14,
                wide ? 26 : 18,
                18,
              ),
              color: Colors.white.withValues(alpha: .64),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    path.title,
                    style: GoogleFonts.newsreader(
                      fontSize: wide ? 30 : 24,
                      height: 1.05,
                      fontWeight: FontWeight.w700,
                      color: HardSyncColors.ink,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    path.audience,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      height: 1.4,
                      color: HardSyncColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '$courses courses · about ${courses * 30} min',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: HardSyncColors.violetDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _RoadmapStage extends StatelessWidget {
  final LearningPath stage;
  final int stageIndex;
  final List<(LearningCourse, int, LearningLesson)> bytes;
  final String progressLabel;
  final bool Function(LearningCourse, int) isComplete;
  final void Function(LearningCourse, int, LearningLesson) onByteTap;

  const _RoadmapStage({
    required this.stage,
    required this.stageIndex,
    required this.bytes,
    required this.progressLabel,
    required this.isComplete,
    required this.onByteTap,
  });

  @override
  Widget build(BuildContext context) {
    final allDone =
        bytes.isNotEmpty &&
        bytes.every((entry) => isComplete(entry.$1, entry.$2));
    final started = bytes.any((entry) => isComplete(entry.$1, entry.$2));
    final status = allDone
        ? 'Stage complete'
        : started
        ? 'In progress'
        : 'Ready when you are';
    final stageTint = switch (stageIndex) {
      0 => HardSyncColors.oliveMist,
      1 => HardSyncColors.lilacMist,
      _ => HardSyncColors.apricotMist,
    };
    final stageAccent = switch (stageIndex) {
      0 => HardSyncColors.olive,
      1 => HardSyncColors.violet,
      _ => HardSyncColors.apricot,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: HardSyncColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0B17182B),
              blurRadius: 16,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
              color: stageTint,
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .74),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${stageIndex + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: stageAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${stage.level} · ${stage.title}',
                          style: GoogleFonts.newsreader(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          progressLabel,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 55,
                    height: 55,
                    child: AppIllustration(stage.illustration),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stage.audience,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: bytes.isEmpty
                          ? 0
                          : bytes
                                    .where(
                                      (entry) => isComplete(entry.$1, entry.$2),
                                    )
                                    .length /
                                bytes.length,
                      minHeight: 7,
                      color: stageAccent,
                      backgroundColor: stageTint,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    progressLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 7),
                  ...bytes.indexed.map((entry) {
                    final index = entry.$1;
                    final course = entry.$2.$1;
                    final lessonIndex = entry.$2.$2;
                    final lesson = entry.$2.$3;
                    final complete = isComplete(course, lessonIndex);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Material(
                        color: HardSyncColors.cream,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          onTap: () => onByteTap(course, lessonIndex, lesson),
                          borderRadius: BorderRadius.circular(18),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: complete ? stageTint : Colors.white,
                                    border: Border.all(
                                      color: HardSyncColors.border,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    complete
                                        ? Icons.check_rounded
                                        : Icons.play_arrow_rounded,
                                    size: 19,
                                    color: stageAccent,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${index + 1}. ${lesson.title}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${course.title} · quick read + linked practice',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  CupertinoIcons.chevron_right,
                                  size: 17,
                                  color: stageAccent,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final int index;
  final LearningCourse course;
  final double progress;
  final VoidCallback onTap;
  const _CourseCard({
    required this.index,
    required this.course,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: progress > 0
                ? HardSyncColors.lilacBorder
                : HardSyncColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _learningTints[index % _learningTints.length],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: AppIllustration(course.hero),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${index + 1}. ${course.title}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.newsreader(
                          fontSize: 20,
                          height: 1.08,
                          fontWeight: FontWeight.w700,
                          color: HardSyncColors.ink,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Quick read + practice · ',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          color: HardSyncColors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 9),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 5,
                          backgroundColor: HardSyncColors.borderSubtle,
                          valueColor: AlwaysStoppedAnimation(
                            index.isEven
                                ? HardSyncColors.apricot
                                : HardSyncColors.olive,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  CupertinoIcons.chevron_right,
                  size: 19,
                  color: HardSyncColors.inkMuted,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _BrowseCourseCard extends StatelessWidget {
  final LearningCourse course;
  final int completedBytes;
  final VoidCallback onTap;

  const _BrowseCourseCard({
    required this.course,
    required this.completedBytes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final count = course.lessons.length;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          constraints: const BoxConstraints(minHeight: 128),
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: HardSyncColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0817182B),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 105,
                height: 106,
                decoration: BoxDecoration(
                  color: HardSyncColors.lilacMist,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: AppIllustration(course.hero),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      course.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.newsreader(
                        fontSize: 19,
                        height: 1.05,
                        fontWeight: FontWeight.w700,
                        color: HardSyncColors.ink,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      course.promise,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        height: 1.3,
                        color: HardSyncColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.menu_book_rounded,
                          size: 13,
                          color: HardSyncColors.violet,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$count quick bytes',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: HardSyncColors.inkMuted,
                          ),
                        ),
                        const SizedBox(width: 9),
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 13,
                          color: HardSyncColors.olive,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '$completedBytes/$count',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: HardSyncColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: HardSyncColors.lilacMist,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color: HardSyncColors.violetDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatalogCard extends StatelessWidget {
  final LearningCourse course;
  final VoidCallback onTap;
  const _CatalogCard({required this.course, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          border: Border.all(color: HardSyncColors.border),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _learningTint(course.id),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: AppIllustration(course.hero),
              ),
            ),
            const SizedBox(height: 9),
            Text(
              course.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.newsreader(
                fontSize: 17,
                height: 1.05,
                fontWeight: FontWeight.w700,
                color: HardSyncColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Quick read + practice · ',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                color: HardSyncColors.inkMuted,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class CourseDetailScreen extends StatelessWidget {
  final LearningCourse course;
  const CourseDetailScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: HardSyncColors.cream,
    body: SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            sliver: SliverToBoxAdapter(
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    CupertinoIcons.back,
                    color: HardSyncColors.ink,
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 225,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: HardSyncColors.lilacMist,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: AppIllustration(course.hero),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    course.title,
                    style: GoogleFonts.newsreader(
                      fontSize: 32,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      color: HardSyncColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    course.promise,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      height: 1.45,
                      color: HardSyncColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetaPill('${course.lessons.length} quick bytes'),
                      _MetaPill('1:1 practice'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            sliver: SliverToBoxAdapter(
              child: Text(
                'What you will learn',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverList.separated(
              itemCount: course.lessons.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _LessonRow(
                course: course,
                lesson: course.lessons[index],
                index: index,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const AppIcon(HardSyncAssets.iconTargetBullseye, size: 34),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'One example',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              color: HardSyncColors.ink,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            course.lessons.first.example,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              height: 1.4,
                              color: HardSyncColors.inkMuted,
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
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            sliver: SliverToBoxAdapter(
              child: SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LessonScreen(
                          course: course,
                          lesson: course.lessons.first,
                          index: 0,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start this module'),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class CoursePracticeScreen extends StatelessWidget {
  final LearningCourse course;
  final LearningLesson? lesson;
  const CoursePracticeScreen({super.key, required this.course, this.lesson});

  @override
  Widget build(BuildContext context) {
    final scenarios = Scenario.defaultScenarios
        .where(
          (item) =>
              (lesson?.practiceScenarioIds ?? course.allPracticeScenarioIds)
                  .contains(item.id),
        )
        .toList();
    return Scaffold(
      backgroundColor: HardSyncColors.cream,
      appBar: AppBar(title: Text('Practise: ${course.title}')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: HardSyncColors.lilacMist,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QUICK BYTES · ${course.level.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  course.promise,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 9),
                ...(lesson == null ? course.lessons : [lesson!]).map(
                  (lesson) => Padding(
                    padding: const EdgeInsets.only(top: 9),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          lesson.concept,
                          style: const TextStyle(height: 1.4),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Example: ${lesson.example}',
                          style: const TextStyle(
                            height: 1.4,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Use your own words. There may be more than one good way to handle the situation.',
                  style: TextStyle(height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Practise what you just read',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          ...scenarios.map(
            (scenario) => Card(
              child: ListTile(
                title: Text(scenario.title),
                subtitle: Text(
                  '${scenario.difficultyLabel} · ${scenario.subtitle}',
                ),
                trailing: const Icon(Icons.play_arrow_rounded),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SessionPrepScreen(scenario: scenario),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final String text;
  const _MetaPill(this.text);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: HardSyncColors.border),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: HardSyncColors.inkMuted,
      ),
    ),
  );
}

class _LessonRow extends StatefulWidget {
  final LearningCourse course;
  final LearningLesson lesson;
  final int index;
  const _LessonRow({
    required this.course,
    required this.lesson,
    required this.index,
  });
  @override
  State<_LessonRow> createState() => _LessonRowState();
}

class _LessonRowState extends State<_LessonRow> {
  bool complete = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) {
      setState(
        () => complete =
            p
                .getStringList('learning_progress')
                ?.contains('${widget.course.id}:${widget.index}') ??
            false,
      );
    }
  }

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LessonScreen(
              course: widget.course,
              lesson: widget.lesson,
              index: widget.index,
            ),
          ),
        );
        _load();
      },
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          border: Border.all(
            color: complete
                ? HardSyncColors.lilacBorder
                : HardSyncColors.border,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: complete
                    ? HardSyncColors.oliveMist
                    : HardSyncColors.lilacMist,
                borderRadius: BorderRadius.circular(14),
              ),
              child: AppIllustration(widget.lesson.illustration),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.index + 1}. ${widget.lesson.title}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: HardSyncColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Quick read · example + practice',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      color: HardSyncColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              complete
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.chevron_right,
              size: 20,
              color: complete ? HardSyncColors.olive : HardSyncColors.inkMuted,
            ),
          ],
        ),
      ),
    ),
  );
}

class LessonScreen extends StatefulWidget {
  final LearningCourse course;
  final LearningLesson lesson;
  final int index;
  const LessonScreen({
    super.key,
    required this.course,
    required this.lesson,
    required this.index,
  });
  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  bool saving = false;
  int _step = 0;
  int? _selectedAnswer;
  bool _answerChecked = false;
  final TextEditingController _reflectionController = TextEditingController();

  String get _oneToOneSituation {
    if (widget.lesson.situation.trim().isNotEmpty) {
      return _readable(widget.lesson.situation);
    }
    return switch (widget.course.id) {
      'clarity' =>
        'A teammate leaves your 1:1 with a different idea of the deadline and who owns the next step.',
      'listening' =>
        'A teammate tells you the plan feels unfair. You feel ready to explain why the plan was made.',
      'feedback' =>
        'A handoff was late twice. You need to explain the effect without making the person feel attacked.',
      'boundaries' =>
        'A colleague asks you to take on urgent work, but your week is already full.',
      'conflict' =>
        'You and a teammate want different dates for the same piece of work.',
      'manage_up' =>
        'A senior leader asks you to promise a date that leaves little time for checks.',
      'coaching' =>
        'A teammate brings you a problem and waits for you to tell them what to do.',
      'presence' =>
        'Someone challenges your recommendation while you are explaining it.',
      'negotiation' =>
        'Another manager cannot spare the help you need unless your team changes its plan.',
      'performance' =>
        'A teammate has missed the same agreed step more than once.',
      _ => 'Think of a recent 1:1 that did not end as clearly as you hoped.',
    };
  }

  String get _weakExample => switch (widget.course.id) {
    'clarity' => '"Let us sort this out soon."',
    'listening' => '"We already explained why we have to do it this way."',
    'feedback' => '"You are careless with handoffs."',
    'boundaries' => '"Sure, I will try to fit it in."',
    'conflict' => '"You need to be more realistic."',
    'manage_up' => '"That date will not work."',
    'coaching' => '"Here is what you should do."',
    'presence' => '"No, that is the wrong way to look at it."',
    'negotiation' => '"Your team has to help us this week."',
    'performance' => '"You need to improve your attitude."',
    _ => '"I was only trying to help."',
  };

  String get _weakImpact => switch (widget.course.id) {
    'clarity' =>
      'They may leave without knowing the action, owner, or deadline.',
    'listening' =>
      'They may stop sharing useful details and feel brushed aside.',
    'feedback' =>
      'They may defend their character instead of discussing the missed step.',
    'boundaries' =>
      'You may take on work you cannot finish and surprise them later.',
    'conflict' =>
      'The disagreement may become personal instead of staying about the work.',
    'manage_up' =>
      'The leader may hear resistance without enough information to make a decision.',
    'coaching' =>
      'They may follow your answer without learning how to solve it next time.',
    'presence' =>
      'The conversation may turn into an argument about who is right.',
    'negotiation' =>
      'The other manager may push back because their needs were never discussed.',
    'performance' =>
      'They may not know which action must change or how you will review it.',
    _ =>
      'The other person may hear an excuse and miss the effect of what happened.',
  };

  String _readable(String value) => value;

  static const _stepLabels = [
    'Learn',
    'Quick read',
    'Example',
    'Think it through',
    'Remember',
    'Try a situation',
    'Complete',
  ];

  @override
  void dispose() {
    _reflectionController.dispose();
    super.dispose();
  }

  List<String> get _supportingVisuals {
    switch (widget.course.id) {
      case 'clarity':
        return [
          HardSyncAssets.illusConversationBlueprint,
          HardSyncAssets.illusClarityMeter,
        ];
      case 'listening':
        return [
          HardSyncAssets.illusEmpathyLens,
          HardSyncAssets.illusEmotionalCheckInOrb,
        ];
      case 'feedback':
        return [
          HardSyncAssets.illusSituationActionImpact,
          HardSyncAssets.illusBetterResponse,
        ];
      case 'boundaries':
        return [
          HardSyncAssets.illusPauseAndReframe,
          HardSyncAssets.illusScriptBuilder,
        ];
      case 'conflict':
        return [
          HardSyncAssets.illusConflictBridge,
          HardSyncAssets.illusDifficultConversationArena,
        ];
      case 'manage_up':
        return [
          HardSyncAssets.illusPushbackPractice,
          HardSyncAssets.illusExecutiveChallenge,
        ];
      case 'coaching':
        return [
          HardSyncAssets.illusQuietTeamMemberPersona,
          HardSyncAssets.illusCoachDebrief,
        ];
      case 'presence':
        return [
          HardSyncAssets.illusSpeakingPace,
          HardSyncAssets.illusToneAwareness,
        ];
      default:
        return [
          HardSyncAssets.illusConversationRewind,
          HardSyncAssets.illusJournalReflection,
        ];
    }
  }

  List<String> get _visualCaptions {
    switch (widget.course.id) {
      case 'clarity':
        return [
          'Map the message before adding detail.',
          'Check whether the outcome, ask, and ownership are visible.',
        ];
      case 'listening':
        return [
          'Look through the other person’s frame before responding.',
          'Use the pause to notice facts, concerns, and emotion.',
        ];
      case 'feedback':
        return [
          'Anchor feedback in situation, observable behavior, and impact.',
          'Compare a vague judgment with language someone can act on.',
        ];
      case 'boundaries':
        return [
          'Pause before an automatic yes, apology, or defensive no.',
          'Draft a boundary that includes a workable choice.',
        ];
      case 'conflict':
        return [
          'Build a bridge around the shared problem.',
          'Treat disagreement as a space for options, evidence, and review.',
        ];
      case 'manage_up':
        return [
          'Connect evidence and risk to the stakeholder’s goal.',
          'Make the trade-off and decision moment easy to see.',
        ];
      case 'coaching':
        return [
          'Create enough space for the other person to think.',
          'Reflect the learning without taking ownership of the decision.',
        ];
      case 'presence':
        return [
          'Use pace and pauses to make the main point easier to follow.',
          'Notice tone as information, not as a personality score.',
        ];
      default:
        return [
          'Rewind the facts before interpreting the conversation.',
          'Carry one useful observation into a concrete next attempt.',
        ];
    }
  }

  List<String> get _method {
    switch (widget.course.id) {
      case 'clarity':
        return [
          'Start with what needs to be decided or done.',
          'Describe what happened; leave guesses about intent out.',
          'Ask for one action and say when it is needed.',
          'Check understanding and agree who will do what next.',
        ];
      case 'listening':
        return [
          'Pause your first impulse to fix, defend, explain, or withdraw.',
          'Ask one open question and allow the answer to finish.',
          'Reflect the facts, concern, and need in neutral language.',
          'Check your understanding before choosing the next action together.',
        ];
      case 'feedback':
        return [
          'Describe the moment, the action, and its effect on the work.',
          'Ask what was happening from their point of view.',
          'Agree one useful action to try next time.',
          'For positive feedback, name the helpful action so it can be repeated.',
        ];
      case 'boundaries':
        return [
          'Name what you can and cannot take on.',
          'Show you understand why the request matters.',
          'Explain the effect of adding it to the current plan.',
          'Offer realistic choices and agree what will move.',
        ];
      case 'conflict':
        return [
          'Describe the shared work problem without assigning intent.',
          'Ask what each stated position is trying to protect.',
          'Summarize both accounts until each person recognizes the summary.',
          'Generate options, choose fair criteria, and schedule a review.',
        ];
      case 'manage_up':
        return [
          'Identify the senior stakeholder’s goal and decision constraints.',
          'Bring concise evidence and label estimates or assumptions honestly.',
          'Connect the risk directly to the outcome they care about.',
          'Recommend one option, show an alternative, and request a decision.',
        ];
      case 'coaching':
        return [
          'Agree what would make the conversation useful for the other person.',
          'Explore what they know, tried, and find difficult before advising.',
          'Reflect a pattern and ask what they notice.',
          'Offer advice with permission, then let them choose the commitment.',
        ];
      case 'presence':
        return [
          'Lead with the conclusion, recommendation, or decision required.',
          'Add one reason and the implication instead of a long chronology.',
          'Pause when challenged and answer the concern beneath the question.',
          'Restate the ask, then stop so the other person can respond.',
        ];
      default:
        return [
          'Record what was said or decided separately from your interpretation.',
          'Identify one behavior that helped and one behavior to change.',
          'Repair a specific impact when needed without over-explaining.',
          'Write a short cue for the next conversation and schedule a retry.',
        ];
    }
  }

  List<String> get _mistakes {
    switch (widget.course.id) {
      case 'clarity':
        return [
          'Beginning with a long history before stating the point.',
          'Treating your preferred solution as the only acceptable outcome.',
          'Ending with “we should” instead of an owner and date.',
        ];
      case 'listening':
        return [
          'Asking a question while already preparing your rebuttal.',
          'Repeating words without checking the concern beneath them.',
          'Naming emotion as a fact instead of leaving room for correction.',
        ];
      case 'feedback':
        return [
          'Using labels such as careless, negative, or not strategic.',
          'Hiding criticism between unrelated praise.',
          'Giving a verdict without hearing missing context.',
        ];
      case 'boundaries':
        return [
          'Apologizing until the boundary sounds optional.',
          'Offering an alternative that still violates the real constraint.',
          'Blaming policy or leadership instead of owning the message.',
        ];
      case 'conflict':
        return [
          'Trying to decide who is right before defining the problem.',
          'Assuming compromise always means splitting the difference.',
          'Moving to solutions before each account has been understood.',
        ];
      case 'manage_up':
        return [
          'Bringing resistance without evidence or alternatives.',
          'Overloading the stakeholder with operational detail.',
          'Leaving without confirming who owns the accepted risk.',
        ];
      case 'coaching':
        return [
          'Turning a coaching conversation into a disguised instruction.',
          'Asking several questions without listening to the answers.',
          'Taking ownership of the action the other person should own.',
        ];
      case 'presence':
        return [
          'Equating authority with speed, volume, or certainty.',
          'Adding detail after the listener already has enough to respond.',
          'Defending a position after new evidence should change it.',
        ];
      default:
        return [
          'Replaying the exchange as a judgment of your personality.',
          'Choosing a vague improvement such as “be more confident.”',
          'Writing a repair that explains your intent but ignores the impact.',
        ];
    }
  }

  String get _whyItMatters {
    switch (widget.course.id) {
      case 'clarity':
        return 'Ambiguity creates hidden disagreement. People can leave the same meeting with different ideas about the decision, priority, owner, or deadline. Clear communication reduces that coordination cost while still leaving room for questions and better information.';
      case 'listening':
        return 'A response can be logically correct and still miss the concern driving the conversation. Listening first reveals constraints, reduces avoidable defensiveness, and gives both people a more accurate problem to solve.';
      case 'feedback':
        return 'Feedback is useful only when the receiver can identify the behavior and try something different. Specific observations reduce argument about personality and create a fair basis for dialogue and improvement.';
      case 'boundaries':
        return 'A boundary protects a real constraint. Stating it clearly helps both people make an informed trade-off. Vague resistance often produces false agreement, resentment, or a commitment the team cannot keep.';
      case 'conflict':
        return 'Positions make conflict look binary. Interests reveal what each side is protecting and create more possible agreements. A shared problem and fair criteria also reduce the pressure to win through status or persistence.';
      case 'manage_up':
        return 'Senior stakeholders need a decision, not a hidden disagreement. Concise evidence, visible trade-offs, and a recommendation make it possible to challenge a plan while remaining accountable to the larger goal.';
      case 'coaching':
        return 'Solving every problem for a team member can create speed today and dependence tomorrow. Coaching develops judgment by keeping the thinking, decision, and commitment with the person who owns the work.';
      case 'presence':
        return 'Executive presence is behavioral. A clear headline, useful pause, and direct ask make your thinking easier to follow under pressure. These behaviors are more reliable than trying to perform a particular personality or speaking style.';
      default:
        return 'Reflection is useful when it produces a specific next behavior. Separating facts from interpretation reduces unproductive replay and helps you carry one practical lesson into the next conversation.';
    }
  }

  Future<void> _complete() async {
    setState(() => saving = true);
    final prefs = await SharedPreferences.getInstance();
    final items =
        prefs.getStringList('learning_progress')?.toSet() ?? <String>{};
    items.add('${widget.course.id}:${widget.index}');
    await prefs.setStringList('learning_progress', items.toList());
    if (!mounted) return;
    setState(() => saving = false);
  }

  void _next() {
    if (_step == 5) {
      _complete();
      return;
    }
    if (_step < 6) setState(() => _step++);
  }

  void _back() {
    if (_step == 0) {
      Navigator.pop(context);
    } else {
      setState(() {
        _step--;
        _answerChecked = false;
      });
    }
  }

  Widget _buildStaged(BuildContext context) {
    final progress = (_step + 1) / _stepLabels.length;
    return Scaffold(
      backgroundColor: HardSyncColors.cream,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 18, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _back,
                        icon: const Icon(CupertinoIcons.back),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '${widget.course.title} · ${widget.lesson.title}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: HardSyncColors.inkMuted,
                              ),
                            ),
                            const SizedBox(height: 7),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 5,
                                color: HardSyncColors.violet,
                                backgroundColor: HardSyncColors.lilacBorder,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        '${_step + 1}/${_stepLabels.length}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: HardSyncColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: SingleChildScrollView(
                      key: ValueKey(_step),
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      child: _stageContent(context),
                    ),
                  ),
                ),
                if (_step < 6)
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                    decoration: const BoxDecoration(
                      color: HardSyncColors.cream,
                      border: Border(
                        top: BorderSide(color: HardSyncColors.border),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        onPressed: saving ? null : _next,
                        child: Text(_stageButtonLabel),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _stageButtonLabel {
    if (saving) return 'Saving…';
    if (_step == 5) return 'Continue';
    return 'Continue';
  }

  Widget _stageContent(BuildContext context) {
    switch (_step) {
      case 0:
        return _lessonIntro(context);
      case 1:
        return _takeaways(context);
      case 2:
        return _workedExample(context);
      case 3:
        return _reflection(context);
      case 4:
        return _recap(context);
      case 5:
        return _knowledgeCheck(context);
      default:
        return _completion(context);
    }
  }

  Widget _stageHeading(
    BuildContext context,
    String eyebrow,
    String title,
    String subtitle,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        eyebrow.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10.5,
          letterSpacing: 1,
          fontWeight: FontWeight.w800,
          color: HardSyncColors.violetDark,
        ),
      ),
      const SizedBox(height: 7),
      Text(
        title,
        style: GoogleFonts.newsreader(
          fontSize: 31,
          height: 1.02,
          fontWeight: FontWeight.w700,
          color: HardSyncColors.ink,
        ),
      ),
      const SizedBox(height: 7),
      Text(
        subtitle,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          height: 1.45,
          color: HardSyncColors.inkMuted,
        ),
      ),
    ],
  );

  Widget _lessonIntro(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _stageHeading(
        context,
        _stepLabels[_step],
        widget.lesson.title,
        widget.lesson.outcome,
      ),
      const SizedBox(height: 18),
      Container(
        height: 230,
        width: double.infinity,
        decoration: BoxDecoration(
          color: HardSyncColors.lilacMist,
          borderRadius: BorderRadius.circular(28),
        ),
        child: AppIllustration(widget.lesson.illustration),
      ),
      const SizedBox(height: 16),
      _LessonBlock(
        title: 'What this means',
        asset: HardSyncAssets.iconLightbulbIdea,
        color: HardSyncColors.apricotMist,
        body: widget.lesson.concept,
      ),
      const SizedBox(height: 12),
      _LessonBlock(
        title: 'Why it matters',
        asset: HardSyncAssets.iconTargetBullseye,
        color: HardSyncColors.oliveMist,
        body: _whyItMatters,
      ),
    ],
  );

  Widget _takeaways(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _stageHeading(
        context,
        _stepLabels[_step],
        'Remember these points',
        'Use the ideas that fit. Your words and approach can be your own.',
      ),
      const SizedBox(height: 18),
      _LessonVisualBreak(
        illustration: _supportingVisuals.first,
        caption: _visualCaptions.first,
        color: HardSyncColors.lilacMist,
      ),
      const SizedBox(height: 14),
      ..._method.asMap().entries.map(
        (entry) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: [
              HardSyncColors.lilacMist,
              HardSyncColors.oliveMist,
              HardSyncColors.apricotMist,
              const Color(0xFFFFEBEF),
            ][entry.key % 4],
            borderRadius: BorderRadius.circular(19),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${entry.key + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: HardSyncColors.violet,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: HardSyncColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _workedExample(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _stageHeading(
        context,
        _stepLabels[_step],
        'A real example',
        'One possible way to respond. Adapt it to your own words and situation.',
      ),
      const SizedBox(height: 18),
      Container(
        height: 205,
        width: double.infinity,
        decoration: BoxDecoration(
          color: HardSyncColors.apricotMist,
          borderRadius: BorderRadius.circular(26),
        ),
        child: AppIllustration(_supportingVisuals.last),
      ),
      const SizedBox(height: 14),
      _exampleCard(
        false,
        'Could be clearer',
        _mistakes.first,
        'This wording may sound broad or blaming, which can make it harder to respond.',
      ),
      const SizedBox(height: 10),
      _exampleCard(
        true,
        'One possible response',
        widget.lesson.example,
        'This makes the situation clearer and opens a next step. Other respectful approaches can work too.',
      ),
    ],
  );

  Widget _exampleCard(bool positive, String title, String body, String note) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: HardSyncColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  positive
                      ? CupertinoIcons.check_mark_circled_solid
                      : CupertinoIcons.exclamationmark_circle,
                  color: HardSyncColors.violet,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              body,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                height: 1.5,
                color: HardSyncColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              note,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                height: 1.4,
                color: HardSyncColors.inkMuted,
              ),
            ),
          ],
        ),
      );

  Widget _reflection(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _stageHeading(
        context,
        _stepLabels[_step],
        'Take a moment',
        'Connect the idea to a real conversation. Your reflection stays private.',
      ),
      const SizedBox(height: 18),
      _LessonVisualBreak(
        illustration: HardSyncAssets.illusJournalReflection,
        caption: widget.lesson.reflection,
        color: HardSyncColors.oliveMist,
        reverse: true,
      ),
      const SizedBox(height: 14),
      TextField(
        controller: _reflectionController,
        minLines: 6,
        maxLines: 9,
        decoration: InputDecoration(
          hintText:
              'Write what happened, what you noticed, and what you want to try next…',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: HardSyncColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: HardSyncColors.border),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          const AppIcon(HardSyncAssets.iconShieldVerified, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Reflections are stored on this device until account sync is available.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    ],
  );

  Widget _recap(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _stageHeading(
        context,
        _stepLabels[_step],
        'Quick recap',
        'Keep these cues available when the real conversation begins.',
      ),
      const SizedBox(height: 18),
      ..._method
          .take(4)
          .toList()
          .asMap()
          .entries
          .map(
            (entry) => ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 4,
              ),
              leading: Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: HardSyncColors.lilacMist,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${entry.key + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: HardSyncColors.violet,
                  ),
                ),
              ),
              title: Text(
                entry.value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      const SizedBox(height: 12),
      Container(
        height: 190,
        width: double.infinity,
        decoration: BoxDecoration(
          color: HardSyncColors.lilacMist,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const AppIllustration(HardSyncAssets.illusCoachDebrief),
      ),
    ],
  );

  Widget _knowledgeCheck(BuildContext context) {
    final answers = [
      _mistakes.first,
      widget.lesson.example,
      _mistakes.length > 1
          ? _mistakes[1]
          : 'Avoid the conversation until it feels easier.',
      'Give a general reminder without naming the behavior.',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stageHeading(
          context,
          _stepLabels[_step],
          'Think it through',
          'Which response might help move this conversation forward?',
        ),
        const SizedBox(height: 18),
        Container(
          height: 145,
          width: double.infinity,
          decoration: BoxDecoration(
            color: HardSyncColors.apricotMist,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const AppIllustration(HardSyncAssets.illusCoachThinking),
        ),
        const SizedBox(height: 14),
        ...answers.asMap().entries.map((entry) {
          final selected = _selectedAnswer == entry.key;
          final border = selected
              ? HardSyncColors.violet
              : HardSyncColors.border;
          return InkWell(
            key: ValueKey('lesson_answer_${entry.key}'),
            onTap: _answerChecked
                ? null
                : () => setState(() => _selectedAnswer = entry.key),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: border, width: selected ? 1.6 : 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? border : HardSyncColors.lilacMist,
                    ),
                    child: Text(
                      String.fromCharCode(65 + entry.key),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: selected
                            ? Colors.white
                            : HardSyncColors.inkMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        if (_answerChecked)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: HardSyncColors.apricotMist,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              'This is one possible approach. Adapt it to the situation and your own words. Notice what helps the other person engage.',
              style: const TextStyle(fontWeight: FontWeight.w600, height: 1.4),
            ),
          ),
      ],
    );
  }

  Widget _completion(BuildContext context) => Column(
    children: [
      const SizedBox(height: 16),
      SizedBox(
        height: 260,
        width: double.infinity,
        child: AppIllustration(
          widget.index == widget.course.lessons.length - 1
              ? HardSyncAssets.gamifyLeadershipLevelUp
              : HardSyncAssets.gamifyCoachCelebration,
        ),
      ),
      Text(
        widget.index == widget.course.lessons.length - 1
            ? 'Course complete!'
            : 'Lesson complete!',
        textAlign: TextAlign.center,
        style: GoogleFonts.newsreader(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: HardSyncColors.ink,
        ),
      ),
      const SizedBox(height: 7),
      Text(
        widget.index == widget.course.lessons.length - 1
            ? 'You completed ${widget.course.title}.'
            : 'You finished ${widget.lesson.title}.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: HardSyncColors.apricotMist,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const AppIcon(HardSyncAssets.iconSeedlingGrowth, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.course.takeaway,
                style: GoogleFonts.newsreader(
                  fontSize: 18,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      SizedBox(
        width: double.infinity,
        height: 54,
        child: FilledButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CoursePracticeScreen(
                  course: widget.course,
                  lesson: widget.lesson,
                ),
              ),
            );
          },
          child: Text('Choose practice situations'),
        ),
      ),
      const SizedBox(height: 10),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Finish for now'),
      ),
    ],
  );

  Widget _quickBytePage(BuildContext context) => Scaffold(
    backgroundColor: HardSyncColors.cream,
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 18, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(CupertinoIcons.back),
                      ),
                      Expanded(
                        child: Text(
                          'QUICK BYTE  ${widget.index + 1} OF ${widget.course.lessons.length}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w800,
                            color: HardSyncColors.violetDark,
                          ),
                        ),
                      ),
                      const _MetaPill('Manager skill'),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _readable(widget.lesson.title),
                        style: GoogleFonts.newsreader(
                          fontSize: 34,
                          height: 1.02,
                          fontWeight: FontWeight.w700,
                          color: HardSyncColors.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _readable(widget.lesson.outcome),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          height: 1.45,
                          color: HardSyncColors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        height: 210,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: HardSyncColors.oliveMist,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: AppIllustration(widget.lesson.illustration),
                      ),
                      const SizedBox(height: 16),
                      _LessonBlock(
                        title: 'A 1:1 situation',
                        asset: HardSyncAssets.iconLightbulbIdea,
                        color: Colors.white,
                        body: _oneToOneSituation,
                      ),
                      const SizedBox(height: 12),
                      _LessonBlock(
                        title: 'The idea',
                        asset: HardSyncAssets.iconLightbulbIdea,
                        color: Colors.white,
                        body: _readable(widget.lesson.concept),
                      ),
                      const SizedBox(height: 12),
                      _LessonBlock(
                        title: 'Why it helps',
                        asset: HardSyncAssets.iconTargetBullseye,
                        color: Colors.white,
                        body: _readable(_whyItMatters),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Use this simple approach',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      ..._method
                          .take(4)
                          .toList()
                          .asMap()
                          .entries
                          .map(
                            (entry) => Container(
                              margin: const EdgeInsets.only(bottom: 9),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: HardSyncColors.border,
                                ),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 15,
                                    backgroundColor: HardSyncColors.violet,
                                    child: Text(
                                      '${entry.key + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _readable(entry.value),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        height: 1.45,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      const SizedBox(height: 16),
                      _LessonVisualBreak(
                        illustration: _supportingVisuals.first,
                        caption: _visualCaptions.first,
                        color: HardSyncColors.cream,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'See it in a 1:1',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      _exampleCard(
                        false,
                        'This can go wrong',
                        _weakExample,
                        _weakImpact,
                      ),
                      const SizedBox(height: 10),
                      _exampleCard(
                        true,
                        'Try something like this',
                        _readable(widget.lesson.example),
                        'Use your own words. There is no single perfect script.',
                      ),
                      const SizedBox(height: 16),
                      _LessonVisualBreak(
                        illustration: _supportingVisuals.last,
                        caption: _visualCaptions.last,
                        color: HardSyncColors.cream,
                        reverse: true,
                      ),
                      const SizedBox(height: 20),
                      _LessonBlock(
                        title: 'Before you practise',
                        asset: HardSyncAssets.iconSeedlingGrowth,
                        color: Colors.white,
                        body: _readable(widget.lesson.reflection),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _reflectionController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'Write a note for your next 1:1 (optional)',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(
                              color: HardSyncColors.border,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton.icon(
                          onPressed: saving
                              ? null
                              : () async {
                                  await _complete();
                                  if (!context.mounted) return;
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CoursePracticeScreen(
                                        course: widget.course,
                                        lesson: widget.lesson,
                                      ),
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: Text(
                            saving
                                ? 'Saving...'
                                : 'Mark read & practise scenarios',
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          'Your practice will use situations linked to this quick byte.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => _quickBytePage(context);
}

class _LessonVisualBreak extends StatelessWidget {
  final String illustration;
  final String caption;
  final Color color;
  final bool reverse;
  const _LessonVisualBreak({
    required this.illustration,
    required this.caption,
    required this.color,
    this.reverse = false,
  });

  @override
  Widget build(BuildContext context) {
    final visual = Expanded(
      flex: 5,
      child: AppIllustration(illustration, height: 126),
    );
    final copy = Expanded(
      flex: 6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Visual cue',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: .8,
              color: HardSyncColors.violetDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            caption,
            style: GoogleFonts.newsreader(
              fontSize: 18,
              height: 1.15,
              fontWeight: FontWeight.w700,
              color: HardSyncColors.ink,
            ),
          ),
        ],
      ),
    );
    return Container(
      constraints: const BoxConstraints(minHeight: 170),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: reverse
            ? [visual, const SizedBox(width: 10), copy]
            : [copy, const SizedBox(width: 10), visual],
      ),
    );
  }
}

class _LessonBlock extends StatelessWidget {
  final String title;
  final String asset;
  final Color color;
  final String body;
  const _LessonBlock({
    required this.title,
    required this.asset,
    required this.color,
    required this.body,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIcon(asset, size: 32),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: HardSyncColors.ink,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                body,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  height: 1.5,
                  color: HardSyncColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
