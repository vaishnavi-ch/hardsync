import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/persona.dart';
import '../models/scenario.dart';
import '../services/backend_service.dart';
import '../theme/hardsync_assets.dart';
import '../theme/hardsync_theme.dart';
import 'session_prep_screen.dart';

class CustomScenarioScreen extends StatefulWidget {
  const CustomScenarioScreen({super.key});

  @override
  State<CustomScenarioScreen> createState() => _CustomScenarioScreenState();
}

class _CustomScenarioScreenState extends State<CustomScenarioScreen> {
  int _step = 0;
  String _selectedGoal = 'Give feedback';
  final TextEditingController _contextController = TextEditingController(
    text:
        'Alex was my former peer. He missed two deadlines this week and gets defensive in 1-on-1s.',
  );
  bool _isGenerating = false;

  // Selected Counterpart Archetype
  String _selectedPersonaId = 'alex';

  // Selected Tensions
  final Set<String> _selectedTensions = {'Missed Deadlines', 'Defensiveness'};

  final List<String> _allTensions = [
    'Missed Deadlines',
    'Scope Pushback',
    'Defensiveness',
    'Compensation',
    'Role Boundaries',
    'Feedback Resistance',
  ];

  @override
  void dispose() {
    _contextController.dispose();
    super.dispose();
  }

  Persona _getSelectedPersona() {
    return Persona.defaultPersonas.firstWhere(
      (p) => p.id == _selectedPersonaId,
      orElse: () => Persona.defaultPersonas.first,
    );
  }

  void _submitScenario() => _generateScenarioWithAi();

  void _generateScenarioWithAi() async {
    final note = _contextController.text.trim();
    setState(() => _isGenerating = true);

    try {
      final result = await BackendService.request('/api/scenarios/generate', {
        'description': note,
        'goal': _selectedGoal,
        'tensions': _selectedTensions.toList(),
        'personaHint': _selectedPersonaId,
      });

      final difficulty = switch (result['difficulty']) {
        'beginner' => ScenarioDifficulty.beginner,
        'advanced' => ScenarioDifficulty.advanced,
        _ => ScenarioDifficulty.intermediate,
      };
      const defensivenessByDifficulty = {
        ScenarioDifficulty.beginner: 40,
        ScenarioDifficulty.intermediate: 60,
        ScenarioDifficulty.advanced: 80,
      };
      final persona = Persona(
        id: 'custom_persona_${DateTime.now().millisecondsSinceEpoch}',
        name: result['name'] as String,
        role: result['role'] as String,
        company: result['company'] as String,
        avatarAsset: result['avatarAsset'] as String,
        callBackgroundAsset: 'assets/avatars/alex_call.jpg',
        bio: result['bio'] as String,
        personalityTraits: result['personalityTraits'] as String,
        baselineDefensiveness: defensivenessByDifficulty[difficulty]!,
        pushbackPhrases: List<String>.from(result['pushbackPhrases'] as List),
        yieldingPhrases: const [],
        voiceStyle: 'Natural, conversational',
        geminiVoiceName: result['geminiVoiceName'] as String,
        geminiAvatarName: result['name'] as String,
        tavusReplicaId: result['tavusReplicaId'] as String,
      );

      final customScenario = Scenario(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        title: result['title'] as String,
        subtitle: result['subtitle'] as String,
        category: 'Custom Practice',
        difficulty: difficulty,
        persona: persona,
        userPersona: Scenario.userPersonaFor(persona),
        contextBrief: result['contextBrief'] as String,
        userObjectives: List<String>.from(result['userObjectives'] as List),
        trapPhrasesToAvoid: List<String>.from(
          result['trapPhrasesToAvoid'] as List,
        ),
      );

      if (!mounted) return;
      setState(() => _isGenerating = false);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SessionPrepScreen(scenario: customScenario),
        ),
      );
    } on BackendException catch (e) {
      if (!mounted) return;
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: const Color(0xFFFF8A43),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scenario generation returned an invalid result. Please retry.'),
          backgroundColor: Color(0xFFFF8A43),
        ),
      );
    }
  }

  void _nextStep() {
    if (_step < 2) setState(() => _step++);
  }

  void _previousStep() {
    if (_step == 0) {
      Navigator.pop(context);
    } else {
      setState(() => _step--);
    }
  }

  Widget _buildWizard(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 18, 6),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _previousStep,
                        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Create your scenario',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1B1715),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: List.generate(3, (index) {
                                return Expanded(
                                  child: Container(
                                    height: 5,
                                    margin: EdgeInsets.only(
                                      right: index == 2 ? 0 : 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: index <= _step
                                          ? const Color(0xFF7C5CE7)
                                          : const Color(0xFFE5E0EC),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_step + 1}/3',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF7A726C),
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
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      child: _wizardStep(context),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFAF7F2),
                    border: Border(top: BorderSide(color: Color(0xFFEDE8DE))),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF7C5CE7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                      ),
                      onPressed: _isGenerating
                          ? null
                          : _step == 2
                          ? _submitScenario
                          : _nextStep,
                      child: _isGenerating
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _step == 2
                                  ? 'Generate with AI'
                                  : 'Continue',
                            ),
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

  Widget _wizardStep(BuildContext context) {
    switch (_step) {
      case 0:
        return _situationStep(context);
      case 1:
        return _personaStep(context);
      default:
        return _reviewStep(context);
    }
  }

  Widget _wizardHeading(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: GoogleFonts.newsreader(
          fontSize: 29,
          height: 1.05,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF17182B),
        ),
      ),
      const SizedBox(height: 7),
      Text(
        subtitle,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13.5,
          height: 1.45,
          color: const Color(0xFF565B76),
        ),
      ),
    ],
  );

  Widget _situationStep(BuildContext context) {
    const goals = [
      'Give feedback',
      'Handle conflict',
      'Set expectations',
      'Build trust',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _wizardHeading(
          'Define the situation',
          'Describe what is happening, and AI will turn it into a full practice scenario.',
        ),
        const SizedBox(height: 16),
        Container(
          height: 165,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0E3),
            borderRadius: BorderRadius.circular(26),
          ),
          child: const AppIllustration(
            HardSyncAssets.illusToughFeedbackMoment,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'What’s the situation?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 9),
        _buildContextInput(),
        const SizedBox(height: 18),
        Text(
          'What’s your goal? (optional)',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: goals
              .map(
                (goal) => ChoiceChip(
                  label: Text(goal),
                  selected: _selectedGoal == goal,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _selectedGoal = goal),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 18),
        Text(
          'What is creating friction? (optional)',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 9),
        _buildFrictionChips(),
      ],
    );
  }

  Widget _personaStep(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _wizardHeading(
        'Choose your conversation partner (optional)',
        'Pick who best matches the real conversation, or leave this and AI will choose based on your description.',
      ),
      const SizedBox(height: 16),
      Container(
        height: 210,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF1EDFF),
          borderRadius: BorderRadius.circular(28),
        ),
        child: const AppIllustration(HardSyncAssets.illusPersonaSelector),
      ),
      const SizedBox(height: 18),
      _buildCounterpartArchetypes(),
      const SizedBox(height: 18),
      _buildInsightCard(),
    ],
  );

  Widget _reviewStep(BuildContext context) {
    final persona = _getSelectedPersona();
    final contextText = _contextController.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _wizardHeading(
          'Review your scenario',
          'Check the details before choosing text, voice, or video practice.',
        ),
        const SizedBox(height: 16),
        Container(
          height: 190,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF1EDFF),
            borderRadius: BorderRadius.circular(28),
          ),
          child: const AppIllustration(HardSyncAssets.illusSafeRehearsalRoom),
        ),
        const SizedBox(height: 14),
        _reviewCard(
          'Conversation partner',
          '${persona.name} · ${persona.role}',
          HardSyncAssets.illusPersonaSelector,
          () => setState(() => _step = 1),
        ),
        const SizedBox(height: 10),
        _reviewCard(
          'Your goal',
          _selectedGoal,
          HardSyncAssets.iconTargetBullseye,
          () => setState(() => _step = 0),
        ),
        const SizedBox(height: 10),
        _reviewCard(
          'Situation',
          contextText.isEmpty ? _selectedTensions.join(', ') : contextText,
          HardSyncAssets.illusConversationBlueprint,
          () => setState(() => _step = 0),
        ),
        const SizedBox(height: 10),
        _reviewCard(
          'Difficulty',
          'Intermediate · adjustable on the next screen',
          HardSyncAssets.illusClarityMeter,
          () {},
        ),
      ],
    );
  }

  Widget _reviewCard(
    String label,
    String value,
    String asset,
    VoidCallback onEdit,
  ) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE2DDE8)),
    ),
    child: Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFFF1EDFF),
            borderRadius: BorderRadius.circular(15),
          ),
          child: AppIllustration(asset),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 9.5,
                  letterSpacing: .7,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF7C5CE7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        TextButton(onPressed: onEdit, child: const Text('Edit')),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => _buildWizard(context);

  // Kept temporarily while the guided builder replaces the original dense form.
  // ignore: unused_element
  Widget _legacyBuild(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              children: [
                // Top Navigation
                _buildTopNav(context),

                // Main Scrollable Area
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Text(
                          'Configure Scenario',
                          style: GoogleFonts.newsreader(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1B1715),
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose your counterpart relationship and the tension you want to practice.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: const Color(0xFF7A726C),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Section 1: Who are you meeting with?
                        Text(
                          '1. WHO ARE YOU MEETING WITH?',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: const Color(0xFF1B1715),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildCounterpartArchetypes(),
                        const SizedBox(height: 22),

                        // Section 2: Core friction
                        Text(
                          '2. WHAT IS THE CORE FRICTION?',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: const Color(0xFF1B1715),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildFrictionChips(),
                        const SizedBox(height: 22),

                        // Section 3: Context Note
                        Text(
                          '3. KEY CONTEXT (OPTIONAL)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: const Color(0xFF1B1715),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildContextInput(),
                        const SizedBox(height: 20),

                        // Briefing Insight Card
                        _buildInsightCard(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Bottom Action CTA
                _buildBottomCTA(),
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
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: Color(0xFF1B1715),
            ),
            tooltip: 'Go back',
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEBE5DB),
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Row(
              children: [
                const AppIcon(HardSyncAssets.iconSparkleStarsMagic, size: 14),
                const SizedBox(width: 6),
                Text(
                  'Custom Scenario',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF224838),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterpartArchetypes() {
    final archetypes = [
      {
        'id': 'marcus',
        'name': 'Marcus',
        'role': 'Direct Report',
        'avatar': HardSyncAssets.avatarMarcus,
        'bg': const Color(0xFFEBF2EE),
      },
      {
        'id': 'alex',
        'name': 'Alex',
        'role': 'Former Peer',
        'avatar': HardSyncAssets.avatarAlex,
        'bg': const Color(0xFFF3ECE0),
      },
      {
        'id': 'jordan',
        'name': 'Jordan',
        'role': 'VP Exec',
        'avatar': HardSyncAssets.avatarJordan,
        'bg': const Color(0xFFF5EDE4),
      },
    ];

    return Row(
      children: archetypes.map((arch) {
        final id = arch['id'] as String;
        final isSelected = _selectedPersonaId == id;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => setState(() => _selectedPersonaId = id),
              borderRadius: BorderRadius.circular(18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? HardSyncColors.lilacMist : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected
                        ? HardSyncColors.violet
                        : const Color(0xFFE5DFD5),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isSelected ? 0.05 : 0.02,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    AppAvatar(
                      arch['avatar'] as String,
                      size: 54,
                      backgroundColor: arch['bg'] as Color,
                      borderColor: isSelected
                          ? HardSyncColors.violet
                          : HardSyncColors.lilacBorder,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      arch['name'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? HardSyncColors.violet
                            : const Color(0xFF1B1715),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      arch['role'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected
                            ? HardSyncColors.violet.withValues(alpha: 0.8)
                            : const Color(0xFF7A726C),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFrictionChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _allTensions.map((tension) {
        final isSelected = _selectedTensions.contains(tension);

        return InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedTensions.remove(tension);
              } else {
                _selectedTensions.add(tension);
              }
            });
          },
          borderRadius: BorderRadius.circular(9999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF224838) : Colors.white,
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF224838)
                    : const Color(0xFFDFD9CD),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              tension,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF2C3831),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContextInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5DFD5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: _contextController,
        maxLines: 3,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13.5,
          color: const Color(0xFF1B1715),
          height: 1.45,
        ),
        decoration: InputDecoration(
          hintText: 'Add specific nuance, past history, or talking points...',
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF9E968D),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildInsightCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3ECE0).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5DDD0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFE7DEC8),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const AppIcon(HardSyncAssets.iconLightbulbIdea, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'HardSync calibrates the counterpart’s baseline defensiveness and pushback style based on your selected relationship dynamics.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF5A524A),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCTA() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFFAF7F2),
        border: Border(top: BorderSide(color: Color(0xFFEDE8DE))),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF224838),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: _isGenerating ? null : _generateScenarioWithAi,
          child: _isGenerating
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AppIcon(HardSyncAssets.iconRocketLaunch, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Generate Scenario',
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
    );
  }
}
