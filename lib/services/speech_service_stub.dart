class SpeechRecognitionService {
  bool get isListening => false;

  void startListening({
    required Function(String text) onResult,
    Function(int wpm)? onWpm,
    Function(String filler)? onFiller,
    Function(String partial)? onPartial,
  }) {}

  void stopListening() {}
}
