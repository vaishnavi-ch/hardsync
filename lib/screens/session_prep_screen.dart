import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/scenario.dart';
import '../models/subscription_tier.dart';
import '../models/user_persona.dart';
import '../providers/simulation_provider.dart';
import '../providers/subscription_provider.dart';
import 'live_call_screen.dart';
import 'subscription_paywall_screen.dart';
import '../theme/hardsync_assets.dart';
import '../theme/hardsync_theme.dart';

class SessionPrepScreen extends StatefulWidget {
  final Scenario scenario;

  const SessionPrepScreen({super.key, required this.scenario});

  @override
  State<SessionPrepScreen> createState() => _SessionPrepScreenState();
}

class _SessionPrepScreenState extends State<SessionPrepScreen> {
  late List<bool> _talkingPointsChecked;
  late List<String> _talkingPoints;

  late UserPersona _selectedUserPersona;
  CallMode _selectedCallMode = CallMode.text;
  bool _initializedRoles = false;
  bool _starting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedRoles) {
      final sub = Provider.of<SubscriptionProvider>(context, listen: false);

      _selectedUserPersona = widget.scenario.userPersona;

      if (sub.canUseVideoCalls) {
        _selectedCallMode = CallMode.video;
      } else if (sub.canUseAudioCalls) {
        _selectedCallMode = CallMode.audio;
      } else {
        _selectedCallMode = CallMode.text;
      }
      _initializedRoles = true;
    }
  }

  @override
  void initState() {
    super.initState();
    // Use scenario objectives or fallback talking points
    if (widget.scenario.userObjectives.isNotEmpty) {
      _talkingPoints = [
        ...widget.scenario.userObjectives,
        'Keep a calm, confident, and respectful tone',
      ].take(4).toList();
    } else {
      _talkingPoints = [
        'Define project deadline for Friday',
        'Acknowledge past friendship, but state clear boundaries',
        'Be specific about next steps and expectations',
        'Keep a calm, confident, and respectful tone',
      ];
    }
    // Default first 2 or 3 checked as in Stitch design
    _talkingPointsChecked = List.generate(
      _talkingPoints.length,
      (index) => false,
    );
  }

  int get _checkedCount => _talkingPointsChecked.where((c) => c).length;

  @override
  Widget build(BuildContext context) {
    final scenario = widget.scenario;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 820;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: wide ? 980 : 440),
                child: Column(
                  children: [
                    // Top Navigation Header
                    _buildTopNavigation(context),

                    // Scrollable Content
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        child: wide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        _buildScenarioCard(scenario),
                                        const SizedBox(height: 14),
                                        _buildStudioCustomizer(),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 18),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        _buildGoalBox(scenario),
                                        const SizedBox(height: 14),
                                        _buildTalkingPointsCard(),
                                        const SizedBox(height: 14),
                                        _buildMentorTipCard(),
                                        const SizedBox(height: 14),
                                        _buildChallengesSection(),
                                        const SizedBox(height: 16),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildScenarioCard(scenario),
                                  const SizedBox(height: 14),
                                  _buildStudioCustomizer(),
                                  const SizedBox(height: 14),
                                  _buildGoalBox(scenario),
                                  const SizedBox(height: 14),
                                  _buildTalkingPointsCard(),
                                  const SizedBox(height: 14),
                                  _buildMentorTipCard(),
                                  const SizedBox(height: 14),
                                  _buildChallengesSection(),
                                  const SizedBox(height: 16),
                                ],
                              ),
                      ),
                    ),

                    // Bottom CTA Controls
                    Align(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: _buildBottomControls(context),
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

  Widget _buildTopNavigation(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: Color(0xFF1E2522),
            ),
            tooltip: 'Go back',
          ),
          Expanded(
            child: Text(
              'Prepare for Your Session',
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.newsreader(
                fontSize: 21,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E2522),
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildScenarioCard(Scenario scenario) {
    final personaIllus = Scenario.illustrationFor(scenario.id);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8E3DA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Counterpart Illustration Stage
          Container(
            width: double.infinity,
            height: 205,
            color: const Color(0xFFF1EDFF),
            alignment: Alignment.bottomCenter,
            child: AppIllustration(
              personaIllus,
              height: 195,
              fit: BoxFit.contain,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF1F5),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        scenario.difficultyLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF335C6D),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1EB),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AppIcon(
                            HardSyncAssets.iconHeartbeatPulseHealth,
                            size: 11,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${scenario.persona.baselineDefensiveness}% Defensiveness',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFF8A43),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  scenario.title,
                  style: GoogleFonts.newsreader(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E2522),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  scenario.contextBrief,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: const Color(0xFF5C6661),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Counterpart: ',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8A8275),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${scenario.persona.name} (${scenario.persona.role})',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2C3D34),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalBox(Scenario scenario) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF2ED),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3E8E1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFDEE5DC),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const AppIcon(HardSyncAssets.iconTargetBullseye, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Goal',
                  style: GoogleFonts.newsreader(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E2522),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  scenario.userObjectives.isNotEmpty
                      ? scenario.userObjectives.first
                      : 'Have a clear, direct conversation, set a firm deadline, and maintain a positive working relationship.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF5C6661),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTalkingPointsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECE7DE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Things to consider',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.newsreader(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E2522),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$_checkedCount of ${_talkingPoints.length}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF808984),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(_talkingPoints.length, (index) {
            final isChecked = _talkingPointsChecked[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _talkingPointsChecked[index] =
                        !_talkingPointsChecked[index];
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: BoxDecoration(
                        color: isChecked
                            ? const Color(0xFF496653)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: isChecked
                              ? const Color(0xFF496653)
                              : const Color(0xFFCCC6B9),
                          width: 1.5,
                        ),
                      ),
                      child: isChecked
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _talkingPoints[index],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: isChecked
                              ? FontWeight.w500
                              : FontWeight.w400,
                          color: isChecked
                              ? const Color(0xFF1E2522)
                              : const Color(0xFF5C6661),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMentorTipCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F6F0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEBE3D3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFEFE7D8),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const AppIcon(HardSyncAssets.iconLightbulbIdea, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Briefing Insight',
                  style: GoogleFonts.newsreader(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E2522),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '\u201cAcknowledge the history, but don\u2019t let it override the standard. Be warm, clear, and confident.\u201d',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF616B66),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengesSection() {
    final challenges = [
      {
        'label': 'Pushback',
        'bg': const Color(0xFFFAF4ED),
        'text': const Color(0xFF4E443B),
        'border': const Color(0xFFEFE5D7),
        'icon': HardSyncAssets.iconChatBubbles,
      },
      {
        'label': 'Casual familiarity',
        'bg': const Color(0xFFF6F4EE),
        'text': const Color(0xFF4A4F4A),
        'border': const Color(0xFFE9E4D9),
        'icon': HardSyncAssets.iconUsersGroup,
      },
      {
        'label': 'Defensiveness spike',
        'bg': const Color(0xFFFAF2EF),
        'text': const Color(0xFF844335),
        'border': const Color(0xFFF4E1DB),
        'icon': HardSyncAssets.iconHeartbeatPulseHealth,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Anticipated Dynamics',
          style: GoogleFonts.newsreader(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E2522),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: challenges.map((item) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: item['bg'] as Color,
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: item['border'] as Color),
                ),
                child: Row(
                  children: [
                    AppIcon(item['icon'] as String, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      item['label'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: item['text'] as Color,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStudioCustomizer() {
    final scenario = widget.scenario;
    final userPersona = _selectedUserPersona;
    final aiPersona = scenario.persona;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5DFD5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR ROLE',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: HardSyncColors.violetDark,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          _buildPersonaIdentity(
            image: Text(
              userPersona.iconEmoji,
              style: const TextStyle(fontSize: 23),
            ),
            name: userPersona.title,
            detail: userPersona.roleSummary,
          ),
          const SizedBox(height: 16),
          Text(
            'SCENARIO PARTNER',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF7A6B56),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          _buildPersonaIdentity(
            image: AppAvatar(aiPersona.avatarAsset, size: 42, borderWidth: 0),
            name: aiPersona.name,
            detail: '${aiPersona.role} · ${aiPersona.company}',
          ),
          const SizedBox(height: 8),
          Text(
            'This person stays the same in text and calls for this scenario.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: HardSyncColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonaIdentity({
    required Widget image,
    required String name,
    required String detail,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEBE5DA)),
      ),
      child: Row(
        children: [
          image,
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E2522),
                  ),
                ),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context) {
    final sub = Provider.of<SubscriptionProvider>(context);
    final simulation = context.watch<SimulationProvider>();
    final canUseAudio = sub.canUseAudioCalls;
    final canUseVideo = sub.canUseVideoCalls;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFFAF8F5),
        border: Border(top: BorderSide(color: Color(0xFFEDE8DE))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Call Mode Selector Bar
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: HardSyncColors.lilacMist,
              borderRadius: BorderRadius.circular(14),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tabWidth = constraints.maxWidth / 3;
                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      left: tabWidth * _selectedCallMode.index,
                      top: 0,
                      bottom: 0,
                      width: tabWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        _buildModeTab(
                          label: 'Text Drill',
                          mode: CallMode.text,
                          iconAsset: HardSyncAssets.iconChatBubbles,
                          isLocked: false,
                          badge: 'FREE',
                        ),
                        _buildModeTab(
                          label: 'Voice Audio',
                          mode: CallMode.audio,
                          iconAsset: HardSyncAssets.iconHeartbeatPulseHealth,
                          isLocked: !canUseAudio,
                          badge: 'PRO',
                        ),
                        _buildModeTab(
                          label: 'Video',
                          mode: CallMode.video,
                          iconAsset: HardSyncAssets.iconLaptopComputer,
                          isLocked: !canUseVideo,
                          badge: 'ULTRA',
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // Plan requirement / session limit disclosure
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEBE5DA)),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, size: 16, color: Color(0xFFD97706)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedCallMode == CallMode.text
                        ? 'Text practice is included with every plan'
                        : (_selectedCallMode == CallMode.audio
                              ? 'Included with Pro & Ultra • 10 min per session'
                              : 'Included with Ultra • 10 min per session'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: HardSyncColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: HardSyncColors.ink,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed:
                  _starting || simulation.callState == CallState.connecting
                  ? null
                  : () async {
                      if (_selectedCallMode == CallMode.audio &&
                          !canUseAudio) {
                        _showUpgradeSheet(context, SubscriptionTier.pro);
                        return;
                      }
                      if (_selectedCallMode == CallMode.video &&
                          !canUseVideo) {
                        _showUpgradeSheet(context, SubscriptionTier.ultra);
                        return;
                      }

                      setState(() => _starting = true);
                      await simulation.startCall(
                        widget.scenario,
                        mode: _selectedCallMode,
                      );
                      // Auto-retry once on session conflict (closes the stale session)
                      if (simulation.hasSessionConflict ||
                          (simulation.callState == CallState.ended &&
                              simulation.error != null &&
                              simulation.error!.contains('earlier scenario'))) {
                        await simulation.retryStart();
                      }
                      if (!context.mounted) return;
                      if (simulation.callState == CallState.ended) {
                        setState(() => _starting = false);
                        // If there's still a conflict after auto-retry, show a
                        // prominent "Force End" button instead of just a snackbar.
                        if (simulation.hasSessionConflict ||
                            (simulation.error?.contains('earlier scenario') == true)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              duration: const Duration(seconds: 8),
                              backgroundColor: const Color(0xFF844335),
                              content: const Text(
                                'A previous scenario is blocking. Tap "Force End" to clear it.',
                              ),
                              action: SnackBarAction(
                                label: 'Force End',
                                textColor: Colors.white,
                                onPressed: () async {
                                  await simulation.retryStart();
                                  if (!context.mounted) return;
                                  if (simulation.callState != CallState.ended) {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (_) => const LiveCallScreen(),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                simulation.error ??
                                    'Could not start the scenario.',
                              ),
                              backgroundColor: const Color(0xFF844335),
                            ),
                          );
                        }
                        return;
                      }
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const LiveCallScreen(),
                        ),
                      );
                    },
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AppIcon(HardSyncAssets.iconRocketLaunch, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      _starting
                          ? 'Preparing scenario…'
                          : _selectedCallMode == CallMode.video
                          ? 'Begin Video Call'
                          : (_selectedCallMode == CallMode.audio
                                ? 'Begin Audio Call'
                                : 'Begin Text Practice'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (_) => _buildScenarioDetailsModal(widget.scenario),
              );
            },
            child: Text(
              'View Scenario Details',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF5C6661),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab({
    required String label,
    required CallMode mode,
    required String iconAsset,
    required bool isLocked,
    required String badge,
  }) {
    final isSelected = _selectedCallMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedCallMode = mode),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcon(iconAsset, size: 16),
                  const SizedBox(width: 4),
                  if (isLocked)
                    const Icon(Icons.lock, size: 10, color: Color(0xFF9CA3AF))
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: HardSyncColors.lilacMist,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: HardSyncColors.violetDark,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? HardSyncColors.ink
                      : HardSyncColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUpgradeSheet(BuildContext context, SubscriptionTier requiredTier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: requiredTier.badgeBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    requiredTier == SubscriptionTier.ultra
                        ? Icons.videocam
                        : Icons.mic,
                    color: requiredTier.primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Unlock ${requiredTier.displayName}',
                  style: GoogleFonts.newsreader(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E2522),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  requiredTier == SubscriptionTier.ultra
                      ? 'Video calls come with HardSync Ultra.'
                      : 'Audio calls come with HardSync Pro (and Ultra).',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: requiredTier.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SubscriptionPaywallScreen(),
                        ),
                      );
                    },
                    child: Text('View ${requiredTier.displayName} plan'),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SubscriptionPaywallScreen(),
                      ),
                    );
                  },
                  child: const Text('View All Plan Options'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScenarioDetailsModal(Scenario scenario) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDCD7CC),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            scenario.title,
            style: GoogleFonts.newsreader(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E2522),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Partner: ${scenario.persona.name} (${scenario.persona.role})',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF7C5CE7),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            scenario.contextBrief,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              color: const Color(0xFF4A4F4A),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          if (scenario.trapPhrasesToAvoid.isNotEmpty)
            Text(
              'Try to avoid:',
              style: GoogleFonts.newsreader(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFF8A43),
              ),
            ),
          const SizedBox(height: 6),
          if (scenario.trapPhrasesToAvoid.isNotEmpty)
            ...scenario.trapPhrasesToAvoid.map(
              (phrase) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.close, size: 14, color: Color(0xFFFF8A43)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        phrase,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          color: const Color(0xFF626C66),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
