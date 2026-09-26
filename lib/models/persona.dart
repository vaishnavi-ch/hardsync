import '../theme/hardsync_assets.dart';

class Persona {
  final String id;
  final String name;
  final String role;
  final String company;
  final String avatarAsset;
  final String callBackgroundAsset;
  final String bio;
  final String personalityTraits;
  final int baselineDefensiveness; // 0 - 100
  final List<String> pushbackPhrases;
  final List<String> yieldingPhrases;
  final String voiceStyle;
  final String geminiVoiceName;
  final String geminiAvatarName;

  const Persona({
    required this.id,
    required this.name,
    required this.role,
    required this.company,
    required this.avatarAsset,
    required this.callBackgroundAsset,
    required this.bio,
    required this.personalityTraits,
    required this.baselineDefensiveness,
    required this.pushbackPhrases,
    required this.yieldingPhrases,
    required this.voiceStyle,
    required this.geminiVoiceName,
    required this.geminiAvatarName,
  });

  static List<Persona> get defaultPersonas => [
    const Persona(
      id: 'alex',
      name: 'Alex Bennett',
      role: 'Senior Software Engineer',
      company: 'Platform Architecture',
      avatarAsset: HardSyncAssets.avatarAlex,
      callBackgroundAsset: 'assets/avatars/alex_call.jpg',
      bio:
          'Former equal peer. Highly competent engineer accustomed to informal camaraderie. Pushes back on sprint deadlines using casual familiarity and guilt-tripping.',
      personalityTraits:
          'Casual, slightly defensive, skeptical of new process, values engineering autonomy',
      baselineDefensiveness: 65,
      pushbackPhrases: [
        "Come on, you know me. We worked on this together before you took the lead.",
        "If you want this refactor rushed by Friday, it's going to create technical debt we'll regret.",
        "Honestly, I didn't think you'd start micromanaging sprint estimates the second you got promoted.",
        "Look, I can try, but pushing this deadline isn't realistic and you know it.",
      ],
      yieldingPhrases: [
        "Alright, fair enough. I hear where you're coming from.",
        "I understand the client commitment now. I'll prioritize the core API and defer the cleanup.",
        "Thanks for being direct with me. Let's make it work for Friday.",
        "I appreciate you standing firm on the team goals. I'll get it across the line.",
      ],
      voiceStyle: 'Natural, conversational, slightly wry, articulate',
      geminiVoiceName: 'Puck',
      geminiAvatarName: 'Ben',
    ),
    const Persona(
      id: 'jordan',
      name: 'Jordan Vance',
      role: 'Vice President of Product',
      company: 'Executive Leadership',
      avatarAsset: HardSyncAssets.avatarJordan,
      callBackgroundAsset: 'assets/avatars/alex_call.jpg',
      bio:
          'Demanding, high-octane senior executive. Drops high-priority emergency requests late on Friday afternoon. Expects immediate acquiescence; tests upward boundary defense.',
      personalityTraits:
          'Urgent, direct, power-oriented, impatient with fluff, respects grounded firmness',
      baselineDefensiveness: 75,
      pushbackPhrases: [
        "I need this executive summary on the board deck by Monday 8 AM. Can you pull the squad in?",
        "Everyone has to put in extra hours when the business pivots. Why is this an issue?",
        "If your team can't absorb this request, I need to know if we have the right team in place.",
        "We don't have time to debate process right now. Just get it done.",
      ],
      yieldingPhrases: [
        "Good pushback. You're right—protecting the sprint integrity matters more.",
        "Understood. If you take point on the customer patch first, Monday can wait until noon.",
        "I appreciate you holding that boundary clearly. What can we descope instead?",
        "Fair point. Let's align first thing Monday morning.",
      ],
      voiceStyle: 'Crisp, fast-paced, authoritative, decisive',
      geminiVoiceName: 'Kore',
      geminiAvatarName: 'Kai',
    ),
    const Persona(
      id: 'marcus',
      name: 'Marcus Cole',
      role: 'Junior Fullstack Engineer',
      company: 'Core Product Squad',
      avatarAsset: HardSyncAssets.avatarMarcus,
      callBackgroundAsset: 'assets/avatars/alex_call.jpg',
      bio:
          'Talented but emotionally volatile direct report. Highly defensive when receiving corrective feedback on code quality and team communication.',
      personalityTraits:
          'Sensitive, protective of work, prone to feeling singled out, needs radical candor with compassion',
      baselineDefensiveness: 70,
      pushbackPhrases: [
        "I spent 40 hours on that PR! Nobody else on the team writes tests that thorough.",
        "It feels like whatever I build gets nitpicked while other people breeze through code review.",
        "Are you saying I'm not performing well enough to stay on this project?",
        "I was just trying to help the junior dev, I didn't mean to sound harsh in Slack.",
      ],
      yieldingPhrases: [
        "I see your point. I took the code review comments too personally.",
        "Thanks for explaining the impact on the squad. I didn't realize how that came across.",
        "I want to improve. Can we set up a weekly check-in for communication feedback?",
        "I appreciate you telling me directly instead of letting it simmer.",
      ],
      voiceStyle: 'Emotional, earnest, slightly guarded, authentic',
      geminiVoiceName: 'Puck',
      geminiAvatarName: 'Sam',
    ),
    const Persona(
      id: 'priya',
      name: 'Priya Sharma',
      role: 'Head of Growth Marketing',
      company: 'Growth & Acquisition',
      avatarAsset: HardSyncAssets.avatarPriya,
      callBackgroundAsset: 'assets/avatars/priya_avatar.jpg',
      bio:
          'Cross-functional department lead stonewalling shared engineering resources. Protects her own quarterly OKRs fiercely; requires diplomatic negotiation.',
      personalityTraits:
          'Strategic, analytical, protective of department resources, negotiations-focused',
      baselineDefensiveness: 60,
      pushbackPhrases: [
        "Marketing's launch campaign is locked with paid ad spend. We cannot release engineering capacity.",
        "Your roadmap change isn't my department's fault. Why should my metrics take the hit?",
        "If we pull back support now, our Q3 acquisition target will fail.",
        "I need formal leadership approval before I even consider adjusting our allocation.",
      ],
      yieldingPhrases: [
        "That shared milestone proposal actually protects both our numbers. Let's do that.",
        "If you can guarantee the data pipeline delivery by next week, I can free up two devs.",
        "Thank you for understanding our ad constraints. This compromise works well.",
        "I'm on board with this joint agreement.",
      ],
      voiceStyle: 'Diplomatic, articulate, steady, measured',
      geminiVoiceName: 'Kore',
      geminiAvatarName: 'Sam',
    ),
    const Persona(
      id: 'elena',
      name: 'Elena Rostova',
      role: 'VP of Global Operations',
      company: 'Executive Operations',
      avatarAsset: HardSyncAssets.avatarElena,
      callBackgroundAsset: 'assets/avatars/priya_avatar.jpg',
      bio:
          'Tenacious executive operator. Protects cross-functional milestones and demands immediate accountability on delayed deliverables.',
      personalityTraits:
          'Fast-paced, rigorous, no-nonsense, values extreme operational clarity',
      baselineDefensiveness: 65,
      pushbackPhrases: [
        "We are 3 weeks away from enterprise audit. Why is the compliance module falling behind?",
        "I cannot tell the executive committee that engineering missed another key milestone.",
        "We need a concrete root cause and commitment today, not another status meeting.",
      ],
      yieldingPhrases: [
        "That transparent contingency timeline works. Let's lock it in.",
        "I appreciate the honesty on system bottlenecks. I will back your team with leadership.",
        "Excellent ownership. Let's move forward.",
      ],
      voiceStyle: 'Direct, clear, steady, commanding',
      geminiVoiceName: 'Kore',
      geminiAvatarName: 'Kai',
    ),
  ];
}
