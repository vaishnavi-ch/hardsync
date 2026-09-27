// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/env_config.dart';
import '../providers/settings_provider.dart';
import '../providers/simulation_provider.dart';
import '../services/call_controller.dart';
import '../services/gemini_live_embed_view.dart';
import '../theme/hardsync_assets.dart';
import '../theme/hardsync_theme.dart';
import 'session_detail_screen.dart';

class LiveCallScreen extends StatefulWidget {
  const LiveCallScreen({super.key});

  @override
  State<LiveCallScreen> createState() => _LiveCallScreenState();
}

class _LiveCallScreenState extends State<LiveCallScreen> {
  final _input = TextEditingController();
  final _callController = CallController();
  SimulationProvider? _simulation;
  bool _openedReport = false;
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _needsAudioTap = false;
  bool _leaveAfterFinish = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _simulation ??= context.read<SimulationProvider>();
    _simulation!.finishMedia = () async {
      return await _callController.finish?.call();
    };
  }

  @override
  void dispose() {
    _simulation?.finishMedia = null;
    _input.dispose();
    super.dispose();
  }

  Future<void> _finish(
    SimulationProvider sim, {
    bool returnToPrevious = false,
  }) async {
    if (returnToPrevious) _leaveAfterFinish = true;
    await sim.endCall();
    if (!mounted) return;
    if (!mounted) return;
    if (returnToPrevious || sim.savedSessionId == null) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sim = context.watch<SimulationProvider>();
    final settings = context.read<SettingsProvider>();
    final ended = sim.callState == CallState.ended;

    if (ended &&
        sim.savedSessionId != null &&
        !sim.isGeneratingDebrief &&
        !_leaveAfterFinish &&
        !_openedReport) {
      _openedReport = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => SessionDetailScreen(
                sessionId: sim.savedSessionId!,
                autoAnalyze: true,
              ),
            ),
          );
        }
      });
    }

    return PopScope(
      canPop: ended && !sim.isGeneratingDebrief,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finish(sim, returnToPrevious: true);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1612),
        body: sim.isTextOnly
            ? _buildTextOnlyLayout(sim)
            : sim.isAudioOnly
            ? _buildAudioCallLayout(sim, settings, ended)
            : _buildImmersiveMediaLayout(sim, settings, ended),
      ),
    );
  }

  Widget _buildAudioCallLayout(
    SimulationProvider sim,
    SettingsProvider settings,
    bool ended,
  ) {
    final lastUtterance = sim.transcript.isEmpty ? null : sim.transcript.last;
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [HardSyncColors.cream, Color(0xFFF0EAFE)],
              ),
            ),
          ),
        ),
        if (sim.geminiLiveUrl != null && !ended)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: kIsWeb || sim.callState != CallState.connecting,
              child: Opacity(
                opacity: !kIsWeb && sim.callState == CallState.connecting
                    ? 1
                    : 0,
                child: GeminiLiveEmbedView(
                  conversationUrl: sim.geminiLiveUrl!,
                  sessionId: sim.currentSessionId ?? '',
                  mode: sim.callMode.name,
                  controller: _callController,
                  realtimeProvider: sim.realtimeProvider,
                  microphoneEnabled: settings.micEnabled,
                  cameraEnabled: false,
                  personaId: sim.activeCounterpart.id,
                  replayUploadUrl: sim.replayUploadUrl,
                  onEvent: (event) {
                    if (event['type'] == 'user-action-required') {
                      if (mounted) setState(() => _needsAudioTap = true);
                    } else {
                      if (event['type'] == 'connected' && _needsAudioTap) {
                        setState(() => _needsAudioTap = false);
                      }
                      sim.providerEvent(event);
                    }
                  },
                ),
              ),
            ),
          ),
        if (kIsWeb || sim.callState != CallState.connecting)
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => _finish(sim, returnToPrevious: true),
                        icon: const Icon(Icons.arrow_back_rounded),
                        tooltip: 'End call and go back',
                      ),
                      const Expanded(
                        child: Text('Voice call', textAlign: TextAlign.center),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .75),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(sim.formattedTimer),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 236,
                        height: 236,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: HardSyncColors.lilacMist,
                          boxShadow: [
                            BoxShadow(
                              color: HardSyncColors.violet.withValues(
                                alpha: .16,
                              ),
                              blurRadius: 38,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: AppAvatar(
                          sim.activeCounterpart.avatarAsset,
                          size: 212,
                          backgroundColor: Colors.white,
                          borderColor: Colors.white,
                          borderWidth: 4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        sim.activeCounterpart.name,
                        style: GoogleFonts.newsreader(
                          color: HardSyncColors.ink,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (_needsAudioTap) ...[
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: Text(
                            'Tap below to allow microphone access and start the call.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              color: HardSyncColors.inkMuted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        FilledButton(
                          onPressed: _callController.joinAudio,
                          child: const Text('Start audio call'),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        sim.callState == CallState.connecting
                            ? 'Connecting…'
                            : sim.callState == CallState.inCall
                            ? 'Listening…'
                            : 'Call ended',
                        style: GoogleFonts.plusJakartaSans(
                          color: HardSyncColors.inkMuted,
                          fontSize: 14,
                        ),
                      ),
                      if (sim.callState == CallState.inCall) ...[
                        const SizedBox(height: 8),
                        Text(
                          sim.isRecording
                              ? 'Recording this session for playback later'
                              : 'Live call only · audio and video are not saved',
                          style: GoogleFonts.plusJakartaSans(
                            color: HardSyncColors.inkMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      _AudioWaveform(active: sim.isBusy),
                      if (lastUtterance != null) ...[
                        const SizedBox(height: 22),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Text(
                            '${lastUtterance.speakerName}: ${lastUtterance.text}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              color: HardSyncColors.ink,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildAudioAction(
                        icon: _isMuted ? Icons.mic_off : Icons.mic,
                        label: _isMuted ? 'Unmute' : 'Mute',
                        onTap: () {
                          setState(() => _isMuted = !_isMuted);
                          _callController.toggleMic?.call();
                        },
                      ),
                      const SizedBox(width: 42),
                      _buildAudioAction(
                        icon: Icons.call_end_rounded,
                        label: 'End call',
                        destructive: true,
                        onTap: sim.isGeneratingDebrief
                            ? null
                            : () => _finish(sim),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAudioAction({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool destructive = false,
  }) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Material(
        color: destructive ? const Color(0xFFC75438) : Colors.white,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 58,
            height: 58,
            child: Icon(
              icon,
              color: destructive ? Colors.white : HardSyncColors.ink,
            ),
          ),
        ),
      ),
      const SizedBox(height: 7),
      Text(label, style: const TextStyle(color: HardSyncColors.inkMuted)),
    ],
  );

  /// Full-screen layout with rich counterpart stage, audio aura, coach HUD, and clean action dock
  Widget _buildImmersiveMediaLayout(
    SimulationProvider sim,
    SettingsProvider settings,
    bool ended,
  ) {
    final counterpartName = sim.activeCounterpart.name;
    final scenarioTitle = sim.activeScenario?.title ?? 'Managing Former Peer';
    final lastUtterance = sim.transcript.isNotEmpty
        ? sim.transcript.last
        : null;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Full-screen Video Player or Illustrated Rehearsal Room
        if (sim.geminiLiveUrl != null && !ended)
          Positioned.fill(
            child: GeminiLiveEmbedView(
              conversationUrl: sim.geminiLiveUrl!,
              sessionId: sim.currentSessionId ?? '',
              mode: sim.callMode.name,
              controller: _callController,
              realtimeProvider: sim.realtimeProvider,
              microphoneEnabled: settings.micEnabled,
              cameraEnabled: sim.isVideoActive && settings.cameraEnabled,
              personaId: sim.activeCounterpart.id,
              replayUploadUrl: sim.replayUploadUrl,
              onEvent: sim.providerEvent,
            ),
          )
        else
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.2),
                  radius: 1.1,
                  colors: [
                    Color(0xFF192D23),
                    Color(0xFF101814),
                    Color(0xFF080A09),
                  ],
                ),
              ),
              child: ended
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AppIllustration(
                            HardSyncAssets.aiStarCelebration,
                            height: 140,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 16),
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Color(0xFF76D8A2),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            sim.isGeneratingDebrief
                                ? 'Finalizing your executive debrief...'
                                : sim.error != null
                                ? 'Could not connect'
                                : 'Session completed',
                            style: GoogleFonts.newsreader(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (sim.error != null) ...[
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Text(
                                sim.error!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Atmospheric Character Stage with Pulsing Halo
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(
                                  0xFF224838,
                                ).withOpacity(0.35),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF76D8A2,
                                    ).withOpacity(0.18),
                                    blurRadius: 40,
                                    spreadRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            AppAvatar(
                              sim.activeCounterpart.avatarAsset,
                              size: 180,
                              backgroundColor: const Color(0xFFF1EDFF),
                              borderColor: Colors.white.withOpacity(0.85),
                              borderWidth: 5,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          counterpartName,
                          style: GoogleFonts.newsreader(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sim.callState == CallState.connecting
                              ? 'Connecting to counterpart...'
                              : sim.isBusy
                              ? 'Speaking...'
                              : 'Listening to you...',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF9EABA4),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

        if (sim.isAudioOnly && !ended)
          Positioned(
            top: MediaQuery.sizeOf(context).height * .27,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 218,
                  height: 218,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: HardSyncColors.lilacMist.withValues(alpha: .9),
                    boxShadow: [
                      BoxShadow(
                        color: HardSyncColors.violet.withValues(alpha: .24),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: AppAvatar(
                    sim.activeCounterpart.avatarAsset,
                    size: 194,
                    backgroundColor: HardSyncColors.lilacMist,
                    borderColor: Colors.white,
                    borderWidth: 4,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  counterpartName,
                  style: GoogleFonts.newsreader(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  sim.callState == CallState.connecting
                      ? 'Connecting…'
                      : sim.isBusy
                      ? 'Speaking…'
                      : 'Listening',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

        // 2. Subtle top vignette
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 190,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // 3. Subtle bottom vignette
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 240,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.9),
                  Colors.black.withOpacity(0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // 4. Floating Top Header
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Back Chevron
                      IconButton(
                        onPressed: () => _finish(sim, returnToPrevious: true),
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 18,
                        ),
                        tooltip: 'End and return',
                      ),
                      const SizedBox(width: 4),
                      // Title & Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$scenarioTitle ($counterpartName)',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Live Roleplay Rehearsal',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white70,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Active Call Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.22),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFF76D8A2),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              sim.callState == CallState.connecting
                                  ? 'Connecting'
                                  : sim.callState == CallState.inCall
                                  ? 'Active'
                                  : 'Ended',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Timer Pill (+ recording indicator, when opted in)
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const AppIcon(
                                HardSyncAssets.iconHourglassTimer,
                                size: 12,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                sim.formattedTimer,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (sim.isRecording) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC75438).withOpacity(0.85),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Recording',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 5. Live Gemini Vision Read (real confidence/expression, video only)
        if (sim.isVideoActive && sim.liveConfidenceScore != null)
          Positioned(
            top: 115,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C5CE7).withOpacity(0.22),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${sim.liveConfidenceScore}',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Confidence • ${sim.liveExpression ?? ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFFC9B8FF),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if ((sim.liveEyeContact ?? '').isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '• ${sim.liveEyeContact}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white54,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if ((sim.liveCoachTip ?? '').isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            sim.liveCoachTip!,
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFE2EBE5),
                              fontSize: 11.5,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

        // 6. Floating Speaking Telemetry Wave & Live Subtitle Pill
        Positioned(
          left: 20,
          right: 20,
          bottom: 120,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Speaking Waveform Banner
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.72),
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: Colors.white.withOpacity(0.14)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppIllustration(
                      HardSyncAssets.multimodalVoiceAiOrb,
                      height: 14,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      sim.callState == CallState.connecting
                          ? 'Connecting with $counterpartName...'
                          : sim.isBusy
                          ? '$counterpartName speaking'
                          : 'Listening to you',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF76D8A2),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const AppIllustration(
                      HardSyncAssets.pitchIntonationTelemetry,
                      height: 12,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Live Subtitle Transcript Bubble
              if (lastUtterance != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${lastUtterance.speakerName}: ',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF76D8A2),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: lastUtterance.text,
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFFE2EBE5),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // 7. Bottom Control Dock
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 22, top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // MUTE
                  _buildCircularActionButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    label: _isMuted ? 'Unmute' : 'Mute',
                    backgroundColor: _isMuted
                        ? const Color(0xFF3A4740)
                        : Colors.white.withOpacity(0.2),
                    iconColor: Colors.white,
                    onTap: () {
                      setState(() => _isMuted = !_isMuted);
                      _callController.toggleMic?.call();
                    },
                  ),

                  // CAMERA (When in video mode)
                  if (sim.isVideoActive)
                    _buildCircularActionButton(
                      icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
                      label: _isCameraOff ? 'Camera On' : 'Camera',
                      backgroundColor: _isCameraOff
                          ? const Color(0xFF3A4740)
                          : Colors.white.withOpacity(0.2),
                      iconColor: Colors.white,
                      onTap: () {
                        setState(() => _isCameraOff = !_isCameraOff);
                        _callController.toggleCamera?.call();
                      },
                    ),

                  // END CALL
                  _buildCircularActionButton(
                    icon: Icons.call_end,
                    label: 'End Call',
                    backgroundColor: const Color(0xFFC75438),
                    iconColor: Colors.white,
                    isLoading: sim.isGeneratingDebrief,
                    onTap: sim.isGeneratingDebrief ? null : () => _finish(sim),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCircularActionButton({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: backgroundColor,
              border: Border.all(color: Colors.white.withOpacity(0.18)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Icon(icon, color: iconColor, size: 22),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white.withOpacity(0.85),
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Elevated text chat mode layout with conversation bubbles & clean composer
  Widget _buildTextOnlyLayout(SimulationProvider sim) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => _finish(sim),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: Color(0xFF1B1715),
          ),
        ),
        title: Row(
          children: [
            AppAvatar(
              sim.activeCounterpart.avatarAsset,
              size: 44,
              borderWidth: 1,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sim.activeScenario?.title ?? 'Text Practice Drill',
                    style: GoogleFonts.newsreader(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1B1715),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      const AppIcon(
                        HardSyncAssets.iconHourglassTimer,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        sim.formattedTimer,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF224838),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: sim.isGeneratingDebrief ? null : () => _finish(sim),
            child: Text(
              sim.isGeneratingDebrief ? 'Saving...' : 'End Drill',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFC75438),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (EnvConfig.testCalls)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              color: const Color(0xFFFEF4E4),
              child: Row(
                children: [
                  const AppIcon(
                    HardSyncAssets.iconSlidersSettingsTune,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Local test simulation mode active',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF8B6B2B),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: sim.transcript.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppIllustration(
                            sim.error == null
                                ? HardSyncAssets.illusConversationBlueprint
                                : HardSyncAssets.illusPauseAndReframe,
                            height: 180,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            sim.error == null
                                ? 'Preparing your conversation…'
                                : 'Could not start this drill',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.newsreader(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1B1715),
                            ),
                          ),
                          if (sim.error != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              sim.error!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                height: 1.4,
                                color: const Color(0xFF6E655E),
                              ),
                            ),
                            const SizedBox(height: 18),
                            FilledButton(
                              onPressed: sim.canRetryStarting
                                  ? sim.retryStart
                                  : () => _finish(sim, returnToPrevious: true),
                              child: Text(
                                sim.canRetryStarting ? 'Retry' : 'Go back',
                              ),
                            ),
                          ] else
                            const Padding(
                              padding: EdgeInsets.only(top: 16),
                              child: CircularProgressIndicator(),
                            ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: sim.transcript.length + (sim.isBusy ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == sim.transcript.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              AppAvatar(
                                sim.activeCounterpart.avatarAsset,
                                size: 30,
                                borderWidth: 1,
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFE5DFD5),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF7C5CE7),
                                      ),
                                    ),
                                    const SizedBox(width: 9),
                                    Text(
                                      '${sim.activeCounterpart.name} is replying...',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.5,
                                        color: const Color(0xFF6E655E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      final turn = sim.transcript[index];
                      final isUser = turn.isUser;

                      final avatar = AppAvatar(
                        isUser
                            ? HardSyncAssets.avatarCurrentUser
                            : sim.activeCounterpart.avatarAsset,
                        size: 40,
                        borderWidth: 1,
                      );

                      final bubble = Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.78,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isUser
                              ? const Color(0xFF224838)
                              : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isUser ? 16 : 4),
                            bottomRight: Radius.circular(isUser ? 4 : 16),
                          ),
                          border: isUser
                              ? null
                              : Border.all(color: const Color(0xFFE5DFD5)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              turn.speakerName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: isUser
                                    ? const Color(0xFF76D8A2)
                                    : const Color(0xFF7A726C),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              turn.text,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                color: isUser
                                    ? Colors.white
                                    : const Color(0xFF1B1715),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      );

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: isUser
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: isUser
                              ? [bubble, const SizedBox(width: 8), avatar]
                              : [avatar, const SizedBox(width: 8), bubble],
                        ),
                      );
                    },
                  ),
          ),
          if (sim.callState == CallState.inCall &&
              sim.error != null &&
              !sim.isBusy)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 6, 16, 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0EA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF0B9A8)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFC75438),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      sim.error!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        height: 1.35,
                        color: const Color(0xFF6B3326),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: sim.retryLastTextResponse,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          if (sim.callState == CallState.inCall)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEDE8DE))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF7F2),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE5DFD5)),
                      ),
                      child: TextField(
                        controller: _input,
                        enabled: !sim.isBusy,
                        minLines: 1,
                        maxLines: 4,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          color: const Color(0xFF1B1715),
                        ),
                        decoration: InputDecoration(
                          hintText: sim.isBusy
                              ? 'Wait for counterpart to respond...'
                              : 'Type your response...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: const Color(0xFF9E968D),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (text) {
                          if (text.trim().isEmpty || sim.isBusy) return;
                          _input.clear();
                          sim.handleUserUtterance(text);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: sim.isBusy
                        ? null
                        : () {
                            final text = _input.text;
                            if (text.trim().isEmpty) return;
                            _input.clear();
                            sim.handleUserUtterance(text);
                          },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: sim.isBusy
                            ? const Color(0xFFCCC6B9)
                            : const Color(0xFF224838),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const AppIcon(
                        HardSyncAssets.iconPaperAirplaneSend,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AudioWaveform extends StatelessWidget {
  const _AudioWaveform({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    const heights = [10.0, 18.0, 26.0, 15.0, 32.0, 20.0, 12.0, 24.0, 16.0, 9.0];
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (final height in heights)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 5,
            height: active ? height : 8,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: HardSyncColors.violet.withValues(alpha: active ? .9 : .45),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
      ],
    );
  }
}
