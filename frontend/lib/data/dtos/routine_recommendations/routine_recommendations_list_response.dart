import 'package:json_annotation/json_annotation.dart';
import 'routine_recommendation_response.dart';

part 'routine_recommendations_list_response.g.dart';

@JsonSerializable()
class RoutineRecommendationsListResponse {
  final List<RoutineRecommendationResponse> recommendations;
  
  @JsonKey(name: 'total_count')
  final int totalCount;

  RoutineRecommendationsListResponse({
    required this.recommendations,
    required this.totalCount,
  });

  factory RoutineRecommendationsListResponse.fromJson(Map<String, dynamic> json) =>
      _$RoutineRecommendationsListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$RoutineRecommendationsListResponseToJson(this);
}

