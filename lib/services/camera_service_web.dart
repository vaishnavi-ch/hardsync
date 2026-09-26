// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

class CameraVisionService {
  static int _viewIdCounter = 0;
  final String _viewType = 'hardsync-camera-view-${++_viewIdCounter}';
  html.VideoElement? _videoElement;
  html.MediaStream? _mediaStream;
  bool _isStreaming = false;
  final double _gazeStability = 0;
  final bool _isLookingDown = false;

  bool get isAvailable => true;
  bool get isStreaming => _isStreaming;
  double get gazeStability => _gazeStability;
  bool get isLookingDown => _isLookingDown;

  Future<bool> startCamera() async {
    try {
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) return false;

      _mediaStream = await mediaDevices.getUserMedia({
        'video': true,
        'audio': false,
      });
      _videoElement = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.transform = 'scaleX(-1)'
        ..srcObject = _mediaStream;

      ui_web.platformViewRegistry.registerViewFactory(
        _viewType,
        (int id) => _videoElement!,
      );

      _isStreaming = true;
      return true;
    } catch (e) {
      debugPrint('[CameraVisionService] Camera access error: $e');
      _isStreaming = false;
      return false;
    }
  }

  void simulateGazeShift() {}

  void stopCamera() {
    _mediaStream?.getTracks().forEach((track) => track.stop());
    _mediaStream = null;
    _isStreaming = false;
  }

  String? captureSnapshotBase64() {
    if (_videoElement == null || !_isStreaming) return null;
    try {
      final width = _videoElement!.videoWidth > 0
          ? _videoElement!.videoWidth
          : 320;
      final height = _videoElement!.videoHeight > 0
          ? _videoElement!.videoHeight
          : 240;
      final canvas = html.CanvasElement(width: width, height: height);
      final ctx = canvas.context2D;
      ctx.drawImage(_videoElement!, 0, 0);
      final dataUrl = canvas.toDataUrl('image/jpeg', 0.65);
      return dataUrl.contains(',') ? dataUrl.split(',')[1] : dataUrl;
    } catch (e) {
      debugPrint('[CameraVisionService] Snapshot capture note: $e');
      return null;
    }
  }

  Widget buildCameraView({required Widget fallback}) {
    if (!_isStreaming) return fallback;
    return HtmlElementView(viewType: _viewType);
  }
}
