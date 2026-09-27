import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../theme/hardsync_theme.dart';

class ReplayPlayerWidget extends StatefulWidget {
  final String url;
  final bool audioOnly;
  const ReplayPlayerWidget({
    super.key,
    required this.url,
    required this.audioOnly,
  });

  @override
  State<ReplayPlayerWidget> createState() => _ReplayPlayerWidgetState();
}

class _ReplayPlayerWidgetState extends State<ReplayPlayerWidget> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller
        .initialize()
        .then((_) {
          if (!mounted) return;
          setState(() => _ready = true);
          _controller.play();
        })
        .catchError((_) {
          if (!mounted) return;
          setState(
            () => _error =
                'Could not play this recording. Its link may have expired — reopen this session to renew it.',
          );
        });
    _controller.addListener(_onTick);
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: Text(_error!, textAlign: TextAlign.center),
      );
    }
    if (!_ready) {
      return const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: widget.audioOnly
                ? 16 / 6
                : (_controller.value.aspectRatio == 0
                      ? 16 / 9
                      : _controller.value.aspectRatio),
            child: widget.audioOnly
                ? Container(
                    color: const Color(0xFF224838),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.graphic_eq_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  )
                : VideoPlayer(_controller),
          ),
        ),
        VideoProgressIndicator(
          _controller,
          allowScrubbing: true,
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              iconSize: 34,
              color: HardSyncColors.violet,
              icon: Icon(
                _controller.value.isPlaying
                    ? Icons.pause_circle_filled_rounded
                    : Icons.play_circle_fill_rounded,
              ),
              onPressed: () {
                if (_controller.value.isPlaying) {
                  _controller.pause();
                } else {
                  _controller.play();
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
