// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';
import 'replay_controller.dart';

class ReplayPlayer extends StatefulWidget {
  final String url;
  final bool audioOnly;
  final ReplayController controller;
  const ReplayPlayer({
    super.key,
    required this.url,
    required this.audioOnly,
    required this.controller,
  });
  @override
  State<ReplayPlayer> createState() => _ReplayPlayerState();
}

class _ReplayPlayerState extends State<ReplayPlayer> {
  static int next = 0;
  late final String id;
  late final html.MediaElement media;
  String? _error;
  @override
  void initState() {
    super.initState();
    id = 'session-replay-${next++}';
    media = widget.audioOnly ? html.AudioElement() : html.VideoElement();
    media.src = widget.url;
    media.controls = true;
    media.preload = 'metadata';
    media.onLoadedMetadata.listen((_) {
      final seconds = widget.controller.pendingSeek;
      if (seconds != null) {
        media.currentTime = seconds;
        widget.controller.pendingSeek = null;
        media.play();
      }
    });
    media.onError.listen((_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not play the recording. Refresh this session to renew its playback link.',
        );
      }
    });
    media.style.width = '100%';
    media.style.height = '100%';
    media.style.borderRadius = '16px';
    media.setAttribute(
      'aria-label',
      widget.audioOnly ? 'Session audio recording' : 'Session video recording',
    );
    ui.platformViewRegistry.registerViewFactory(id, (_) => media);
    widget.controller.seek = (seconds) {
      if (media.readyState >= 1) {
        media.currentTime = seconds;
        media.play();
        widget.controller.pendingSeek = null;
      } else {
        widget.controller.pendingSeek = seconds;
      }
    };
    widget.controller.download = () {
      html.AnchorElement(href: widget.url)
        ..download = 'rehearsal'
        ..click();
    };
  }

  @override
  void dispose() {
    media.pause();
    media.removeAttribute('src');
    media.load();
    media.remove();
    widget.controller.seek = null;
    widget.controller.download = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _error == null
      ? HtmlElementView(viewType: id)
      : Center(child: Text(_error!));
}
