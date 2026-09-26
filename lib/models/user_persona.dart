class UserPersona {
  final String id;
  final String title;
  final String level;
  final String roleSummary;
  final String coreStakes;
  final String iconEmoji;
  final String defaultTrapHedging;
  final String executiveStandard;

  const UserPersona({
    required this.id,
    required this.title,
    required this.level,
    required this.roleSummary,
    required this.coreStakes,
    required this.iconEmoji,
    required this.defaultTrapHedging,
    required this.executiveStandard,
  });

  static List<UserPersona> get defaultPersonas => const [
    UserPersona(
      id: 'eng_lead',
      title: 'Engineering Team Lead',
      level: 'Mid-Level Management',
      roleSummary:
          'Recently promoted lead transitioning from peer engineer to manager.',
      coreStakes:
          'Defending sprint delivery dates while transitioning from informal friendship to executive accountability.',
      iconEmoji: '💻',
      defaultTrapHedging:
          "I'm sorry to have to ask this of you, but management wants...",
      executiveStandard:
          'Direct, composed, non-apologetic boundary setting with transparent business impact.',
    ),
    UserPersona(
      id: 'product_director',
      title: 'Director of Product',
      level: 'Senior Leadership',
      roleSummary:
          'Shielding engineering velocity from aggressive executive scope creep.',
      coreStakes:
          'Holding product roadmap integrity against last-minute C-suite urgency without damaging executive rapport.',
      iconEmoji: '🧭',
      defaultTrapHedging:
          'We can try to squeeze in a couple of slides over the weekend...',
      executiveStandard:
          'Grounding in data, offering strategic trade-offs, and protecting team burnout boundaries.',
    ),
    UserPersona(
      id: 'startup_founder',
      title: 'Startup Founder & CEO',
      level: 'Executive / Board Level',
      roleSummary: 'Leading high-stakes partner, investor, and team alignment.',
      coreStakes:
          'Maintaining company strategic focus, managing runway, and holding enterprise commercial boundaries.',
      iconEmoji: '🚀',
      defaultTrapHedging:
          'Maybe we can accommodate that discount if we change terms...',
      executiveStandard:
          'Uncompromising conviction, clear value proposition, and calm high-stakes negotiation.',
    ),
    UserPersona(
      id: 'staff_architect',
      title: 'Staff Systems Architect',
      level: 'Principal IC Leadership',
      roleSummary:
          'Technical authority pushing back on architectural shortcuts and on-call burnout.',
      coreStakes:
          'Preventing catastrophic technical debt while maintaining trust with impatient product stakeholders.',
      iconEmoji: '⚡',
      defaultTrapHedging:
          'I guess if we skip integration tests we could deploy earlier...',
      executiveStandard:
          'Unwavering technical integrity, quantifiable risk explanation, and structured trade-offs.',
    ),
    UserPersona(
      id: 'people_partner',
      title: 'People Partner / HR Lead',
      level: 'People Leadership',
      roleSummary:
          'Delivering corrective feedback and navigating sensitive organizational transitions.',
      coreStakes:
          'Providing radical candor with high psychological safety to defensive or struggling team members.',
      iconEmoji: '🤝',
      defaultTrapHedging:
          'Don\'t take this the wrong way, but people were talking...',
      executiveStandard:
          'Objective evidence-based feedback, deep empathy, and clear forward expectations.',
    ),
  ];
}
