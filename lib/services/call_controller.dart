class CallController {
  /// Returns `{'mimeType': String, 'replaySaved': bool}` when the call page
  /// finished uploading an opted-in recording, or null otherwise.
  Future<Map<String, dynamic>?> Function()? finish;
  void Function()? toggleMic;
  void Function()? toggleCamera;
  void Function()? joinAudio;
}
