class TemperatureInfo {
  TemperatureInfo({
    required this.score,
    required this.level,
    required this.positiveRatio,
    required this.negativeRatio,
  });

  final int score;
  final String level;
  final double positiveRatio;
  final double negativeRatio;

  factory TemperatureInfo.fromJson(Map<String, dynamic> json) {
    return TemperatureInfo(
      score: json['score'] as int? ?? 0,
      level: json['level'] as String? ?? 'neutral',
      positiveRatio: (json['positive_ratio'] as num?)?.toDouble() ?? 0,
      negativeRatio: (json['negative_ratio'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'level': level,
      'positive_ratio': positiveRatio,
      'negative_ratio': negativeRatio,
    };
  }
}

class MainEmotion {
  MainEmotion({
    required this.label,
    required this.confidence,
    required this.characterCode,
  });

  final String label;
  final double confidence;
  final String characterCode;

  factory MainEmotion.fromJson(Map<String, dynamic> json) {
    return MainEmotion(
      label: json['label'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      characterCode: json['character_code'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'confidence': confidence,
      'character_code': characterCode,
    };
  }
}

class EmotionBadge {
  EmotionBadge({
    required this.code,
    required this.label,
    required this.description,
  });

  final String code;
  final String label;
  final String description;

  factory EmotionBadge.fromJson(Map<String, dynamic> json) {
    return EmotionBadge(
      code: json['code'] as String? ?? '',
      label: json['label'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'label': label,
      'description': description,
    };
  }
}

class SummaryBubble {
  SummaryBubble({
    required this.role,
    required this.text,
    required this.emotionLabel,
  });

  final String role;
  final String text;
  final String emotionLabel;

  factory SummaryBubble.fromJson(Map<String, dynamic> json) {
    return SummaryBubble(
      role: json['role'] as String? ?? 'user',
      text: json['text'] as String? ?? '',
      emotionLabel: json['emotion_label'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'text': text,
      'emotion_label': emotionLabel,
    };
  }
}

class WeeklyEmotionReport {
  WeeklyEmotionReport({
    required this.userId,
    required this.weekStart,
    required this.weekEnd,
    required this.temperature,
    required this.mainEmotion,
    required this.badge,
    required this.summaryBubbles,
  });

  final int userId;
  final DateTime weekStart;
  final DateTime weekEnd;
  final TemperatureInfo temperature;
  final MainEmotion mainEmotion;
  final EmotionBadge badge;
  final List<SummaryBubble> summaryBubbles;

  factory WeeklyEmotionReport.fromJson(Map<String, dynamic> json) {
    final summaryList = json['summary_bubbles'] as List<dynamic>? ?? [];

    return WeeklyEmotionReport(
      userId: json['user_id'] as int? ?? 0,
      weekStart: _parseDate(json['week_start'] as String?),
      weekEnd: _parseDate(json['week_end'] as String?),
      temperature: TemperatureInfo.fromJson(
        (json['temperature'] as Map<String, dynamic>? ?? <String, dynamic>{}),
      ),
      mainEmotion: MainEmotion.fromJson(
        (json['main_emotion'] as Map<String, dynamic>? ?? <String, dynamic>{}),
      ),
      badge: EmotionBadge.fromJson(
        (json['badge'] as Map<String, dynamic>? ?? <String, dynamic>{}),
      ),
      summaryBubbles: summaryList
          .map((raw) => SummaryBubble.fromJson(raw as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'week_start': weekStart.toIso8601String(),
      'week_end': weekEnd.toIso8601String(),
      'temperature': temperature.toJson(),
      'main_emotion': mainEmotion.toJson(),
      'badge': badge.toJson(),
      'summary_bubbles': summaryBubbles.map((bubble) => bubble.toJson()).toList(),
    };
  }
}

DateTime _parseDate(String? value) {
  if (value == null || value.isEmpty) {
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
}
