enum BubbleRole { character, user }

class EmotionReportBubble {
  EmotionReportBubble({
    required this.role,
    required this.text,
  });

  final BubbleRole role;
  final String text;

  factory EmotionReportBubble.fromJson(Map<String, dynamic> json) {
    final rawRole = json['role'] as String?;
    return EmotionReportBubble(
      role: rawRole == 'user' ? BubbleRole.user : BubbleRole.character,
      text: json['text'] as String? ?? '',
    );
  }
}

class EmotionReportCharacterMeta {
  EmotionReportCharacterMeta({
    required this.key,
    required this.displayName,
    required this.mood,
  });

  final String key;
  final String displayName;
  final String mood;

  factory EmotionReportCharacterMeta.fromJson(Map<String, dynamic> json) {
    return EmotionReportCharacterMeta(
      key: json['key'] as String? ?? '',
      displayName:
          json['display_name'] as String? ?? json['displayName'] as String? ?? '',
      mood: json['mood'] as String? ?? '',
    );
  }
}

class EmotionReportChat {
  EmotionReportChat({
    required this.period,
    required this.headline,
    required this.character,
    required this.bubbles,
  });

  final String period;
  final String headline;
  final EmotionReportCharacterMeta character;
  final List<EmotionReportBubble> bubbles;

  factory EmotionReportChat.fromJson(Map<String, dynamic> json) {
    final bubblesJson = json['bubbles'] as List<dynamic>? ?? <dynamic>[];
    return EmotionReportChat(
      period: json['period'] as String? ?? '',
      headline: json['headline'] as String? ?? '',
      character: EmotionReportCharacterMeta.fromJson(
        (json['character'] as Map<String, dynamic>? ?? <String, dynamic>{}),
      ),
      bubbles: bubblesJson
          .map((raw) =>
              EmotionReportBubble.fromJson(raw as Map<String, dynamic>))
          .toList(),
    );
  }
}
