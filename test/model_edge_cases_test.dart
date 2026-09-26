import 'package:flutter_test/flutter_test.dart';
import 'package:hardsync/models/telemetry.dart';

void main() {
  test('speech ratios are safe with empty and populated samples', () {
    expect(const SpeechMetrics().talkRatio, 0.5);
    expect(const SpeechMetrics().listenRatio, 0.5);
    const metrics = SpeechMetrics(talkTimeSeconds: 30, listenTimeSeconds: 90);
    expect(metrics.talkRatio, 0.25);
    expect(metrics.listenRatio, 0.75);
  });

  test('timestamps remain stable at zero and after one hour', () {
    const zero = DialogueTurn(
      id: 'zero',
      speaker: DialogueSpeaker.user,
      speakerName: 'You',
      text: 'Hello',
      timestamp: Duration.zero,
      tone: ConversationalTone.neutral,
    );
    expect(zero.formattedTimestamp, '00:00');
    expect(
      DialogueTurn(
        id: 'long',
        speaker: DialogueSpeaker.avatar,
        speakerName: 'Alex',
        text: 'Hello',
        timestamp: const Duration(hours: 1, seconds: 2),
        tone: ConversationalTone.neutral,
      ).formattedTimestamp,
      '60:02',
    );
  });

}
