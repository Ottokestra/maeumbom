import 'package:freezed_annotation/freezed_annotation.dart';

part 'routine_recommendation_response.freezed.dart';
part 'routine_recommendation_response.g.dart';

@freezed
class RoutineRecommendationResponse with _$RoutineRecommendationResponse {
  const factory RoutineRecommendationResponse({
    int? id,
    @JsonKey(name: 'recommendation_date') String? recommendationDate,
    @Default([]) List<RoutineItemDto> routines,
    @JsonKey(name: 'primary_emotion') String? primaryEmotion,
    @JsonKey(name: 'sentiment_overall') String? sentimentOverall,
    @JsonKey(name: 'total_emotions') int? totalEmotions,
  }) = _RoutineRecommendationResponse;

  factory RoutineRecommendationResponse.fromJson(Map<String, dynamic> json) =>
      _$RoutineRecommendationResponseFromJson(json);
}

@freezed
class RoutineItemDto with _$RoutineItemDto {
  const factory RoutineItemDto({
    @JsonKey(name: 'routine_id') required String routineId,
    required String title,
    String? category,
  }) = _RoutineItemDto;

  factory RoutineItemDto.fromJson(Map<String, dynamic> json) =>
      _$RoutineItemDtoFromJson(json);
}

