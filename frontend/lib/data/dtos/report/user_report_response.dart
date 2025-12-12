class TopEmotionItem {
  TopEmotionItem({
    required this.label,
    required this.count,
    required this.ratio,
  });

  final String label;
  final int count;
  final double ratio;

  factory TopEmotionItem.fromJson(Map<String, dynamic> json) {
    return TopEmotionItem(
      label: json['label'] as String? ?? '',
      count: json['count'] as int? ?? 0,
      ratio: (json['ratio'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'count': count,
      'ratio': ratio,
    };
  }
}

class EmotionMetric {
  EmotionMetric({
    required this.periodStart,
    required this.periodEnd,
    required this.totalSessions,
    required this.totalMessages,
    required this.avgSentiment,
    required this.topEmotions,
  });

  final DateTime periodStart;
  final DateTime periodEnd;
  final int totalSessions;
  final int totalMessages;
  final double avgSentiment;
  final List<TopEmotionItem> topEmotions;

  factory EmotionMetric.fromJson(Map<String, dynamic> json) {
    final topEmotionsJson = json['top_emotions'] as List<dynamic>? ?? [];

    return EmotionMetric(
      periodStart: _parseDate(json['period_start'] as String?),
      periodEnd: _parseDate(json['period_end'] as String?),
      totalSessions: json['total_sessions'] as int? ?? 0,
      totalMessages: json['total_messages'] as int? ?? 0,
      avgSentiment: (json['avg_sentiment'] as num?)?.toDouble() ?? 0,
      topEmotions: topEmotionsJson
          .map((raw) => TopEmotionItem.fromJson(raw as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
      'total_sessions': totalSessions,
      'total_messages': totalMessages,
      'avg_sentiment': avgSentiment,
      'top_emotions': topEmotions.map((emotion) => emotion.toJson()).toList(),
    };
  }
}

class UserReportResponse {
  UserReportResponse({
    required this.periodType,
    required this.periodStart,
    required this.periodEnd,
    required this.metrics,
    required this.recentHighlights,
    required this.recommendation,
  });

  final String periodType;
  final DateTime periodStart;
  final DateTime periodEnd;
  final EmotionMetric metrics;
  final List<String> recentHighlights;
  final String recommendation;

  factory UserReportResponse.fromJson(Map<String, dynamic> json) {
    return UserReportResponse(
      periodType: json['period_type'] as String? ?? '',
      periodStart: _parseDate(json['period_start'] as String?),
      periodEnd: _parseDate(json['period_end'] as String?),
      metrics: EmotionMetric.fromJson(
        (json['metrics'] as Map<String, dynamic>? ?? <String, dynamic>{}),
      ),
      recentHighlights:
          (json['recent_highlights'] as List<dynamic>? ?? <dynamic>[])
              .map((item) => item.toString())
              .toList(),
      recommendation: json['recommendation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period_type': periodType,
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
      'metrics': metrics.toJson(),
      'recent_highlights': recentHighlights,
      'recommendation': recommendation,
    };
  }
}

DateTime _parseDate(String? value) {
  if (value == null || value.isEmpty) {
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
}
