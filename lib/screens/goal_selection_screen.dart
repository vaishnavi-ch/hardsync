import '../services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'scenario_hub_screen.dart';
import '../theme/hardsync_assets.dart';
import '../theme/hardsync_theme.dart';

class GoalSelectionScreen extends StatefulWidget {
  const GoalSelectionScreen({super.key});

  @override
  State<GoalSelectionScreen> createState() => _GoalSelectionScreenState();
}

class _GoalSelectionScreenState extends State<GoalSelectionScreen> {
  final Set<int> _selectedIndices = {};
  bool _loading = true;

  final List<Map<String, dynamic>> _options = [
    {
      'id': 'managing_former_peers',
      'title': 'Managing Former Peers',
      'subtitle':
          'Navigating authority and setting boundaries with prior friends or teammates.',
      'asset': HardSyncAssets.iconUsersGroup,
    },
    {
      'id': 'critical_feedback',
      'title': 'Delivering Critical Feedback',
      'subtitle':
          'Clear, compassionate performance conversations without sugarcoating.',
      'asset': HardSyncAssets.iconChatBubbles,
    },
    {
      'id': 'push_back_leadership',
      'title': 'Pushing Back on Leadership',
      'subtitle':
          'Saying no to unrealistic deadlines and high-stakes executive demands.',
      'asset': HardSyncAssets.iconShieldVerified,
    },
    {
      'id': 'team_friction',
      'title': 'Resolving Team Friction',
      'subtitle':
          'De-escalating defensive reactions and cross-functional disagreements.',
      'asset': HardSyncAssets.iconHandshakePartnership,
    },
    {
      'id': 'scope_salary',
      'title': 'Negotiating Scope & Salary',
      'subtitle':
          'Advocating for personal compensation, title updates, and team headcount.',
      'asset': HardSyncAssets.iconTrophyCup,
    },
  ];

  @override
  void initState() {
    super.initState();
    SupabaseService.instance
        .fetchOwnProfile()
        .then((profile) {
          final saved = (profile['selected_goal_ids'] as List? ?? const [])
              .map((value) => value.toString())
              .toSet();
          if (mounted) {
            setState(() {
              _selectedIndices.clear();
              for (var index = 0; index < _options.length; index++) {
                if (saved.contains(_options[index]['id'])) {
                  _selectedIndices.add(index);
                }
              }
              _loading = false;
            });
          }
        })
        .catchError((_) {
          if (mounted) setState(() => _loading = false);
        });
  }

  Future<void> _onContinue() async {
    await SupabaseService.instance.updateOwnProfile({
      'selected_goal_ids': _selectedIndices
          .map((index) => _options[index]['id'])
          .toList(),
      'onboarding_completed': true,
    });
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ScenarioHubScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: HardSyncColors.cream,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              children: [
                // Top Navigation Bar
                _buildTopNav(context),

                // Scrollable Question & Options
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // Eyebrow
                        Row(
                          children: [
                            const AppIcon(
                              HardSyncAssets.iconSparkleStarsMagic,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'PERSONALIZE YOUR REHEARSALS',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: const Color(0xFF3D5A46),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Question Headline
                        Text(
                          'What leadership conversations give you the most friction?',
                          style: GoogleFonts.newsreader(
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1C1917),
                            height: 1.2,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'We’ll tailor your first practice scenarios to your day-to-day challenges. Select all that apply.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            color: const Color(0xFF57534E),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 18),

                        Container(
                          height: 118,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: HardSyncColors.lilacMist,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const AppIllustration(
                            HardSyncAssets.illusPersonaSelector,
                            alignment: Alignment.centerRight,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Options Cards
                        ...List.generate(_options.length, (index) {
                          final option = _options[index];
                          final isSelected = _selectedIndices.contains(index);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedIndices.remove(index);
                                  } else {
                                    _selectedIndices.add(index);
                                  }
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFFFAF7F2),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF3D5A46)
                                        : const Color(0xFFE9E2D8),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF3D5A46,
                                            ).withValues(alpha: 0.1),
                                            blurRadius: 10,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.02,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Category icon
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFFF4F7F4)
                                            : const Color(
                                                0xFFEAE3DA,
                                              ).withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFFC7D7C8)
                                              : Colors.transparent,
                                        ),
                                      ),
                                      child: AppIcon(
                                        option['asset'] as String,
                                        size: 23,
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Title & description
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            option['title'] as String,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF1C1917),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            option['subtitle'] as String,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              color: const Color(0xFF57534E),
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Checked indicator circle
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected
                                            ? const Color(0xFF3D5A46)
                                            : Colors.white,
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF3D5A46)
                                              : const Color(0xFFD6D3D1),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              size: 13,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // Floating Sticky Bottom Action
                _buildStickyBottom(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopNav(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFEAE3DA).withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 14,
                color: Color(0xFF44403C),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF2EDE6),
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(color: const Color(0xFFE5DDD2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF3D5A46),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'STEP 1 OF 3',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: const Color(0xFF57534E),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _onContinue,
            child: Text(
              'Skip',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF78716C),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBottom(BuildContext context) {
    final count = _selectedIndices.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFFBF9F5),
        border: Border(top: BorderSide(color: Color(0xFFEDE8DE))),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3D5A46),
                foregroundColor: Colors.white,
                elevation: 3,
                shadowColor: const Color(0xFF3D5A46).withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _onContinue,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    count > 0 ? 'Continue ($count selected)' : 'Continue',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 13,
                color: Color(0xFFA8A29E),
              ),
              const SizedBox(width: 4),
              Text(
                'Your responses are 100% private to your device.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: const Color(0xFF78716C),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
