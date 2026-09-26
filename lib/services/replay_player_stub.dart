import 'package:flutter/material.dart';
import 'replay_controller.dart';

class ReplayPlayer extends StatelessWidget {
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
  Widget build(BuildContext context) =>
      const Text('Open this session in a web browser to play the recording.');
}
