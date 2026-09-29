import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import 'backend_service.dart';
import 'call_controller.dart';
import 'supabase_service.dart';

/// Runs the same authenticated call client in Android WebView or iOS WKWebView.
class GeminiLiveEmbedView extends StatefulWidget {
  final String conversationUrl;
  final String sessionId;
  final String mode;
  final CallController? controller;
  final String realtimeProvider;
  final bool microphoneEnabled;
  final bool cameraEnabled;
  final String personaId;
  final String personaName;
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
    this.onEvent,
    this.onLoaded,
  });

  @override
  State<GeminiLiveEmbedView> createState() => _GeminiLiveEmbedViewState();
}

class _GeminiLiveEmbedViewState extends State<GeminiLiveEmbedView> {
  static const _permissionChannel = MethodChannel('hardsync/media_permissions');
  late final WebViewController _web;
  Completer<void>? _finished;
  bool _sentConfiguration = false;

  @override
  void initState() {
    super.initState();
    PlatformWebViewControllerCreationParams params =
        const PlatformWebViewControllerCreationParams();
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    }
    _web =
        WebViewController.fromPlatformCreationParams(
            params,
            onPermissionRequest: _requestWebPermission,
          )
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(const Color(0x00000000))
          ..addJavaScriptChannel('HardSync', onMessageReceived: _onMessage);

    // Android WebView otherwise refuses to autoplay the avatar's video+audio
    // reply since it starts asynchronously (via a websocket message), well
    // after the "Begin Call" tap that opened this page - Chromium only treats
    // that as a valid activation for a few seconds, not the whole call.
    final platform = _web.platform;
    if (platform is AndroidWebViewController) {
      unawaited(platform.setMediaPlaybackRequiresUserGesture(false));
    }

    widget.controller?.finish = _finish;
    widget.controller?.toggleMic = () => _send({'type': 'toggle_mic'});
    widget.controller?.toggleCamera = () => _send({'type': 'toggle_camera'});
    widget.controller?.joinAudio = () => _send({'type': 'join'});

    unawaited(_web.loadRequest(BackendService.uri('/live_call.html')));
  }

  Future<void> _requestWebPermission(WebViewPermissionRequest request) async {
    final hasMic = request.types.contains(
      WebViewPermissionResourceType.microphone,
    );
    final hasCamera = request.types.contains(
      WebViewPermissionResourceType.camera,
    );
    if (!hasMic && !hasCamera) {
      await request.deny();
      return;
    }

    // A thrown channel error (e.g. a request already in flight) must still
    // resolve the WebView's request, or getUserMedia hangs with no prompt.
    bool? granted;
    try {
      granted = await _permissionChannel.invokeMethod<bool>('request', {
        'microphone': hasMic,
        'camera': hasCamera,
      });
    } catch (_) {
      granted = false;
    }
    if (granted == true) {
      await request.grant();
    } else {
      await request.deny();
      widget.onEvent?.call({
        'type': 'user-action-required',
        'message':
            'Allow microphone${hasCamera ? ' and camera' : ''} access in Settings to join the call.',
      });
    }
  }

  void _onMessage(JavaScriptMessage message) {
    try {
      final event = jsonDecode(message.message) as Map<String, dynamic>;
      if (event['type'] == 'ready') {
        _configure();
        widget.onLoaded?.call();
      } else if (event['type'] == 'finished') {
        if (_finished != null && !_finished!.isCompleted) _finished!.complete();
      } else {
        widget.onEvent?.call(event);
      }
    } catch (_) {
      // Ignore malformed messages from the embedded call page.
    }
  }

  void _configure() {
    if (_sentConfiguration) return;
    _sentConfiguration = true;
    final config = <String, Object?>{
      'type': 'init',
      'sessionId': widget.sessionId,
      'mode': widget.mode,
      'auth':
          SupabaseService.instance.client?.auth.currentSession?.accessToken ??
          '',
      'url': widget.conversationUrl,
      'avatarUrl': BackendService.uri(
        widget.personaId.isNotEmpty
            ? '/call-assets/persona/${widget.personaId}.png'
            : '/call-assets/ai-avatar.png',
      ).toString(),
      'personaName': widget.personaName,
      'realtimeProvider': widget.realtimeProvider,
      'mic': widget.microphoneEnabled,
      'video': widget.cameraEnabled,
      // The Flutter "Begin Call" button the user just tapped IS the required
      // user gesture (mediaTypesRequiringUserAction is also cleared for
      // WKWebView below), so join immediately rather than asking again.
      'autoJoin': true,
    };
    final data = jsonEncode(jsonEncode(config));
    unawaited(
      _web.runJavaScript('window.postMessage($data, "*");'),
    );
  }

  Future<void> _send(Map<String, Object?> message) async {
    final data = jsonEncode(jsonEncode(message));
    try {
      await _web.runJavaScript('window.postMessage($data, "*");');
    } catch (_) {
      // The call page may already be closing.
    }
  }

  Future<void> _finish() async {
    _finished ??= Completer<void>();
    await _send({'type': 'finish'});
    try {
      await _finished!.future.timeout(const Duration(seconds: 8));
    } catch (_) {
      // Don't block the user from leaving the call screen if teardown stalls.
    }
  }

  @override
  void didUpdateWidget(covariant GeminiLiveEmbedView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionId != widget.sessionId ||
        oldWidget.realtimeProvider != widget.realtimeProvider ||
        oldWidget.conversationUrl != widget.conversationUrl) {
      _sentConfiguration = false;
      _finished = null;
      unawaited(_web.loadRequest(BackendService.uri('/live_call.html')));
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.finish = null;
      oldWidget.controller?.toggleMic = null;
      oldWidget.controller?.toggleCamera = null;
      oldWidget.controller?.joinAudio = null;
      widget.controller?.finish = _finish;
      widget.controller?.toggleMic = () => _send({'type': 'toggle_mic'});
      widget.controller?.toggleCamera = () => _send({'type': 'toggle_camera'});
      widget.controller?.joinAudio = () => _send({'type': 'join'});
    }
  }

  @override
  void dispose() {
    widget.controller?.finish = null;
    widget.controller?.toggleMic = null;
    widget.controller?.toggleCamera = null;
    widget.controller?.joinAudio = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _web);
}
