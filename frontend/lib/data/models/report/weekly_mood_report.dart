class WeeklyEmotionRanking {
  WeeklyEmotionRanking({
    required this.rank,
    required this.code,
    required this.label,
    required this.percent,
    required this.count,
    required this.characterCode,
  });

  final int rank;
  final String code;
  final String label;
  final double percent;
  final int count;
  final String characterCode;

  factory WeeklyEmotionRanking.fromJson(Map<String, dynamic> json) {
    return WeeklyEmotionRanking(
      rank: json['rank'] as int? ?? 0,
      code: json['code'] as String? ?? '',
      label: json['label'] as String? ?? '',
      percent: (json['percent'] as num?)?.toDouble() ?? 0,
      count: json['count'] as int? ?? 0,
      characterCode: json['character_code'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'code': code,
      'label': label,
      'percent': percent,
      'count': count,
      'character_code': characterCode,
    };
  }
}

class DailyMoodSticker {
  DailyMoodSticker({
    required this.date,
    required this.weekday,
    required this.emotionCode,
    required this.emotionLabel,
    required this.characterCode,
    required this.hasRecord,
  });

  final DateTime date;
  final String weekday; // "MON" ~ "SUN"
  final String? emotionCode;
  final String? emotionLabel;
  final String? characterCode;
  final bool hasRecord;

  factory DailyMoodSticker.fromJson(Map<String, dynamic> json) {
    return DailyMoodSticker(
      date: _parseDate(json['date'] as String?),
      weekday: json['weekday'] as String? ?? '',
      emotionCode: json['emotion_code'] as String?,
      emotionLabel: json['emotion_label'] as String?,
      characterCode: json['character_code'] as String?,
      hasRecord: json['has_record'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': _formatDate(date),
      'weekday': weekday,
      'emotion_code': emotionCode,
      'emotion_label': emotionLabel,
      'character_code': characterCode,
      'has_record': hasRecord,
    };
  }
}

class WeeklySentimentPoint {
  final DateTime timestamp;
  final double sentimentScore; // -1.0 ~ 1.0
  final String sentimentOverall; // "positive"|"neutral"|"negative"
  final String primaryEmotionCode;
  final String primaryEmotionLabel;
  final String characterCode;

  WeeklySentimentPoint({
    required this.timestamp,
    required this.sentimentScore,
    required this.sentimentOverall,
    required this.primaryEmotionCode,
    required this.primaryEmotionLabel,
    required this.characterCode,
  });

  factory WeeklySentimentPoint.fromJson(Map<String, dynamic> json) {
    return WeeklySentimentPoint(
      timestamp: DateTime.parse(json['timestamp'] as String),
      sentimentScore: (json['sentiment_score'] as num).toDouble(),
      sentimentOverall: json['sentiment_overall'] as String,
      primaryEmotionCode: json['primary_emotion_code'] as String,
      primaryEmotionLabel: json['primary_emotion_label'] as String,
      characterCode: json['character_code'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'sentiment_score': sentimentScore,
      'sentiment_overall': sentimentOverall,
      'primary_emotion_code': primaryEmotionCode,
      'primary_emotion_label': primaryEmotionLabel,
      'character_code': characterCode,
    };
  }
}

class HighlightConversation {
  final int id;
  final String text;
  final DateTime createdAt;
  final String sentimentOverall;
  final String primaryEmotionCode;
  final String primaryEmotionLabel;
  final String? riskLevel;
  final List<String> reportTags;

  HighlightConversation({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.sentimentOverall,
    required this.primaryEmotionCode,
    required this.primaryEmotionLabel,
    this.riskLevel,
    required this.reportTags,
  });

  factory HighlightConversation.fromJson(Map<String, dynamic> json) {
    return HighlightConversation(
      id: json['id'] as int,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      sentimentOverall: json['sentiment_overall'] as String,
      primaryEmotionCode: json['primary_emotion_code'] as String,
      primaryEmotionLabel: json['primary_emotion_label'] as String,
      riskLevel: json['risk_level'] as String?,
      reportTags: (json['report_tags'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'created_at': createdAt.toIso8601String(),
      'sentiment_overall': sentimentOverall,
      'primary_emotion_code': primaryEmotionCode,
      'primary_emotion_label': primaryEmotionLabel,
      'risk_level': riskLevel,
      'report_tags': reportTags,
    };
  }
}

class WeeklyMoodReport {
  WeeklyMoodReport({
    required this.weekLabel,
    required this.weekStart,
    required this.weekEnd,
    required this.overallScorePercent,
    required this.dominantEmotion,
    required this.dailyCharacters,
    required this.emotionRankings,
    required this.analysisText,
    required this.sentimentTimeline,
    required this.highlightConversations,
  });

  final String weekLabel;
  final DateTime weekStart;
  final DateTime weekEnd;
  final int overallScorePercent;
  final WeeklyEmotionRanking dominantEmotion;
  final List<DailyMoodSticker> dailyCharacters;
  final List<WeeklyEmotionRanking> emotionRankings;
  final String analysisText;
  final List<WeeklySentimentPoint> sentimentTimeline;
  final List<HighlightConversation> highlightConversations;

  factory WeeklyMoodReport.fromJson(Map<String, dynamic> json) {
    final dailyList = json['daily_characters'] as List<dynamic>? ?? [];
    final rankingList = json['emotion_rankings'] as List<dynamic>? ?? [];
    final timelineList = json['sentiment_timeline'] as List<dynamic>? ?? [];
    final highlightList = json['highlight_conversations'] as List<dynamic>? ?? [];

    return WeeklyMoodReport(
      weekLabel: json['week_label'] as String? ?? '',
      weekStart: _parseDate(json['week_start'] as String?),
      weekEnd: _parseDate(json['week_end'] as String?),
      overallScorePercent: json['overall_score_percent'] as int? ?? 0,
      dominantEmotion: WeeklyEmotionRanking.fromJson(
        (json['dominant_emotion'] as Map<String, dynamic>? ?? {}),
      ),
      dailyCharacters: dailyList
          .map(
            (raw) => DailyMoodSticker.fromJson(
              raw as Map<String, dynamic>,
            ),
          )
          .toList(),
      emotionRankings: rankingList
          .map(
            (raw) => WeeklyEmotionRanking.fromJson(
              raw as Map<String, dynamic>,
            ),
          )
          .toList(),
      analysisText: json['analysis_text'] as String? ?? '',
      sentimentTimeline: timelineList
          .map(
            (raw) => WeeklySentimentPoint.fromJson(
              raw as Map<String, dynamic>,
            ),
          )
          .toList(),
      highlightConversations: highlightList
          .map(
            (raw) => HighlightConversation.fromJson(
              raw as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'week_label': weekLabel,
      'week_start': _formatDate(weekStart),
      'week_end': _formatDate(weekEnd),
      'overall_score_percent': overallScorePercent,
      'dominant_emotion': dominantEmotion.toJson(),
      'daily_characters': dailyCharacters.map((e) => e.toJson()).toList(),
      'emotion_rankings': emotionRankings.map((e) => e.toJson()).toList(),
      'analysis_text': analysisText,
      'sentiment_timeline':
          sentimentTimeline.map((point) => point.toJson()).toList(),
      'highlight_conversations':
          highlightConversations.map((item) => item.toJson()).toList(),
    };
  }
}

DateTime _parseDate(String? value) {
  if (value == null || value.isEmpty) {
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
}

String _formatDate(DateTime date) {
  return date.toIso8601String().split('T').first;
}
