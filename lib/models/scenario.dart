import 'persona.dart';
import 'user_persona.dart';
import '../theme/hardsync_assets.dart';

enum ScenarioDifficulty { beginner, intermediate, advanced }

class Scenario {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final ScenarioDifficulty difficulty;
  final Persona persona;
  final UserPersona userPersona;
  final String contextBrief;
  final List<String> userObjectives;
  final List<String> trapPhrasesToAvoid;
  final int targetWpmMin;
  final int targetWpmMax;
  final int maxAllowableFillers;

  const Scenario({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.difficulty,
    required this.persona,
    required this.userPersona,
    required this.contextBrief,
    required this.userObjectives,
    required this.trapPhrasesToAvoid,
    this.targetWpmMin = 120,
    this.targetWpmMax = 150,
    this.maxAllowableFillers = 3,
  });

  Scenario copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? category,
    ScenarioDifficulty? difficulty,
    Persona? persona,
    UserPersona? userPersona,
    String? contextBrief,
    List<String>? userObjectives,
    List<String>? trapPhrasesToAvoid,
    int? targetWpmMin,
    int? targetWpmMax,
    int? maxAllowableFillers,
  }) {
    return Scenario(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      persona: persona ?? this.persona,
      userPersona: userPersona ?? this.userPersona,
      contextBrief: contextBrief ?? this.contextBrief,
      userObjectives: userObjectives ?? this.userObjectives,
      trapPhrasesToAvoid: trapPhrasesToAvoid ?? this.trapPhrasesToAvoid,
      targetWpmMin: targetWpmMin ?? this.targetWpmMin,
      targetWpmMax: targetWpmMax ?? this.targetWpmMax,
      maxAllowableFillers: maxAllowableFillers ?? this.maxAllowableFillers,
    );
  }

  String get difficultyLabel {
    switch (difficulty) {
      case ScenarioDifficulty.beginner:
        return 'Beginner';
      case ScenarioDifficulty.intermediate:
        return 'Intermediate';
      case ScenarioDifficulty.advanced:
        return 'Advanced';
    }
  }

  static List<Scenario> get defaultScenarios {
    final personas = Persona.defaultPersonas;
    final roles = UserPersona.defaultPersonas;
    final alex = personas.firstWhere((p) => p.id == 'alex');
    final jordan = personas.firstWhere((p) => p.id == 'jordan');
    final marcus = personas.firstWhere((p) => p.id == 'marcus');
    final priya = personas.firstWhere((p) => p.id == 'priya');
    final elena = personas.firstWhere((p) => p.id == 'elena');
    final sam = personas.firstWhere((p) => p.id == 'sam');
    final grace = personas.firstWhere((p) => p.id == 'grace');
    final omar = personas.firstWhere((p) => p.id == 'omar');
    final nina = personas.firstWhere((p) => p.id == 'nina');
    final david = personas.firstWhere((p) => p.id == 'david');
    final engineeringLead = roles.firstWhere((p) => p.id == 'eng_lead');
    final peoplePartner = roles.firstWhere((p) => p.id == 'people_partner');
    final staffArchitect = roles.firstWhere((p) => p.id == 'staff_architect');

    return [
      Scenario(
        id: 'practice_more_clear_request',
        title: 'Confirm an Action with a Teammate',
        subtitle: 'Agree who will send an update and when',
        category: 'Communication Basics',
        difficulty: ScenarioDifficulty.beginner,
        persona: priya,
        userPersona: engineeringLead,
        contextBrief: 'In a one-to-one check-in, a teammate is unsure who will send the customer update. Clarify the action, owner, deadline, and when you will check progress together.',
        userObjectives: ['State the decision needed.', 'Invite corrections to your understanding.', 'Confirm one owner and a time to follow up.'],
        trapPhrasesToAvoid: [],
      ),
      Scenario(
        id: 'practice_listening_another_view',
        title: 'Hear a Different View',
        subtitle: 'Find out what matters before responding',
        category: 'Listening',
        difficulty: ScenarioDifficulty.beginner,
        persona: grace,
        userPersona: engineeringLead,
        contextBrief: 'A colleague disagrees with your proposed order for two tasks. Ask what they are concerned about and summarize their view before comparing options.',
        userObjectives: ['Ask an open question.', 'Summarize their concern in neutral language.', 'Check that you understood before responding.'],
        trapPhrasesToAvoid: [],
      ),
      Scenario(
        id: 'practice_feedback_followup',
        title: 'Follow Up on a Feedback Conversation',
        subtitle: 'Check whether the agreed change is working',
        category: 'Feedback',
        difficulty: ScenarioDifficulty.intermediate,
        persona: david,
        userPersona: engineeringLead,
        contextBrief: 'You agreed with a teammate to include acceptance details earlier in handoffs. A week later, check what has changed, recognize progress, and ask whether anything is still getting in the way.',
        userObjectives: ['Name the action you agreed to review.', 'Ask for the teammate’s view.', 'Agree any next support or adjustment.'],
        trapPhrasesToAvoid: [],
      ),
      Scenario(
        id: 'practice_boundary_scope',
        title: 'Respond to Added Work',
        subtitle: 'Explain what can fit and what needs to move',
        category: 'Workload and Boundaries',
        difficulty: ScenarioDifficulty.intermediate,
        persona: omar,
        userPersona: engineeringLead,
        contextBrief: 'A stakeholder adds a reporting request to work already committed for the sprint. Discuss the customer need, team capacity, and which existing task could move if the new request is a priority.',
        userObjectives: ['Understand why the added work matters.', 'State the capacity constraint plainly.', 'Offer clear options for changing the plan.'],
        trapPhrasesToAvoid: [],
      ),
      Scenario(
        id: 'practice_conflict_customer_quality',
        title: 'Discuss Speed and Quality',
        subtitle: 'Understand a teammate’s concerns about a release',
        category: 'Conflict and Alignment',
        difficulty: ScenarioDifficulty.intermediate,
        persona: sam,
        userPersona: staffArchitect,
        contextBrief: 'A teammate wants to ship a small fix today. You believe it needs another day of checks after a recent incident. Hear their reason, explain the risk, and agree how to decide.',
        userObjectives: ['Hear your teammate’s reason.', 'Explain the quality risk clearly.', 'Agree on a decision or review point.'],
        trapPhrasesToAvoid: [],
      ),
      Scenario(
        id: 'practice_delegate_checkin',
        title: 'Check In on a Delegated Task',
        subtitle: 'Support progress without taking the task back',
        category: 'Delegation',
        difficulty: ScenarioDifficulty.intermediate,
        persona: nina,
        userPersona: engineeringLead,
        contextBrief: 'A teammate you asked to lead a readiness check says they are unsure whether a new issue is theirs to resolve. Clarify their decision space, ask what they recommend, and offer support.',
        userObjectives: ['Restate the outcome and decision limits.', 'Ask what the teammate has considered.', 'Agree what they own and when to reconnect.'],
        trapPhrasesToAvoid: [],
      ),
      Scenario(
        id: 'practice_change_senior',
        title: 'Explain a Change to Senior Leaders',
        subtitle: 'Share what is known, uncertain, and needed next',
        category: 'Leading Change',
        difficulty: ScenarioDifficulty.advanced,
        persona: elena,
        userPersona: roles.firstWhere((p) => p.id == 'product_director'),
        contextBrief: 'Senior leaders ask how a team will respond to a new market requirement. Some delivery details are still uncertain. Explain the current plan, assumptions, risks, and the next decision date.',
        userObjectives: ['Lead with the current recommendation.', 'Label uncertain information clearly.', 'Name the decision or update needed next.'],
        trapPhrasesToAvoid: [],
      ),
      Scenario(
        id: 'practice_senior_disagreement',
        title: 'Discuss a Different Launch Date with a VP',
        subtitle: 'Explain the trade-offs behind your recommendation',
        category: 'Managing Up',
        difficulty: ScenarioDifficulty.advanced,
        persona: elena,
        userPersona: roles.firstWhere((p) => p.id == 'product_director'),
        contextBrief: 'A VP prefers a launch date that you believe creates a delivery risk. Explain what you understand about the business need, share your evidence, and discuss a workable alternative.',
        userObjectives: ['Confirm the goal the date supports.', 'Explain the delivery risk and evidence.', 'Offer an alternative and ask how they want to proceed.'],
        trapPhrasesToAvoid: [],
      ),
      Scenario(
        id: 'practice_repair_meeting',
        title: 'Repair After a Tense One-to-One',
        subtitle: 'Acknowledge your part and reopen the conversation',
        category: 'Repair and Reflection',
        difficulty: ScenarioDifficulty.intermediate,
        persona: alex,
        userPersona: engineeringLead,
        contextBrief: 'You cut off a teammate during a tense one-to-one and dismissed one of their concerns. In a follow-up, acknowledge what you did, ask what impact it had, and agree how to continue the work.',
        userObjectives: ['Name your specific action without excuses.', 'Listen to the other person’s view.', 'Agree what would help the work move forward.'],
        trapPhrasesToAvoid: [],
      ),
      Scenario(
        id: 'practice_update_priority',
        title: 'Agree on a Project Update',
        subtitle: 'Clarify the next update after priorities change',
        category: 'Communication Basics',
        difficulty: ScenarioDifficulty.beginner,
        persona: omar,
        userPersona: engineeringLead,
        contextBrief: 'A partner team has changed its priorities and the shared project update is now unclear. Agree what needs to be communicated, who owns it, and when it will be sent.',
        userObjectives: ['Clarify the outcome the other team needs.', 'Make one clear request.', 'Confirm the owner and timing for the next update.'],
        trapPhrasesToAvoid: ['You need to communicate better.', 'I thought you were handling it.'],
      ),
      Scenario(
        id: 'practice_team_one_to_one',
        title: 'A Teammate Seems Stuck',
        subtitle: 'Listen and help them choose a next step',
        category: 'One-to-Ones',
        difficulty: ScenarioDifficulty.beginner,
        persona: nina,
        userPersona: engineeringLead,
        contextBrief: 'In a one-to-one, a teammate says they have been blocked for several days but gives few details. Explore what is happening and what support they want before taking over the work.',
        userObjectives: ['Ask what is getting in the way.', 'Reflect what you heard and check it.', 'Agree one next step and the support they want.'],
        trapPhrasesToAvoid: ['Just do it this way.', 'Why did you wait so long?'],
      ),
      Scenario(
        id: 'practice_feedback_missed_handoff',
        title: 'Feedback After a Missed Handoff',
        subtitle: 'Describe the behavior and its effect fairly',
        category: 'Feedback',
        difficulty: ScenarioDifficulty.beginner,
        persona: alex,
        userPersona: engineeringLead,
        contextBrief: 'A recent handoff missed important acceptance details and another teammate had to redo part of the work. Discuss the specific event, hear what happened, and agree how to prevent a repeat.',
        userObjectives: ['Describe the event without labeling the person.', 'Explain the effect on the work.', 'Hear their view and agree a practical next step.'],
        trapPhrasesToAvoid: ['You are careless.', 'You always leave things out.'],
      ),
      Scenario(
        id: 'practice_say_no_peer',
        title: 'Say No to an Extra Request',
        subtitle: 'Protect your priorities and offer a choice',
        category: 'Workload and Boundaries',
        difficulty: ScenarioDifficulty.intermediate,
        persona: sam,
        userPersona: engineeringLead,
        contextBrief: 'A colleague asks you to take on an urgent task, but doing so would put an agreed team commitment at risk. Explain the constraint and explore what can move.',
        userObjectives: ['Acknowledge why the request matters.', 'Explain the capacity or priority limit.', 'Offer realistic choices and agree what to do.'],
        trapPhrasesToAvoid: ['Fine, I will do both.', 'That is not my problem.'],
      ),
      Scenario(
        id: 'practice_conflict_priority',
        title: 'Discuss Competing Priorities with a Partner',
        subtitle: 'Understand the need behind a different request',
        category: 'Conflict and Alignment',
        difficulty: ScenarioDifficulty.intermediate,
        persona: priya,
        userPersona: staffArchitect,
        contextBrief: 'A partner asks to use the same specialist you had planned to rely on next week. Their need is tied to a customer launch; yours is tied to a security review. Discuss the competing needs and agree an option or who should decide.',
        userObjectives: ['Ask why the request matters to them.', 'Explain your own priority and its impact.', 'Compare options and agree the next decision step.'],
        trapPhrasesToAvoid: ['My team should come first.', 'Let us just split the time equally.'],
      ),
      Scenario(
        id: 'practice_manage_up_scope',
        title: 'Raise a Scope Risk Early',
        subtitle: 'Give a senior colleague options before a deadline slips',
        category: 'Managing Up',
        difficulty: ScenarioDifficulty.intermediate,
        persona: elena,
        userPersona: engineeringLead,
        contextBrief: 'A senior colleague has added work to a release without changing its date. Your estimate shows that keeping all scope will leave too little time for testing. Explain the evidence and recommend a trade-off.',
        userObjectives: ['Start with the shared goal.', 'Separate known facts from estimates.', 'Recommend an option and ask for a decision.'],
        trapPhrasesToAvoid: ['This will never work.', 'I will just tell the team to stay late.'],
      ),
      Scenario(
        id: 'practice_change_uncertainty',
        title: 'Guide a Team Through a Change',
        subtitle: 'Explain what is known and listen to concerns',
        category: 'Leading Change',
        difficulty: ScenarioDifficulty.advanced,
        persona: marcus,
        userPersona: roles.firstWhere((p) => p.id == 'product_director'),
        contextBrief: 'Your organization is changing how teams plan work, but some details are still undecided. A team member is worried the change will disrupt delivery. Be honest about what is known, hear the concern, and identify the next useful check-in.',
        userObjectives: ['Say what is decided and what is still unknown.', 'Invite the person’s concern and reflect it accurately.', 'Agree what information or support comes next.'],
        trapPhrasesToAvoid: ['Nothing will change.', 'There is no point worrying about it.'],
      ),
      Scenario(
        id: 'practice_clear_update',
        title: 'Give a Clear Project Update',
        subtitle: 'Share the status, risk, and owner in a short update',
        category: 'Communication Basics',
        difficulty: ScenarioDifficulty.beginner,
        persona: omar,
        userPersona: engineeringLead,
        contextBrief: 'A partner asks where a shared task stands. One part is done, one is delayed, and the owner of the next step is unclear. Give an accurate short update and confirm what happens next.',
        userObjectives: ['State what is done and what is still open.', 'Name the effect of the delay without blame.', 'Agree the next owner and update time.'],
        trapPhrasesToAvoid: ['Everything is fine.', 'They are holding us up.'],
      ),
      Scenario(
        id: 'practice_listening_change',
        title: 'Hear a Concern About a New Plan',
        subtitle: 'Ask, reflect, and check before responding',
        category: 'Listening',
        difficulty: ScenarioDifficulty.beginner,
        persona: alex,
        userPersona: engineeringLead,
        contextBrief: 'A teammate says a new planning process will slow the team down. Ask what specifically worries them and check your understanding before explaining the reasons for the change.',
        userObjectives: ['Ask an open question.', 'Reflect the specific concern in neutral language.', 'Ask what information or support would help.'],
        trapPhrasesToAvoid: ['You just need to give it a chance.', 'That is not what the process says.'],
      ),
      Scenario(
        id: 'practice_feedback_positive',
        title: 'Recognize Helpful Work',
        subtitle: 'Give specific appreciation that can be repeated',
        category: 'Feedback',
        difficulty: ScenarioDifficulty.beginner,
        persona: nina,
        userPersona: engineeringLead,
        contextBrief: 'A teammate noticed a confusing handoff and wrote a checklist that reduced rework in your work together. Recognize what they did and why it helped, then hear their view.',
        userObjectives: ['Name the specific action.', 'Explain its positive effect.', 'Ask what helped them take that action.'],
        trapPhrasesToAvoid: ['You are a superstar.', 'Keep doing great work.'],
      ),
      Scenario(
        id: 'practice_boundary_timeline',
        title: 'Renegotiate a Deadline',
        subtitle: 'Be clear about what can be delivered safely',
        category: 'Workload and Boundaries',
        difficulty: ScenarioDifficulty.intermediate,
        persona: jordan,
        userPersona: engineeringLead,
        contextBrief: 'A stakeholder asks for a full feature by Friday. A smaller version is possible by then, but the full version needs another week of testing. Explain the options and ask which outcome matters most.',
        userObjectives: ['Acknowledge the deadline need.', 'Explain the limit and why it matters.', 'Offer two realistic delivery choices.'],
        trapPhrasesToAvoid: ['No, impossible.', 'We will skip the testing this time.'],
      ),
      Scenario(
        id: 'practice_conflict_design',
        title: 'Discuss a Design Disagreement',
        subtitle: 'Compare the needs behind two proposed solutions',
        category: 'Conflict and Alignment',
        difficulty: ScenarioDifficulty.intermediate,
        persona: grace,
        userPersona: staffArchitect,
        contextBrief: 'A design partner wants a simpler first release; you want more time for a flexible system. Discuss what each option protects and what evidence can guide your choice.',
        userObjectives: ['Hear your partner’s reason.', 'State the shared decision clearly.', 'Agree on options and a fair way to choose.'],
        trapPhrasesToAvoid: ['Engineering knows best.', 'Let us just split the difference.'],
      ),
      Scenario(
        id: 'practice_delegate_task',
        title: 'Delegate a New Responsibility',
        subtitle: 'Set the outcome while leaving room for ownership',
        category: 'Delegation',
        difficulty: ScenarioDifficulty.intermediate,
        persona: david,
        userPersona: engineeringLead,
        contextBrief: 'You want a teammate to lead the next release readiness check. They have not done it before and are unsure what decisions they can make. Agree the outcome, boundaries, support, and check-in.',
        userObjectives: ['Explain the result that is needed.', 'Clarify authority and limits.', 'Ask what support and check-in would help.'],
        trapPhrasesToAvoid: ['Just handle the whole thing.', 'Ask me before every decision.'],
      ),
      Scenario(
        id: 'practice_senior_tradeoff',
        title: 'Recommend a Trade-Off to a VP',
        subtitle: 'Lead with your recommendation and support it with evidence',
        category: 'Managing Up',
        difficulty: ScenarioDifficulty.advanced,
        persona: elena,
        userPersona: roles.firstWhere((p) => p.id == 'product_director'),
        contextBrief: 'A VP asks to keep the release date and add two features. Current estimates show that doing both risks missing the reliability target. Give a concise recommendation with the evidence, options, and decision needed.',
        userObjectives: ['Lead with a clear recommendation.', 'Separate known evidence from estimates.', 'Explain the trade-off and ask for a decision.'],
        trapPhrasesToAvoid: ['This is a bad idea.', 'Whatever you want is fine.'],
      ),
      Scenario(
        id: 'practice_clear_request',
        title: 'Clarify a Missed Handoff',
        subtitle: 'Make a clear request and agree on the next step',
        category: 'Communication Basics',
        difficulty: ScenarioDifficulty.beginner,
        persona: alex,
        userPersona: engineeringLead,
        contextBrief:
            'A teammate has sent a project update without the customer impact or a clear owner for the next action. You have a short check-in to understand what happened and agree what information will be shared next time.',
        userObjectives: [
          'Ask what happened before assuming why the update was incomplete.',
          'Explain what information the team needs and why.',
          'Agree who will send the update and by when.',
        ],
        trapPhrasesToAvoid: [
          'You never give us enough information.',
          'Just communicate better next time.',
        ],
      ),
      Scenario(
        id: 'practice_listening',
        title: 'Understand a Teammate’s Concern',
        subtitle: 'Listen fully before deciding how to help',
        category: 'Listening',
        difficulty: ScenarioDifficulty.beginner,
        persona: nina,
        userPersona: engineeringLead,
        contextBrief:
            'A teammate says a new deadline feels unrealistic and that they are worried about quality. You do not yet know whether the issue is workload, unclear priorities, or a technical risk. Explore their concern before proposing a solution.',
        userObjectives: [
          'Ask an open question and allow the teammate to explain.',
          'Summarize the concern and check that you understood it.',
          'Agree whether to explore options now or gather more information.',
        ],
        trapPhrasesToAvoid: [
          'It will be fine; just make it work.',
          'You should have raised this earlier.',
        ],
      ),
      Scenario(
        id: 'scenario_managing_former_peer',
        title: 'Managing Former Peer',
        subtitle: 'Holding Deadlines Under Emotional Guilt',
        category: 'Peer Transition',
        difficulty: ScenarioDifficulty.intermediate,
        persona: alex,
        userPersona: engineeringLead,
        contextBrief:
            'You were promoted to Engineering Lead two months ago. Alex, who was formerly your equal peer and close friend on the team, is resisting the sprint deadline for the payments migration. He uses casual familiarity ("Come on, you know me") and accuses you of micromanaging to evade accountability.',
        userObjectives: [
          'Acknowledge his engineering perspective without conceding the deadline.',
          'State the business impact clearly without apologizing or hedging.',
          'Agree on a concrete mitigation plan before ending the call.',
        ],
        trapPhrasesToAvoid: [
          "I'm sorry to have to ask you this...",
          "I just feel like maybe we should...",
          "I know you hate this, but management is making me...",
        ],
      ),
      Scenario(
        id: 'practice_urgent_request',
        title: 'Respond to an Urgent Request',
        subtitle: 'Explain the team’s limit and offer a useful option',
        category: 'Managing Workload',
        difficulty: ScenarioDifficulty.advanced,
        persona: jordan,
        userPersona: engineeringLead,
        contextBrief:
            'It is Friday at 4:30 PM. VP Jordan has just called requiring a surprise 20-page analytics deck for Monday morning\'s board review. Your team has been operating at redline capacity. You must defend team burnout boundaries without appearing uncommitted.',
        userObjectives: [
          'Validate Jordan\'s urgency before stating current squad bandwidth.',
          'Hold the boundary against weekend emergency work.',
          'Offer a fair trade: a short 2-page summary Monday, full deck Wednesday.',
        ],
        trapPhrasesToAvoid: [
          "We can't do this, my team will quit.",
          "I guess we could try to work over the weekend...",
          "Why is this always our responsibility?",
        ],
      ),
      Scenario(
        id: 'practice_feedback_review',
        title: 'Give Clear, Respectful Feedback',
        subtitle: 'Discuss a specific behavior and agree what to try next',
        category: 'Direct Reports',
        difficulty: ScenarioDifficulty.intermediate,
        persona: marcus,
        userPersona: peoplePartner,
        contextBrief:
            'Marcus is a gifted junior engineer who becomes defensive and shut down during code reviews. His recent blunt comments in PRs caused friction with other contributors. Deliver direct corrective feedback with compassion without diluting the core message.',
        userObjectives: [
          'Cite specific PR comment examples rather than vague character judgments.',
          'Explain the cultural impact on team trust.',
          'Establish a two-way support cadence for professional growth.',
        ],
        trapPhrasesToAvoid: [
          "Everyone says you are being difficult.",
          "It's not really a big deal, but...",
          "You just need to calm down in Slack.",
        ],
      ),
      Scenario(
        id: 'scenario_cross_team_alignment',
        title: 'Cross-Team Alignment',
        subtitle: 'Breaking Deadlocks with Diplomatic Influence',
        category: 'Negotiations',
        difficulty: ScenarioDifficulty.beginner,
        persona: priya,
        userPersona: staffArchitect,
        contextBrief:
            'Marketing Lead Priya is refusing to release dedicated frontend bandwidth for critical authentication security updates because of an upcoming ad campaign. Negotiate a compromise that protects security compliance while maintaining launch continuity.',
        userObjectives: [
          'Demonstrate understanding of her campaign revenue goals.',
          'Frame security compliance as a shared business risk.',
          'Secure partial engineering commitment or phased rollout.',
        ],
        trapPhrasesToAvoid: [
          "Security always trumps marketing.",
          "You have to give us what we want.",
          "We'll just escalate this to the CTO.",
        ],
      ),
    ];
  }

  static String illustrationFor(String scenarioId) {
    switch (scenarioId) {
      case 'scenario_managing_former_peer':
        return HardSyncAssets.illusManager11;
      case 'practice_urgent_request':
        return HardSyncAssets.illusDemandingExecutivePersona;
      case 'practice_feedback_review':
        return HardSyncAssets.illusToughFeedbackMoment;
      case 'scenario_cross_team_alignment':
        return HardSyncAssets.illusConflictBridge;
      case 'practice_more_clear_request':
        return HardSyncAssets.illusCareFramework;
      case 'practice_listening_another_view':
        return HardSyncAssets.illusActiveListening;
      case 'practice_feedback_followup':
        return HardSyncAssets.illusConversationRewind;
      case 'practice_boundary_scope':
        return HardSyncAssets.illusBurnoutBattery;
      case 'practice_conflict_customer_quality':
        return HardSyncAssets.illusPushbackPractice;
      case 'practice_delegate_checkin':
        return HardSyncAssets.illusPauseAndReframe;
      case 'practice_change_senior':
        return HardSyncAssets.illusExecutiveChallenge;
      case 'practice_senior_disagreement':
        return HardSyncAssets.illusDifficultConversationArena;
      case 'practice_repair_meeting':
        return HardSyncAssets.illusMindsetReset;
      case 'practice_update_priority':
        return HardSyncAssets.illusToneAwareness;
      case 'practice_team_one_to_one':
        return HardSyncAssets.illusQuietTeamMemberPersona;
      case 'practice_feedback_missed_handoff':
        return HardSyncAssets.illusFeedbackSandwichVisual;
      case 'practice_say_no_peer':
        return HardSyncAssets.illusScriptBuilder;
      case 'practice_conflict_priority':
        return HardSyncAssets.illusEmpathyLens;
      case 'practice_manage_up_scope':
        return HardSyncAssets.illusLeadershipCompass;
      case 'practice_change_uncertainty':
        return HardSyncAssets.illusDifficultConversationsPath;
      case 'practice_clear_update':
        return HardSyncAssets.illusCaseStudyScene;
      case 'practice_listening_change':
        return HardSyncAssets.illusBetterResponse;
      case 'practice_feedback_positive':
        return HardSyncAssets.illusHighPerformerPersona;
      case 'practice_boundary_timeline':
        return HardSyncAssets.illusOverwhelmedEmployeePersona;
      case 'practice_conflict_design':
        return HardSyncAssets.illusSituationActionImpact;
      case 'practice_delegate_task':
        return HardSyncAssets.illusRemoteTeammatePersona;
      case 'practice_senior_tradeoff':
        return HardSyncAssets.illusQuoteHighlight;
      case 'practice_clear_request':
        return HardSyncAssets.illusConversationBlueprint;
      case 'practice_listening':
        return HardSyncAssets.illusDefensiveDirectReportPersona;
      default:
        return HardSyncAssets.illusSafeRehearsalRoom;
    }
  }

  static UserPersona userPersonaFor(Persona persona) {
    final roleId = switch (persona.id) {
      'marcus' => 'people_partner',
      'priya' => 'staff_architect',
      _ => 'eng_lead',
    };
    return UserPersona.defaultPersonas.firstWhere((role) => role.id == roleId);
  }
}
