import '../theme/hardsync_assets.dart';

class LearningLesson {
  final String title;
  final String situation;
  final String outcome;
  final String concept;
  final List<String> framework;
  final String example;
  final String reflection;
  final String illustration;
  final List<String> practiceScenarioIds;

  const LearningLesson({
    required this.title,
    required this.situation,
    required this.outcome,
    required this.concept,
    this.framework = const [],
    required this.example,
    required this.reflection,
    required this.illustration,
    this.practiceScenarioIds = const [],
  });
}

class LearningCourse {
  final String id;
  final String title;
  final String audience;
  final String level;
  final String promise;
  final String takeaway;
  final String hero;
  final List<LearningLesson> lessons;
  final List<String> practiceScenarioIds;

  const LearningCourse({
    required this.id,
    required this.title,
    required this.audience,
    required this.level,
    required this.promise,
    required this.takeaway,
    required this.hero,
    required this.lessons,
    this.practiceScenarioIds = const [],
  });

  int get minutes => 1;

  List<String> get allPracticeScenarioIds => lessons
      .expand((lesson) => lesson.practiceScenarioIds)
      .toList(growable: false);
}

class LearningPath {
  final String title;
  final String audience;
  final String illustration;
  final List<String> courseIds;
  final String level;

  const LearningPath({
    required this.title,
    required this.audience,
    required this.illustration,
    required this.courseIds,
    required this.level,
  });
}

LearningLesson _lesson(
  String title,
  String outcome,
  String concept,
  String example,
  String reflection,
  String illustration, [
  List<String> scenarios = const [],
]) => LearningLesson(
  title: title,
  situation: '',
  outcome: outcome,
  concept: concept,
  example: example,
  reflection: reflection,
  illustration: illustration,
  practiceScenarioIds: scenarios,
);

class LearningCatalog {
  static final courses = <LearningCourse>[
    LearningCourse(
      id: 'clarity',
      title: 'Make a Clear Request',
      audience: 'Anyone at work',
      level: 'Basic',
      promise: 'Make a clear request and agree who will do what next.',
      takeaway:
          'Outcome → facts → ask → understanding → owner and date.',
      hero: HardSyncAssets.illusLeadershipCompass,
      lessons: [
        _lesson(
          'Start with the outcome',
          'Name the result the conversation must produce.',
          'Decide what needs to be clear by the end: a choice, a plan, or who will do what.',
          '“Today we need to decide which launch scope we can support safely.”',
          'What one sentence should the other person remember?',
          HardSyncAssets.illusLeadershipCompass,
          ['practice_clear_request', 'practice_more_clear_request'],
        ),
        _lesson(
          'Describe what you know',
          'Separate observable facts from interpretation.',
          'Describe what you saw or heard, and keep guesses about the reason separate.',
          '“The release is two days behind the agreed date” is an observation. “You do not care” is an inference.',
          'Rewrite one judgment as an observable fact.',
          HardSyncAssets.illusConversationBlueprint,
          ['practice_update_priority'],
        ),
        _lesson(
          'Make a clear ask',
          'Turn concern into a bounded request.',
          'Ask for one action and say when it is needed. Add a reason if it helps the other person decide.',
          '“Can you send the revised estimate by 3 p.m. today?”',
          'Write the smallest clear ask that moves your issue forward.',
          HardSyncAssets.illusScriptBuilder,
          ['practice_clear_update'],
        ),
        _lesson(
          'Check understanding',
          'Find gaps before they become rework.',
          'Check what the other person understood and ask what might make the plan difficult.',
          '“What am I missing from your side?”',
          'Which open question would reveal a hidden constraint?',
          HardSyncAssets.illusActiveListening,
          ['practice_listening', 'practice_listening_another_view'],
        ),
        _lesson(
          'Close the loop',
          'End with shared ownership.',
          'Repeat the decision, who will act, when they will do it, and when you will check again.',
          '“Mina will send the estimate today; we will revisit scope if validation exceeds two days.”',
          'Complete: [owner] will [action] by [date].',
          HardSyncAssets.illusClarityMeter,
          ['practice_update_priority'],
        ),
      ],
    ),
    LearningCourse(
      id: 'listening',
      title: 'Listen Before You Solve',
      audience: 'Anyone at work',
      level: 'Basic',
      promise: 'Listen for what matters before offering a solution.',
      takeaway:
          'Listen for the facts and concern. Say what you heard and check it before responding.',
      hero: HardSyncAssets.illusActiveListening,
      lessons: [
        _lesson(
          'Notice your listening default',
          'Recognize the reaction that narrows your attention.',
          'When a conversation feels tense, you may rush to fix, defend, explain, or go quiet. Notice the urge and pause.',
          'Notice the urge to explain before choosing whether explanation is useful.',
          'Which default appears most often for you?',
          HardSyncAssets.illusEmotionalCheckInOrb,
          ['practice_listening_change'],
        ),
        _lesson(
          'Use open questions',
          'Invite information instead of steering the answer.',
          'Ask questions that help the other person explain what is difficult or important, without suggesting they are at fault.',
          '“What would a workable outcome need to protect?”',
          'Turn one leading question into an open question.',
          HardSyncAssets.illusEmpathyLens,
          ['practice_listening'],
        ),
        _lesson(
          'Reflect and check',
          'Confirm meaning without claiming certainty.',
          'Put the concern into your own neutral words and check that you have it right.',
          '“It sounds like the date works only if testing moves. Have I got that right?”',
          'Write a neutral reflection for a current concern.',
          HardSyncAssets.illusActiveListening,
          ['practice_team_one_to_one'],
        ),
        _lesson(
          'Name emotion carefully',
          'Acknowledge emotion while leaving room for correction.',
          'You can mention what you notice, while letting the other person correct you.',
          '“You sound frustrated about the late change.”',
          'What tentative emotion label could open space?',
          HardSyncAssets.illusMoodConstellation,
          ['practice_listening_change'],
        ),
        _lesson(
          'Move to action together',
          'Choose the next mode of conversation jointly.',
          'Ask whether to keep exploring, compare options, or decide a next step.',
          '“Would it help to explore this more, or should we compare options?”',
          'Which transition would feel least abrupt?',
          HardSyncAssets.illusPracticeReflectImprove,
          ['practice_team_one_to_one'],
        ),
      ],
    ),
    LearningCourse(
      id: 'feedback',
      title: 'Give Useful Feedback',
      audience: 'Anyone working with others',
      level: 'Basic',
      promise:
          'Talk about a specific action, its effect, and what to try next.',
      takeaway:
          'What happened, what the person did, the effect, their view, next step.',
      hero: HardSyncAssets.illusSituationActionImpact,
      lessons: [
        _lesson(
          'Choose a useful moment',
          'Create conditions where feedback can be heard.',
          'Choose a recent example and a calm, private time when you can both talk without rushing.',
          'Ask for ten focused minutes rather than surprising someone at the end of a meeting.',
          'When and where would this conversation work best?',
          HardSyncAssets.illusToughFeedbackMoment,
          ['practice_feedback_missed_handoff'],
        ),
        _lesson(
          'Describe the moment–Behavior–Impact',
          'Describe feedback without labels.',
          'Say when it happened, what the person did that you could observe, and how it affected the work.',
          '“In Tuesday’s review, the estimate changed after the decision. The team left with two dates.”',
          'Draft one situation, behavior, and impact.',
          HardSyncAssets.illusSituationActionImpact,
          ['practice_feedback_review'],
        ),
        _lesson(
          'Separate observation from story',
          'Remove assumptions that trigger defensiveness.',
          'Replace character judgments with actions another observer could verify.',
          'Replace “careless” with the missed step and the supported consequence.',
          'Which label can you turn into a behavior?',
          HardSyncAssets.illusBetterResponse,
          ['practice_feedback_missed_handoff'],
        ),
        _lesson(
          'Invite their perspective',
          'Discover context before deciding meaning.',
          'Ask what was happening from their side and listen before moving to correction.',
          '“What was happening from your side?”',
          'What might you not know yet?',
          HardSyncAssets.illusEmpathyLens,
          ['practice_feedback_review'],
        ),
        _lesson(
          'Agree the next experiment',
          'Convert feedback into observable action.',
          'Choose one behavior, a support needed, and a time to review what happened.',
          'Agree to flag estimate changes before the decision and review after the next planning meeting.',
          'What single behavior would show progress?',
          HardSyncAssets.illusCoachDebrief,
          ['practice_feedback_positive', 'practice_feedback_followup'],
        ),
      ],
    ),
    LearningCourse(
      id: 'boundaries',
      title: 'Set Limits and Offer Options',
      audience: 'Anyone working with others',
      level: 'Intermediate',
      promise:
          'Explain what you can do, what you cannot do, and what could change.',
      takeaway: 'Acknowledge → limit → trade-off → choice.',
      hero: HardSyncAssets.illusScriptBuilder,
      lessons: [
        _lesson(
          'Know what must be protected',
          'Separate the firm constraint from flexible details.',
          'Work out what cannot change, such as your available time or a quality check, and what can.',
          '“We need to keep the quality checks. We could reduce the first release or move the date.”',
          'What is fixed, and what can change?',
          HardSyncAssets.illusScriptBuilder,
          ['practice_say_no_peer', 'practice_boundary_scope'],
        ),
        _lesson(
          'Acknowledge the request',
          'Show understanding without promising agreement.',
          'Show that you understand why the request matters, even if you cannot agree to it as asked.',
          '“I see why Friday matters for the customer.”',
          'What need can you acknowledge sincerely?',
          HardSyncAssets.illusEmpathyLens,
          ['practice_urgent_request'],
        ),
        _lesson(
          'State your limit clearly',
          'Make the limit and consequence easy to understand.',
          'Say your limit simply. You do not need a long defense or repeated apologies.',
          '“I cannot commit to the full migration by Friday without skipping validation.”',
          'Write your boundary in one sentence.',
          HardSyncAssets.illusPauseAndReframe,
          ['practice_boundary_timeline'],
        ),
        _lesson(
          'Offer real choices',
          'Protect the constraint while keeping movement possible.',
          'Offer choices that are both possible, and explain what changes with each one.',
          '“We can launch the viewing feature Friday and add downloads Tuesday, or move the full launch.”',
          'Which two viable options can you offer?',
          HardSyncAssets.illusScriptBuilder,
          ['practice_say_no_peer'],
        ),
        _lesson(
          'Confirm the decision',
          'Turn agreement into a reliable next step.',
          'Ask which trade-off they choose, then record owner and date.',
          '“Which option should I plan around?”',
          'How will you document the decision?',
          HardSyncAssets.illusClarityMeter,
          ['practice_boundary_timeline'],
        ),
      ],
    ),
    LearningCourse(
      id: 'conflict',
      title: 'Work Through a Disagreement',
      audience: 'Managers and team leads',
      level: 'Intermediate',
      promise:
          'Understand what one other person needs and agree how to move forward.',
      takeaway:
          'Name the issue / hear their reason / compare options / agree what happens next.',
      hero: HardSyncAssets.illusConflictBridge,
      lessons: [
        _lesson(
          'Describe the work issue',
          'Talk about the decision without blaming the person.',
          'Name the choice or task you disagree about. Keep assumptions about motive out of it.',
          '“We have different views on what needs to be ready for Friday.”',
          'How can you describe the issue neutrally?',
          HardSyncAssets.illusConflictBridge,
          ['practice_conflict_priority', 'practice_conflict_customer_quality'],
        ),
        _lesson(
          'Ask what matters to them',
          'Understand the reason behind their request.',
          'Ask why they prefer that option. The reason may reveal other ways to meet the need.',
          '“What is most important for you to protect with that date?”',
          'What need might be behind their request?',
          HardSyncAssets.illusDifficultConversationArena,
          ['practice_conflict_design'],
        ),
        _lesson(
          'Check that you understood',
          'Show you heard their view before explaining yours.',
          'Let them finish, summarize what you heard, and check that you got it right.',
          '“It sounds like the customer date is the main concern. Did I understand?”',
          'What question would help you understand their view?',
          HardSyncAssets.illusActiveListening,
          ['scenario_cross_team_alignment'],
        ),
        _lesson(
          'Compare possible options',
          'Look for more than one workable next step.',
          'Think of options that address the need and name what each one changes.',
          '“We could ship the smaller change Friday and test the rest next week.”',
          'What two options could you discuss?',
          HardSyncAssets.illusDifficultConversationsPath,
          ['practice_conflict_priority'],
        ),
        _lesson(
          'Agree what happens next',
          'Leave with a decision or a clear next step.',
          'Agree who will decide, what information is needed, and when you will check again.',
          '“Let’s check the test results tomorrow and decide then.”',
          'What should happen next, and when?',
          HardSyncAssets.illusPracticeReflectImprove,
          ['practice_conflict_design'],
        ),
      ],
    ),
    LearningCourse(
      id: 'manage_up',
      title: 'Raise a Risk with Senior Leaders',
      audience: 'Anyone working with others',
      level: 'Intermediate',
      promise:
          'Share a concern about a plan and suggest realistic ways forward.',
      takeaway: 'Goal → evidence → risk → options → decision.',
      hero: HardSyncAssets.illusDemandingExecutivePersona,
      lessons: [
        _lesson(
          'Read the decision context',
          'Identify the goal and what can still change.',
          'Find out what matters most to the person making the decision before you suggest a change.',
          '“Which matters most for this release: keeping Friday, including every feature, or completing all checks?”',
          'What outcome matters most to them?',
          HardSyncAssets.illusDemandingExecutivePersona,
          ['practice_urgent_request'],
        ),
        _lesson(
          'Bring evidence',
          'Ground resistance in relevant facts.',
          'Explain what you know, what you are estimating, and what could go wrong.',
          '“The security review has taken four to six days in the last three releases.”',
          'Which evidence is relevant and trustworthy?',
          HardSyncAssets.illusClarityMeter,
          ['practice_manage_up_scope'],
        ),
        _lesson(
          'Connect risk to their goal',
          'Frame concern around the shared outcome.',
          'Show how the proposed plan might undermine what the stakeholder wants to protect.',
          '“To protect the audit date, this plan needs validation time.”',
          'How does the risk connect to their goal?',
          HardSyncAssets.illusPushbackPractice,
          ['practice_senior_tradeoff'],
        ),
        _lesson(
          'Bring options and trade-offs',
          'Make a decision easier without hiding cost.',
          'Offer a recommendation and one alternative with visible consequences.',
          'Keep the date and move reporting, or keep scope and shift one week.',
          'What do you recommend, and what is the alternative?',
          HardSyncAssets.illusExecutiveChallenge,
          ['practice_manage_up_scope'],
        ),
        _lesson(
          'Ask for the decision',
          'Close with ownership of risk and scope.',
          'Confirm the chosen option, risk owner, and check-in point.',
          '“Which trade-off should I plan around?”',
          'What needs to be documented after the conversation?',
          HardSyncAssets.illusConversationBlueprint,
          ['practice_senior_tradeoff'],
        ),
      ],
    ),
    LearningCourse(
      id: 'coaching',
      title: 'Delegate and Coach for Ownership',
      audience: 'Anyone working with others',
      level: 'Intermediate',
      promise:
          'Support someone to think through a problem and choose an action.',
      takeaway:
          'Ask → listen → reflect → offer with permission → commit.',
      hero: HardSyncAssets.illusManager11,
      lessons: [
        _lesson(
          'Agree on the topic',
          'Let the learner define useful progress.',
          'Ask what the person hopes to work out before you begin giving suggestions.',
          '“What would be most useful to leave this 1:1 with?”',
          'What outcome would make this conversation useful?',
          HardSyncAssets.illusManager11,
          ['practice_team_one_to_one'],
        ),
        _lesson(
          'Explore before advising',
          'Keep the thinking with the other person.',
          'Ask what they tried, know, and find difficult before offering an answer.',
          '“What options have you considered?”',
          'Which question would help them think further?',
          HardSyncAssets.illusQuietTeamMemberPersona,
          ['practice_delegate_task', 'practice_delegate_checkin'],
        ),
        _lesson(
          'Offer a reflection',
          'Surface patterns without diagnosing.',
          'Describe what you noticed and ask what pattern they see.',
          '“We have returned to the same blocker twice. What do you notice?”',
          'What neutral pattern can you reflect?',
          HardSyncAssets.illusReflectionMirror,
          ['practice_team_one_to_one'],
        ),
        _lesson(
          'Ask before advising',
          'Make advice collaborative.',
          'Request permission and offer an option rather than taking control.',
          '“Would it help if I shared an option I have seen work?”',
          'How will you ask permission?',
          HardSyncAssets.illusCoachThinking,
          ['practice_delegate_task'],
        ),
        _lesson(
          'Let them choose',
          'End with their commitment and requested support.',
          'Ask what they will do, by when, and what support they want.',
          '“What will you try before our next 1:1?”',
          'What support can you offer without owning the task?',
          HardSyncAssets.illusCoachDebrief,
          ['practice_delegate_task'],
        ),
      ],
    ),
    LearningCourse(
      id: 'presence',
      title: 'Lead High-Stakes Conversations',
      audience: 'Experienced professionals and leaders',
      level: 'Advanced',
      promise:
          'Make your main point clear when the stakes or pressure are high.',
      takeaway: 'Headline → reason → implication → ask.',
      hero: HardSyncAssets.illusConfidenceMeter,
      lessons: [
        _lesson(
          'Lead with the headline',
          'Make the recommendation easy to hear.',
          'Say your recommendation first, then give the most important reason.',
          '“I recommend delaying one week to complete the security review.”',
          'What is your headline in twelve words?',
          HardSyncAssets.illusConfidenceMeter,
          ['practice_senior_tradeoff'],
        ),
        _lesson(
          'Use a short structure',
          'Speak with enough context and a clear ask.',
          'Use point, reason, implication, and ask. Stop when the listener can respond.',
          'State the point, one reason, the consequence, and the decision needed.',
          'Which detail can you remove?',
          HardSyncAssets.illusSpeakingPace,
          ['practice_manage_up_scope'],
        ),
        _lesson(
          'Pause under pressure',
          'Respond deliberately instead of defensively.',
          'A breath and a beat create room for judgment and for the other person to finish.',
          'Pause, acknowledge the question, then answer the main concern.',
          'What physical cue will remind you to pause?',
          HardSyncAssets.illusPauseAndReframe,
          ['practice_change_uncertainty', 'practice_change_senior'],
        ),
        _lesson(
          'Hold with flexibility',
          'Stay clear while remaining open to evidence.',
          'Repeat the constraint calmly and change your view when new information warrants it.',
          '“The validation requirement remains; I am open to another way to meet it.”',
          'What evidence would appropriately change your position?',
          HardSyncAssets.illusToneAwareness,
          ['practice_conflict_design'],
        ),
        _lesson(
          'Recover cleanly',
          'Repair a poor moment without derailing the issue.',
          'Name the specific miss briefly, correct it, and return to the conversation.',
          '“I cut you off. Please finish your point.”',
          'Write one short repair sentence.',
          HardSyncAssets.illusPracticeReflectImprove,
          ['practice_change_uncertainty'],
        ),
      ],
    ),
    LearningCourse(
      id: 'negotiation',
      title: 'Negotiate a Fair Agreement',
      audience: 'Managers working across teams',
      level: 'Intermediate',
      promise:
          'Prepare for a difficult ask and find an agreement both sides can deliver.',
      takeaway: 'Goal, interests, options, trade-offs, agreement.',
      hero: HardSyncAssets.illusConflictBridge,
      lessons: [
        _lesson(
          'Prepare the real problem',
          'Know what you need before you start.',
          'Write the outcome you need, what you can change, and what you cannot promise.',
          '"I need design support this week. I can move the review date, but I cannot remove accessibility checks."',
          'What is your must-have, and what can you trade?',
          HardSyncAssets.illusConversationBlueprint,
          ['practice_conflict_priority'],
        ),
        _lesson(
          'Ask about their priorities',
          'Find the need behind the first position.',
          'A request such as "not this week" may be protecting a deadline, a person, or a quality risk.',
          '"What does your team need to protect this week?"',
          'What might be important on their side?',
          HardSyncAssets.illusEmpathyLens,
          ['practice_conflict_design'],
        ),
        _lesson(
          'Offer two workable options',
          'Make the trade-off visible.',
          'Offer choices you can genuinely support. Explain what each choice changes.',
          '"We can borrow Priya for two days and move our test review, or keep the review and use a smaller design change."',
          'Which two options are honest and possible?',
          HardSyncAssets.illusScriptBuilder,
          ['practice_senior_tradeoff'],
        ),
        _lesson(
          'Confirm the agreement',
          'Leave with a shared plan.',
          'Say what each person will do, what has changed, and when you will check progress.',
          '"Priya joins us Tuesday and Wednesday. I will move the review to Friday. We will check in Wednesday afternoon."',
          'Who owns each action and when will you review?',
          HardSyncAssets.illusClarityMeter,
          ['practice_conflict_priority'],
        ),
      ],
    ),
    LearningCourse(
      id: 'performance',
      title: 'Manage Performance with Care',
      audience: 'Managers holding regular 1:1s',
      level: 'Advanced',
      promise: 'Address a performance concern clearly, fairly, and early.',
      takeaway: 'Evidence, impact, their view, clear support, follow-up.',
      hero: HardSyncAssets.illusToughFeedbackMoment,
      lessons: [
        _lesson(
          'Bring specific evidence',
          'Start with work you can describe clearly.',
          'Use recent examples, expected standards, and impact. Avoid labels about attitude or personality.',
          '"The customer handoff was late on Monday and Thursday, so support started both cases without the required notes."',
          'Which facts would another person be able to verify?',
          HardSyncAssets.illusSituationActionImpact,
          ['practice_feedback_missed_handoff'],
        ),
        _lesson(
          'Hear the full context',
          'Make room for information you do not have.',
          'Ask what is getting in the way and listen before deciding the cause.',
          '"I want to understand what is making these handoffs difficult from your side."',
          'What could you learn by asking before advising?',
          HardSyncAssets.illusActiveListening,
          ['practice_feedback_review'],
        ),
        _lesson(
          'Set a clear improvement plan',
          'Turn concern into observable progress.',
          'Agree the behaviour, support, check-in date, and what good looks like.',
          '"For the next two weeks, each handoff includes the notes before 3 p.m. I will review the first two with you on Tuesday."',
          'What would visible progress look like?',
          HardSyncAssets.illusCoachDebrief,
          ['practice_feedback_followup'],
        ),
        _lesson(
          'Follow up consistently',
          'Build trust through steady follow-through.',
          'Review what changed, acknowledge effort, and adjust support when the plan is not working.',
          '"The notes were complete this week. What helped, and what do we need to keep in place?"',
          'How will you make the follow-up feel fair and useful?',
          HardSyncAssets.illusPracticeReflectImprove,
          ['practice_feedback_followup'],
        ),
      ],
    ),
    LearningCourse(
      id: 'reset',
      title: 'Reset After a Hard Conversation',
      audience: 'Anyone at work',
      level: 'Basic',
      promise: 'Reflect, repair, and choose one concrete improvement.',
      takeaway: 'Keep one behavior, change one, plan one next attempt.',
      hero: HardSyncAssets.illusConversationRewind,
      lessons: [
        _lesson(
          'Facts before interpretation',
          'Separate what happened from the meaning you assigned.',
          'Record what was said or decided, then list assumptions separately.',
          '“They ended the meeting early” is a fact; the reason is not yet known.',
          'Which part of your replay is an assumption?',
          HardSyncAssets.illusConversationRewind,
          ['practice_change_uncertainty'],
        ),
        _lesson(
          'Find one effective moment',
          'Notice a behavior worth repeating.',
          'Choose a question, pause, boundary, or acknowledgment that helped.',
          'A concise summary may have stopped the discussion from looping.',
          'What worked, even briefly?',
          HardSyncAssets.illusBetterResponse,
          ['practice_senior_tradeoff', 'practice_senior_disagreement'],
        ),
        _lesson(
          'Choose one improvement',
          'Turn reflection into an observable experiment.',
          'Avoid vague goals. Choose one behavior you can see or hear.',
          'Replace “be confident” with “state my recommendation before the context.”',
          'What one behavior will you try?',
          HardSyncAssets.illusPracticeReflectImprove,
          ['practice_conflict_design'],
        ),
        _lesson(
          'Repair if needed',
          'Acknowledge impact and clarify what changes.',
          'Name the action, its impact, and your next behavior without demanding forgiveness.',
          '“I dismissed your concern before hearing it. Next time I will summarize first.”',
          'Is there a specific repair you owe?',
          HardSyncAssets.illusEmpathyLens,
          ['practice_change_uncertainty', 'practice_repair_meeting'],
        ),
        _lesson(
          'Carry learning forward',
          'Create a cue for the next real conversation.',
          'Write a short prompt and decide when you will review it.',
          'Cue: “Headline first, then pause.”',
          'What cue will you take into the next conversation?',
          HardSyncAssets.illusJournalReflection,
          ['practice_senior_tradeoff'],
        ),
      ],
    ),
  ];

  static const paths = <LearningPath>[
    LearningPath(
      title: 'Build better 1:1s',
      level: 'Start here',
      audience:
          'Learn how to make regular 1:1s clear, useful, and safe for honest conversation.',
      illustration: HardSyncAssets.illusManagerJourneyMap,
      courseIds: ['clarity', 'listening', 'coaching'],
    ),
    LearningPath(
      title: 'Give feedback and support growth',
      level: 'People management',
      audience:
          'Handle feedback, performance concerns, and follow-up without making people defensive.',
      illustration: HardSyncAssets.illusPracticeReflectImprove,
      courseIds: ['feedback', 'performance', 'reset'],
    ),
    LearningPath(
      title: 'Handle difficult conversations',
      level: 'When stakes are high',
      audience:
          'Set limits, work through disagreement, and negotiate a fair agreement.',
      illustration: HardSyncAssets.illusLeadershipToolkit,
      courseIds: ['boundaries', 'conflict', 'negotiation'],
    ),
    LearningPath(
      title: 'Influence and lead with confidence',
      level: 'Leading beyond your team',
      audience:
          'Raise risks, make clear recommendations, and stay steady under pressure.',
      illustration: HardSyncAssets.illusConfidenceMeter,
      courseIds: ['manage_up', 'presence'],
    ),
  ];

  static LearningCourse? forScenario(String scenarioId) {
    for (final course in courses) {
      if (course.allPracticeScenarioIds.contains(scenarioId)) return course;
    }
    return null;
  }

  static List<LearningCourse> coursesForScenario(String scenarioId) => courses
      .where((course) => course.allPracticeScenarioIds.contains(scenarioId))
      .toList();

  static Set<String> get linkedScenarioIds =>
      courses.expand((course) => course.allPracticeScenarioIds).toSet();

  static LearningCourse byId(String id) =>
      courses.firstWhere((c) => c.id == id);
}
