// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'supabase_service.dart';
import 'call_controller.dart';
import 'backend_service.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

class GeminiLiveEmbedView extends StatefulWidget {
  final String conversationUrl;
  final String sessionId;
  final String mode;
  final CallController? controller;
  final String realtimeProvider;
  final bool microphoneEnabled;
  final bool cameraEnabled;
  final String personaId;
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
    this.onEvent,
    this.onLoaded,
  });
  @override
  State<GeminiLiveEmbedView> createState() => _GeminiLiveEmbedViewState();
}

class _GeminiLiveEmbedViewState extends State<GeminiLiveEmbedView> {
  static int _nextId = 0;
  Completer<void>? _finished;
  late String _viewId;
  html.IFrameElement? _iframe;
  StreamSubscription<html.MessageEvent>? _messages;
  StreamSubscription<html.Event>? _load;

  // Safe postMessage target: '*' allows localhost origins even when
  // location.origin is null (which crashes postMessage on some Flutter builds).
  // Security is provided by the iframe source identity check on incoming events.
  static const _targetOrigin = '*';

  void _post(Map<String, dynamic> msg) {
    try {
      _iframe?.contentWindow?.postMessage(jsonEncode(msg), _targetOrigin);
    } catch (_) {
      // Swallow postMessage errors (e.g. iframe not yet ready).
    }
  }

  void _configure() {
    _post({
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
      'realtimeProvider': widget.realtimeProvider,
      'mic': widget.microphoneEnabled,
      'video': widget.cameraEnabled,
    });
  }

  @override
  void initState() {
    super.initState();
    widget.controller?.finish = () async {
      if (_iframe == null) return;
      _finished ??= Completer<void>();
      _post({'type': 'finish'});
      await _finished!.future.timeout(const Duration(seconds: 10));
    };
    widget.controller?.toggleMic = () => _post({'type': 'toggle_mic'});
    widget.controller?.toggleCamera = () => _post({'type': 'toggle_camera'});
    widget.controller?.joinAudio = () => _post({'type': 'join'});

    _viewId = 'hardsync-call-${_nextId++}';
    _messages = html.window.onMessage.listen((event) {
      // Only accept messages whose source is our iframe's contentWindow.
      // We intentionally skip the origin check because location.origin can be
      // null on localhost, which would crash or incorrectly reject messages.
      if (_iframe == null || event.data is! String) return;
      final isSameSource = identical(
        js_util.getProperty<Object?>(event, 'source'),
        js_util.getProperty<Object?>(_iframe!, 'contentWindow'),
      );
      if (!isSameSource) return;
      try {
        final data = jsonDecode(event.data as String) as Map<String, dynamic>;
        if (data['type'] == 'finished') {
          if (_finished != null && !_finished!.isCompleted) {
            _finished!.complete();
          }
        } else if (data['type'] == 'ready') {
          _configure();
          widget.onLoaded?.call();
        } else {
          widget.onEvent?.call(data);
        }
      } catch (_) {
        /* Ignore unrelated frame messages. */
      }
    });
    ui_web.platformViewRegistry.registerViewFactory(_viewId, (_) {
      _iframe = html.IFrameElement()
        ..src = 'live_call.html'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allow =
            'camera *; microphone *; autoplay *; fullscreen *; display-capture *';
      // Double-configure: once on iframe load (for normal flow) and once on
      // 'ready' postMessage (for cases where JS fires before onLoad).
      _load = _iframe!.onLoad.listen((_) => _configure());
      return _iframe!;
    });
  }

  @override
  void dispose() {
    widget.controller?.finish = null;
    widget.controller?.joinAudio = null;
    widget.controller?.toggleMic = null;
    widget.controller?.toggleCamera = null;
    _messages?.cancel();
    _load?.cancel();
    _iframe?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: _viewId);
}
