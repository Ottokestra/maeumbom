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
  });

  final String weekLabel;
  final DateTime weekStart;
  final DateTime weekEnd;
  final int overallScorePercent;
  final WeeklyEmotionRanking dominantEmotion;
  final List<DailyMoodSticker> dailyCharacters;
  final List<WeeklyEmotionRanking> emotionRankings;
  final String analysisText;

  factory WeeklyMoodReport.fromJson(Map<String, dynamic> json) {
    final dailyList = json['daily_characters'] as List<dynamic>? ?? [];
    final rankingList = json['emotion_rankings'] as List<dynamic>? ?? [];

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
