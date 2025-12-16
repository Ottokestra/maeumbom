import 'package:freezed_annotation/freezed_annotation.dart';

part 'routine_recommendation.freezed.dart';

/// 루틴 추천 도메인 모델
@freezed
class RoutineRecommendation with _$RoutineRecommendation {
  const factory RoutineRecommendation({
    int? id,
    String? recommendationDate,
    @Default([]) List<RoutineItem> routines,
    String? primaryEmotion,
    String? sentimentOverall,
    int? totalEmotions,
  }) = _RoutineRecommendation;
}

/// 루틴 아이템 도메인 모델
@freezed
class RoutineItem with _$RoutineItem {
  const factory RoutineItem({
    required String routineId,
    required String title,
    String? category,
  }) = _RoutineItem;
}

