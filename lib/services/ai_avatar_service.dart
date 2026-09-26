import '../models/persona.dart';
import '../models/scenario.dart';
import '../models/telemetry.dart';
import 'backend_service.dart';

enum AvatarVisualState {
  idle,
  listening,
  thinking,
  speaking,
  skeptical,
  yielding,
}

class AiAvatarService {
  AiAvatarService();
  Future<Map<String, dynamic>> generateAvatarResponse({
    required Scenario scenario,
    required Persona persona,
    required String userUtterance,
    required int defensivenessScore,
    required List<DialogueTurn> conversationHistory,
  }) async {
    final contents = conversationHistory
        .map(
          (t) => {
            'role': t.speaker == DialogueSpeaker.user ? 'user' : 'model',
            'parts': [
              {'text': t.text},
            ],
          },
        )
        .toList();
    if (conversationHistory.isEmpty ||
        conversationHistory.last.speaker != DialogueSpeaker.user ||
        conversationHistory.last.text != userUtterance.trim()) {
      contents.add({
        'role': 'user',
        'parts': [
          {'text': userUtterance.trim()},
        ],
      });
    }
    final data = await BackendService.request('/api/generate', {
      'sessionId': BackendService.sessionId,
      'payload': {
        'systemInstruction': {
          'parts': [
            {
              'text':
                  'You are role-playing ONLY as ${persona.name}, ${persona.role}, in a live rehearsal conversation. '
                  'The other speaker (the "user" messages) is the real person practicing this conversation — '
                  'never speak for them, never adopt their position, and never restate their argument back to them. '
                  'Background on ${persona.name}: ${persona.bio} '
                  'Personality: ${persona.personalityTraits}. Current defensiveness: $defensivenessScore/100 '
                  '(higher means push back and resist more before yielding). '
                  'Scenario context (for your situational awareness only — the "you" in this brief refers to the '
                  'other person, not you): ${scenario.contextBrief} '
                  'Stay fully in ${persona.name}\'s own perspective and self-interest at all times, pushing back, '
                  'deflecting, or negotiating the way ${persona.name} would. Example lines in this character\'s voice: '
                  '"${persona.pushbackPhrases.take(2).join('" / "')}". '
                  'Respond in character in 1-3 sentences of spoken dialogue only. No stage directions, no narration, no quotation marks.',
            },
          ],
        },
        'contents': contents,
        'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 384},
      },
    }, const Duration(seconds: 45));
    final candidates = data['candidates'];
    List<dynamic>? parts;
    if (candidates is List && candidates.isNotEmpty) {
      final first = candidates.first;
      final content = first is Map ? first['content'] : null;
      final rawParts = content is Map ? content['parts'] : null;
      if (rawParts is List) parts = rawParts;
    }
    final text =
        parts
            ?.whereType<Map>()
            .where((part) => part['thought'] != true)
            .map((part) => part['text'] is String ? part['text'] as String : '')
            .join()
            .trim() ??
        '';
    if (text.isEmpty) {
      throw StateError('AI returned no dialogue. Please retry.');
    }
    return {'text': text, 'state': AvatarVisualState.speaking};
  }
}
