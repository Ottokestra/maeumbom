import '../../../data/models/target_events/weekly_event_model.dart';
import '../../../core/utils/emotion_mapper.dart';
import '../pages/report_page3.dart';

/// 주간 감정 분석 서비스
///
/// WeeklyEventModel 리스트에서 감정 데이터를 집계하여
/// ReportPage3에서 사용할 수 있는 형식으로 변환합니다.
class EmotionAnalysisService {
  /// 주간 감정 데이터 분석
  ///
  /// 여러 대상 타입(SELF, HUSBAND, CHILD 등)의 감정 분포를 합산하여
  /// 전체 주간 감정 분포를 계산하고, 상위 5개 감정을 EmotionRank 리스트로 반환합니다.
  ///
  /// [weeklyEvents] 주간 이벤트 리스트 (대상별로 분리된 데이터)
  ///
  /// Returns: 분석 결과 (상위 감정 리스트, 전체 카운트)
  static EmotionAnalysisResult analyzeWeeklyEmotions(
    List<WeeklyEventModel> weeklyEvents,
  ) {
    if (weeklyEvents.isEmpty) {
      return EmotionAnalysisResult(
        topEmotion: null,
        allEmotions: [],
        totalCount: 0,
      );
    }

    // 1. 모든 대상의 감정 분포를 합산
    final Map<String, int> emotionScores = {};

    for (final event in weeklyEvents) {
      final distribution = event.emotionDistribution;

      if (distribution.isEmpty) continue;

      // emotionDistribution은 Map<String, dynamic>이므로 각 항목을 처리
      distribution.forEach((emotionName, value) {
        // value는 퍼센트(int) 또는 다른 형태일 수 있음
        final score = _parseScore(value);
        if (score > 0) {
          emotionScores[emotionName] =
              (emotionScores[emotionName] ?? 0) + score;
        }
      });
    }

    if (emotionScores.isEmpty) {
      return EmotionAnalysisResult(
        topEmotion: null,
        allEmotions: [],
        totalCount: 0,
      );
    }

    // 2. 감정을 점수 순으로 정렬
    final sortedEmotions = emotionScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 3. 전체 점수 합계 계산
    final totalScore =
        emotionScores.values.fold<int>(0, (sum, score) => sum + score);

    // 4. 상위 5개 감정을 EmotionRank로 변환
    final List<EmotionRank> emotionRanks = [];

    for (int i = 0; i < sortedEmotions.length && i < 5; i++) {
      final entry = sortedEmotions[i];
      final emotionName = entry.key;
      final score = entry.value;

      // 한글 감정명을 EmotionId로 변환
      final emotionId = EmotionMapper.fromKoreanName(emotionName);

      // 변환 실패 시 건너뛰기
      if (emotionId == null) continue;

      // 퍼센트 계산 (반올림)
      final percentage = ((score / totalScore) * 100).round();

      emotionRanks.add(EmotionRank(
        rank: i + 1,
        emotion: emotionId,
        emotionName: emotionName,
        percentage: percentage,
        count: score, // 실제 카운트 대신 점수 사용
      ));
    }

    return EmotionAnalysisResult(
      topEmotion: emotionRanks.isNotEmpty ? emotionRanks.first : null,
      allEmotions: emotionRanks,
      totalCount: totalScore,
    );
  }

  /// 값을 정수 점수로 변환
  ///
  /// emotionDistribution의 값은 int, double, String 등 다양할 수 있으므로
  /// 안전하게 정수로 변환합니다.
  static int _parseScore(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    return 0;
  }
}

/// 감정 분석 결과
class EmotionAnalysisResult {
  /// 최상위 감정 (1위)
  final EmotionRank? topEmotion;

  /// 전체 감정 리스트 (상위 5개)
  final List<EmotionRank> allEmotions;

  /// 전체 감정 카운트 합계
  final int totalCount;

  EmotionAnalysisResult({
    required this.topEmotion,
    required this.allEmotions,
    required this.totalCount,
  });
}
