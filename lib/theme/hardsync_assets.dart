import 'package:flutter/material.dart';

/// Centralized registry for all illustrated assets, badges, gamification, and illustrated icons.
class HardSyncAssets {
  static const String _illusBase = 'assets/illustrations';
  static const String _avatarBase = 'assets/avatars/split/flutter_256';
  static const String _badgeBase = 'assets/badges';
  static const String _gamifyBase = 'assets/gamification';
  static const String _iconBase = 'assets/icons/split/flutter_128';

  // Stable identity portraits. Use these for profile photos, persona chips,
  // chat senders, call portraits, and account surfaces.
  static const String avatarCurrentUser = '$_avatarBase/avatar_21.png';
  static const String avatarAlex = '$_avatarBase/avatar_10.png';
  static const String avatarJordan = '$_avatarBase/avatar_44.png';
  static const String avatarMarcus = '$_avatarBase/avatar_24.png';
  static const String avatarPriya = '$_avatarBase/avatar_03.png';
  static const String avatarElena = '$_avatarBase/avatar_17.png';
  static const String avatarSam = '$_avatarBase/avatar_08.png';
  static const String avatarGrace = '$_avatarBase/avatar_36.png';
  static const String avatarOmar = '$_avatarBase/avatar_41.png';
  static const String avatarNina = '$_avatarBase/avatar_50.png';
  static const String avatarDavid = '$_avatarBase/avatar_33.png';

  // Curated picker options offered during account setup. Deliberately
  // distinct from the persona avatars above so a user's own picture never
  // matches an AI persona's face during a call.
  static const List<String> avatarPresets = [
    '$_avatarBase/avatar_02.png',
    '$_avatarBase/avatar_05.png',
    '$_avatarBase/avatar_08.png',
    '$_avatarBase/avatar_12.png',
    '$_avatarBase/avatar_15.png',
    '$_avatarBase/avatar_19.png',
    '$_avatarBase/avatar_28.png',
    '$_avatarBase/avatar_33.png',
    '$_avatarBase/avatar_38.png',
    '$_avatarBase/avatar_50.png',
  ];

  // ==========================================
  // --- 7 Executive & Leadership Badges ---
  // ==========================================
  static const String badgeOneononeChampionBadge =
      '$_badgeBase/1-1 Champion Badge.webp';
  static const String badgeClearCommunicatorBadge =
      '$_badgeBase/Clear Communicator Badge.webp';
  static const String badgeConflictNavigatorBadge =
      '$_badgeBase/Conflict Navigator Badge.webp';
  static const String badgeEmpathyLeaderBadge =
      '$_badgeBase/Empathy Leader Badge.webp';
  static const String badgeExecutivePresenceBadge =
      '$_badgeBase/Executive Presence Badge.webp';
  static const String badgeFeedbackBuilderBadge =
      '$_badgeBase/Feedback Builder Badge.webp';
  static const String badgeTeamBuilderBadge =
      '$_badgeBase/Team Builder Badge.webp';

  // ==========================================
  // --- 9 Gamification & Milestones ---
  // ==========================================
  static const String gamifyCoachCelebration =
      '$_gamifyBase/Coach Celebration.webp';
  static const String gamifyGrowthPath = '$_gamifyBase/Growth Path.webp';
  static const String gamifyLeadershipLevelUp =
      '$_gamifyBase/Leadership Level-Up.webp';
  static const String gamifyMasteryMountain =
      '$_gamifyBase/Mastery Mountain.webp';
  static const String gamifyPracticeStreakFlame =
      '$_gamifyBase/Practice Streak Flame.webp';
  static const String gamifyProgressOrbit = '$_gamifyBase/Progress Orbit.webp';
  static const String gamifySkillTree = '$_gamifyBase/Skill Tree.webp';
  static const String gamifySkillUnlocked = '$_gamifyBase/Skill Unlocked.webp';
  static const String gamifyTryAgain = '$_gamifyBase/Try Again.webp';

  // ==========================================
  // --- App Brand Identity & Official Mascot ---
  // ==========================================
  static const String appMascot = '$_illusBase/HardSync Mascot.webp';
  static const String appIcon = '$_illusBase/App Icon.webp';

  // ==========================================
  // --- 56 Individual Extracted Illustrations ---
  // ==========================================
  static const String illusAiCoachWhisper = '$_illusBase/AI Coach Whisper.webp';
  static const String illusActiveListening = '$_illusBase/Active Listening.webp';
  static const String illusBetterResponse = '$_illusBase/Better Response.webp';
  static const String illusBurnoutBattery = '$_illusBase/Burnout Battery.webp';
  static const String illusCareFramework = '$_illusBase/CARE Framework.webp';
  static const String illusCaseStudyScene = '$_illusBase/Case Study Scene.webp';
  static const String illusClarityMeter = '$_illusBase/Clarity Meter.webp';
  static const String illusCoachDebrief = '$_illusBase/Coach Debrief.webp';
  static const String illusCoachThinking = '$_illusBase/Coach Thinking.webp';
  static const String illusConfidenceCheckIn =
      '$_illusBase/Confidence Check-In.webp';
  static const String illusConfidenceMeter = '$_illusBase/Confidence Meter.webp';
  static const String illusConflictBridge = '$_illusBase/Conflict Bridge.webp';
  static const String illusConversationBlueprint =
      '$_illusBase/Conversation Blueprint.webp';
  static const String illusConversationRewind =
      '$_illusBase/Conversation Rewind.webp';
  static const String illusDailyReflectionWindow =
      '$_illusBase/Daily Reflection Window.webp';
  static const String illusDefensiveDirectReportPersona =
      '$_illusBase/Defensive Direct Report Persona.webp';
  static const String illusDemandingExecutivePersona =
      '$_illusBase/Demanding Executive Persona.webp';
  static const String illusDifficultConversationArena =
      '$_illusBase/Difficult Conversation Arena.webp';
  static const String illusDifficultConversationsPath =
      '$_illusBase/Difficult Conversations Path.webp';
  static const String illusEmotionalCheckInOrb =
      '$_illusBase/Emotional Check-In Orb.webp';
  static const String illusEmpathyLens = '$_illusBase/Empathy Lens.webp';
  static const String illusEnergyCheckIn = '$_illusBase/Energy Check-In.webp';
  static const String illusExecutiveChallenge =
      '$_illusBase/Executive Challenge.webp';
  static const String illusFeedbackSandwichVisual =
      '$_illusBase/Feedback Sandwich Visual.webp';
  static const String illusHighPerformerPersona =
      '$_illusBase/High Performer Persona.webp';
  static const String illusImposterSyndrome =
      '$_illusBase/Imposter Syndrome.webp';
  static const String illusJournalReflection =
      '$_illusBase/Journal Reflection.webp';
  static const String illusLeadershipCompass =
      '$_illusBase/Leadership Compass.webp';
  static const String illusLeadershipToolkit =
      '$_illusBase/Leadership Toolkit.webp';
  static const String illusLessonCapsule = '$_illusBase/Lesson Capsule.webp';
  static const String illusManager11 = '$_illusBase/Manager 1-1.webp';
  static const String illusManagerJourneyMap =
      '$_illusBase/Manager Journey Map.webp';
  static const String illusMicroLearningStack =
      '$_illusBase/Micro-Learning Stack.webp';
  static const String illusMindsetReset = '$_illusBase/Mindset Reset.webp';
  static const String illusMoodConstellation =
      '$_illusBase/Mood Constellation.webp';
  static const String illusNewHirePersona = '$_illusBase/New Hire Persona.webp';
  static const String illusOverwhelmedEmployeePersona =
      '$_illusBase/Overwhelmed Employee Persona.webp';
  static const String illusPauseAndReframe = '$_illusBase/Pause & Reframe.webp';
  static const String illusPersonaSelector = '$_illusBase/Persona Selector.webp';
  static const String illusPracticeReflectImprove =
      '$_illusBase/Practice Reflect Improve.webp';
  static const String illusPrivatePracticeSpace =
      '$_illusBase/Private Practice Space.webp';
  static const String illusPushbackPractice =
      '$_illusBase/Pushback Practice.webp';
  static const String illusQuietTeamMemberPersona =
      '$_illusBase/Quiet Team Member Persona.webp';
  static const String illusQuoteHighlight = '$_illusBase/Quote Highlight.webp';
  static const String illusRechargeRitual = '$_illusBase/Recharge Ritual.webp';
  static const String illusReflectionMirror =
      '$_illusBase/Reflection Mirror.webp';
  static const String illusRemoteTeammatePersona =
      '$_illusBase/Remote Teammate Persona.webp';
  static const String illusSafeRehearsalRoom =
      '$_illusBase/Safe Rehearsal Room.webp';
  static const String illusSafeVideoRoleplay =
      '$_illusBase/Safe Video Roleplay.webp';
  static const String illusScriptBuilder = '$_illusBase/Script Builder.webp';
  static const String illusSelfDoubtCloud = '$_illusBase/Self-Doubt Cloud.webp';
  static const String illusSituationActionImpact =
      '$_illusBase/Situation-Action-Impact.webp';
  static const String illusSpeakingPace = '$_illusBase/Speaking Pace.webp';
  static const String illusToneAwareness = '$_illusBase/Tone Awareness.webp';
  static const String illusToughFeedbackMoment =
      '$_illusBase/Tough Feedback Moment.webp';
  static const String illusVoiceRoleplay = '$_illusBase/Voice Roleplay.webp';

  // ==========================================
  // --- Semantic & Backward-Compatible Aliases ---
  // ==========================================
  static const String flightSimulatorCockpit =
      '$_illusBase/Private Practice Space.webp';
  static const String welcomeOnboardingGuide =
      '$_illusBase/Manager Journey Map.webp';
  static const String calmPlanetBalance = '$_illusBase/Mindset Reset.webp';
  static const String careFrameworkPebbles = '$_illusBase/CARE Framework.webp';
  static const String careerCompassNavigation =
      '$_illusBase/Leadership Compass.webp';
  static const String activeListeningEmpathy =
      '$_illusBase/Active Listening.webp';
  static const String aiAnalyticsPondering = '$_illusBase/Coach Thinking.webp';
  static const String aiPuzzleProblemSolving =
      '$_illusBase/Difficult Conversation Arena.webp';
  static const String aiStarCelebration = '$_illusBase/Executive Challenge.webp';
  static const String aiWhisperCoachAssist = '$_illusBase/AI Coach Whisper.webp';
  static const String ascendingConfidenceArrow =
      '$_illusBase/Clarity Meter.webp';
  static const String audioVoiceCoachInteraction =
      '$_illusBase/Voice Roleplay.webp';
  static const String batteryExhaustionRecovery =
      '$_illusBase/Burnout Battery.webp';
  static const String bidirectionalDialogueExchange =
      '$_illusBase/Conversation Rewind.webp';
  static const String chaosToClarityBullet = '$_illusBase/Better Response.webp';
  static const String choosePersonaCards = '$_illusBase/Persona Selector.webp';
  static const String coachDebriefTimeline = '$_illusBase/Coach Debrief.webp';
  static const String coachingBlueprintMap =
      '$_illusBase/Conversation Blueprint.webp';
  static const String coffeeChatDiscussion = '$_illusBase/Manager 1-1.webp';
  static const String collaborativeBookStudy =
      '$_illusBase/Micro-Learning Stack.webp';
  static const String confidenceGaugeEmpowerment =
      '$_illusBase/Confidence Meter.webp';
  static const String conflictConversationWave =
      '$_illusBase/Conflict Bridge.webp';
  static const String conversationBranchesChoice =
      '$_illusBase/Difficult Conversations Path.webp';
  static const String curiousPersonaInterviewee =
      '$_illusBase/New Hire Persona.webp';
  static const String deescalationSmoothWave =
      '$_illusBase/Pause & Reframe.webp';
  static const String emotionalIntelligenceSpectrum =
      '$_illusBase/Mood Constellation.webp';
  static const String energyBalanceHarmony = '$_illusBase/Energy Check-In.webp';
  static const String feedbackSandwichLevels =
      '$_illusBase/Feedback Sandwich Visual.webp';
  static const String firmExecutiveStakeholder =
      '$_illusBase/Demanding Executive Persona.webp';
  static const String focusedWorkspaceCapsule =
      '$_illusBase/Script Builder.webp';
  static const String growthMentorshipPresentation =
      '$_illusBase/Case Study Scene.webp';
  static const String heartLensCompassion = '$_illusBase/Empathy Lens.webp';
  static const String keyQuoteTimestampBadge =
      '$_illusBase/Quote Highlight.webp';
  static const String leadershipPedestalSteps =
      '$_illusBase/Executive Challenge.webp';
  static const String leadershipToolkitCase =
      '$_illusBase/Leadership Toolkit.webp';
  static const String learningPathMilestones =
      '$_illusBase/Manager Journey Map.webp';
  static const String mindfulPauseReflection =
      '$_illusBase/Confidence Check-In.webp';
  static const String mindfulnessRechargeLotus =
      '$_illusBase/Recharge Ritual.webp';
  static const String mirrorAffirmationConfidence =
      '$_illusBase/Reflection Mirror.webp';
  static const String modularLessonCards = '$_illusBase/Lesson Capsule.webp';
  static const String mountainPathFlagSummit =
      '$_illusBase/Difficult Conversations Path.webp';
  static const String multimodalVoiceAiOrb =
      '$_illusBase/Emotional Check-In Orb.webp';
  static const String navigatingUncertaintyPath =
      '$_illusBase/Difficult Conversations Path.webp';
  static const String nervousToRelaxedTransition =
      '$_illusBase/Safe Rehearsal Room.webp';
  static const String overthinkingComfortBot =
      '$_illusBase/Self-Doubt Cloud.webp';
  static const String overwhelmedWorkloadStudent =
      '$_illusBase/Overwhelmed Employee Persona.webp';
  static const String passionMotivationFlame =
      '$_illusBase/Energy Check-In.webp';
  static const String peerCoachingDialogue =
      '$_illusBase/Safe Video Roleplay.webp';
  static const String pitchIntonationTelemetry =
      '$_illusBase/Speaking Pace.webp';
  static const String practiceIterationLoop =
      '$_illusBase/Practice Reflect Improve.webp';
  static const String practiceStudioSimulation =
      '$_illusBase/Safe Rehearsal Room.webp';
  static const String profileProficiencyRing = '$_illusBase/Clarity Meter.webp';
  static const String psychologicalSafetyBubble =
      '$_illusBase/Private Practice Space.webp';
  static const String puzzleBridgeCollaboration =
      '$_illusBase/Pushback Practice.webp';
  static const String reflectiveJournalGrowth =
      '$_illusBase/Journal Reflection.webp';
  static const String shadowBreakthroughTransformation =
      '$_illusBase/High Performer Persona.webp';
  static const String situationActionImpactCards =
      '$_illusBase/Situation-Action-Impact.webp';
  static const String skepticalPersonaInterviewee =
      '$_illusBase/Defensive Direct Report Persona.webp';
  static const String skillTreeGrowth = '$_illusBase/Leadership Toolkit.webp';
  static const String soloMountainAscent =
      '$_illusBase/Difficult Conversations Path.webp';
  static const String springResilienceDecompression =
      '$_illusBase/Imposter Syndrome.webp';
  static const String studentSpeakingExplaining =
      '$_illusBase/Tough Feedback Moment.webp';
  static const String studentThinkingPensive =
      '$_illusBase/Quiet Team Member Persona.webp';
  static const String sunriseWindowVision =
      '$_illusBase/Daily Reflection Window.webp';
  static const String tangledToGrowthArrow = '$_illusBase/Better Response.webp';
  static const String teamGrowthVector =
      '$_illusBase/Remote Teammate Persona.webp';
  static const String teamPuzzleAlignment = '$_illusBase/Pushback Practice.webp';
  static const String transformationSteppingForward =
      '$_illusBase/Practice Reflect Improve.webp';
  static const String triadFeedbackCycle =
      '$_illusBase/Conversation Rewind.webp';
  static const String untanglingComplexityBot =
      '$_illusBase/Self-Doubt Cloud.webp';
  static const String videoCallAiTutor = '$_illusBase/Safe Video Roleplay.webp';
  static const String virtualSessionScreen =
      '$_illusBase/Safe Rehearsal Room.webp';
  static const String vocalToneMicrophone = '$_illusBase/Tone Awareness.webp';

  // ==========================================
  // --- 48 Illustrated Icons (Untouched) ---
  // ==========================================
  static const String iconBadgeRibbonStar =
      '$_iconBase/icon_badge_ribbon_star.png';
  static const String iconBatteryCharging =
      '$_iconBase/icon_battery_charging.png';
  static const String iconBellAlert = '$_iconBase/icon_bell_alert.png';
  static const String iconBinocularsExplore =
      '$_iconBase/icon_binoculars_explore.png';
  static const String iconBookOpen = '$_iconBase/icon_book_open.png';
  static const String iconBrainAiMind = '$_iconBase/icon_brain_ai_mind.png';
  static const String iconChatBubbles = '$_iconBase/icon_chat_bubbles.png';
  static const String iconChecklistClipboard =
      '$_iconBase/icon_checklist_clipboard.png';
  static const String iconCloud = '$_iconBase/icon_cloud.png';
  static const String iconCloudDownload = '$_iconBase/icon_cloud_download.png';
  static const String iconCloudUpload = '$_iconBase/icon_cloud_upload.png';
  static const String iconDatabaseStorage =
      '$_iconBase/icon_database_storage.png';
  static const String iconDocumentFile = '$_iconBase/icon_document_file.png';
  static const String iconDocumentPencil =
      '$_iconBase/icon_document_pencil.png';
  static const String iconEmailNotification =
      '$_iconBase/icon_email_notification.png';
  static const String iconFlagMilestone = '$_iconBase/icon_flag_milestone.png';
  static const String iconFolderSettingsGear =
      '$_iconBase/icon_folder_settings_gear.png';
  static const String iconFolderUpload = '$_iconBase/icon_folder_upload.png';
  static const String iconGlobeWorld = '$_iconBase/icon_globe_world.png';
  static const String iconGraduationCap = '$_iconBase/icon_graduation_cap.png';
  static const String iconHandshakePartnership =
      '$_iconBase/icon_handshake_partnership.png';
  static const String iconHeartCareHand = '$_iconBase/icon_heart_care_hand.png';
  static const String iconHeartbeatPulseHealth =
      '$_iconBase/icon_heartbeat_pulse_health.png';
  static const String iconHourglassTimer =
      '$_iconBase/icon_hourglass_timer.png';
  static const String iconInboxTray = '$_iconBase/icon_inbox_tray.png';
  static const String iconLaptopComputer =
      '$_iconBase/icon_laptop_computer.png';
  static const String iconLightbulbIdea = '$_iconBase/icon_lightbulb_idea.png';
  static const String iconLinkChain = '$_iconBase/icon_link_chain.png';
  static const String iconMagicWand = '$_iconBase/icon_magic_wand.png';
  static const String iconSparkleStarsMagic = '$_iconBase/icon_magic_wand.png';
  static const String iconMapPinLocation =
      '$_iconBase/icon_map_pin_location.png';
  static const String iconMoonStarsNight =
      '$_iconBase/icon_moon_stars_night.png';
  static const String iconPaperAirplaneSend =
      '$_iconBase/icon_paper_airplane_send.png';
  static const String iconPottedPlant = '$_iconBase/icon_potted_plant.png';
  static const String iconPuzzlePieces = '$_iconBase/icon_puzzle_pieces.png';
  static const String iconQuoteBubble = '$_iconBase/icon_quote_bubble.png';
  static const String iconRocketLaunch = '$_iconBase/icon_rocket_launch.png';
  static const String iconSeedlingGrowth =
      '$_iconBase/icon_seedling_growth.png';
  static const String iconShareExternal = '$_iconBase/icon_share_external.png';
  static const String iconShieldVerified =
      '$_iconBase/icon_shield_verified.png';
  static const String iconSlidersSettingsTune =
      '$_iconBase/icon_sliders_settings_tune.png';
  static const String iconStopwatchSpeed =
      '$_iconBase/icon_stopwatch_speed.png';
  static const String iconSunDayBrightness =
      '$_iconBase/icon_sun_day_brightness.png';
  static const String iconTargetBullseye =
      '$_iconBase/icon_target_bullseye.png';
  static const String iconTrashBinDelete =
      '$_iconBase/icon_trash_bin_delete.png';
  static const String iconTrophyCup = '$_iconBase/icon_trophy_cup.png';
  static const String iconUserProfile = '$_iconBase/icon_user_profile.png';
  static const String iconUsersGroup = '$_iconBase/icon_users_group.png';
  static const String iconWifiSignal = '$_iconBase/icon_wifi_signal.png';
}

class AppAvatar extends StatelessWidget {
  final String asset;
  final double size;
  final Color backgroundColor;
  final double borderWidth;
  final Color borderColor;

  const AppAvatar(
    this.asset, {
    super.key,
    this.size = 48,
    this.backgroundColor = const Color(0xFFF1EDFF),
    this.borderWidth = 2,
    this.borderColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final pixelSize = (size * MediaQuery.devicePixelRatioOf(context)).ceil();
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Image.asset(
        asset,
        fit: BoxFit.cover,
        cacheWidth: pixelSize,
        cacheHeight: pixelSize,
        errorBuilder: (_, __, ___) => Icon(
          Icons.person_rounded,
          size: size * .48,
          color: const Color(0xFF7C5CE7),
        ),
      ),
    );
  }
}

/// Reusable illustrated icon widget
class AppIcon extends StatelessWidget {
  final String asset;
  final double size;
  final Color? color;
  final BoxFit fit;

  const AppIcon(
    this.asset, {
    super.key,
    this.size = 24,
    this.color,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final pixelSize = (size * MediaQuery.devicePixelRatioOf(context)).ceil();
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: fit,
      color: color,
      cacheWidth: pixelSize,
      cacheHeight: pixelSize,
      errorBuilder: (_, __, ___) => SizedBox(width: size, height: size),
    );
  }
}

/// Reusable illustrated hero or inline visual widget
class AppIllustration extends StatelessWidget {
  final String asset;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;

  const AppIllustration(
    this.asset, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    return Image.asset(
      asset,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      cacheWidth: width == null ? null : (width! * pixelRatio).ceil(),
      cacheHeight: height == null ? null : (height! * pixelRatio).ceil(),
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height ?? 120,
          color: const Color(0xFFF2ECE1),
          alignment: Alignment.center,
          child: const SizedBox.shrink(),
        );
      },
    );
  }
}
