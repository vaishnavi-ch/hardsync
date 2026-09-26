import 'package:flutter/material.dart';

class CameraVisionService {
  bool get isAvailable => false;
  bool get isStreaming => false;
  double get gazeStability => 0;
  bool get isLookingDown => false;

  Future<bool> startCamera() async => false;
  void stopCamera() {}
  void simulateGazeShift() {}
  String? captureSnapshotBase64() => null;

  Widget buildCameraView({required Widget fallback}) => fallback;
}
