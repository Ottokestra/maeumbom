import 'package:json_annotation/json_annotation.dart';

part 'routine_recommendation_response.g.dart';

@JsonSerializable()
class RoutineRecommendationResponse {
  @JsonKey(name: 'ID')
  final int id;
  
  @JsonKey(name: 'USER_ID')
  final int userId;
  
  @JsonKey(name: 'RECOMMENDATION_DATE')
  final String recommendationDate;
  
  @JsonKey(name: 'EMOTION_SUMMARY')
  final Map<String, dynamic>? emotionSummary;
  
  @JsonKey(name: 'ROUTINES')
  final List<dynamic>? routines;
  
  @JsonKey(name: 'TOTAL_EMOTIONS')
  final int totalEmotions;
  
  @JsonKey(name: 'PRIMARY_EMOTION')
  final String? primaryEmotion;
  
  @JsonKey(name: 'SENTIMENT_OVERALL')
  final String? sentimentOverall;

  RoutineRecommendationResponse({
    required this.id,
    required this.userId,
    required this.recommendationDate,
    this.emotionSummary,
    this.routines,
    required this.totalEmotions,
    this.primaryEmotion,
    this.sentimentOverall,
  });

  factory RoutineRecommendationResponse.fromJson(Map<String, dynamic> json) =>
      _$RoutineRecommendationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$RoutineRecommendationResponseToJson(this);
}

