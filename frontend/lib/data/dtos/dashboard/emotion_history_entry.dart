class EmotionHistoryEntry {
  EmotionHistoryEntry({
    required this.createdAt,
    required this.sentimentOverall,
    required this.primaryEmotionCode,
    required this.primaryEmotionLabel,
    required this.primaryEmotionGroup,
  });

  final DateTime createdAt;
  final String sentimentOverall;
  final String primaryEmotionCode;
  final String primaryEmotionLabel;
  final String primaryEmotionGroup;

  factory EmotionHistoryEntry.fromJson(Map<String, dynamic> json) {
    final primary = json['primary_emotion'] as Map<String, dynamic>? ?? {};
    return EmotionHistoryEntry(
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      sentimentOverall: json['sentiment_overall']?.toString() ?? 'neutral',
      primaryEmotionCode: primary['code']?.toString() ?? '',
      primaryEmotionLabel: primary['label']?.toString() ?? '',
      primaryEmotionGroup: primary['group']?.toString() ?? '',
    );
  }
}
