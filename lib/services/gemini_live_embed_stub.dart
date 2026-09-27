import 'call_controller.dart';
import 'package:flutter/material.dart';

class GeminiLiveEmbedView extends StatelessWidget {
  final String conversationUrl;
  final String sessionId;
  final String mode;
  final CallController? controller;
  final String realtimeProvider;
  final bool microphoneEnabled;
  final bool cameraEnabled;
  final String personaId;
  final String personaName;
  final String? replayUploadUrl;
  final ValueChanged<Map<String, dynamic>>? onEvent;
  final VoidCallback? onLoaded;
  const GeminiLiveEmbedView({
    super.key,
    required this.conversationUrl,
    this.sessionId = '',
    this.mode = 'video',
    this.controller,
    this.realtimeProvider = 'gemini_live',
    this.microphoneEnabled = true,
    this.cameraEnabled = true,
    this.personaId = '',
    this.personaName = '',
    this.replayUploadUrl,
    this.onEvent,
    this.onLoaded,
  });
  @override
  Widget build(BuildContext context) => const Center(
    child: Text('Audio and video calls currently require a web browser.'),
  );
}
