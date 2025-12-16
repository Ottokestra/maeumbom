import '../../api/routine/routine_api_client.dart';
import '../../dtos/routine/routine_recommendation_response.dart';
import '../../models/routine/routine_recommendation.dart';

/// 루틴 추천 Repository
class RoutineRepository {
  RoutineRepository(this._apiClient);

  final RoutineApiClient _apiClient;

  /// 최근 루틴 추천 데이터 조회
  Future<RoutineRecommendation> getLatestRecommendation() async {
    final response = await _apiClient.getLatestRecommendation();
    return _mapToModel(response);
  }

  /// DTO를 도메인 모델로 변환
  RoutineRecommendation _mapToModel(RoutineRecommendationResponse dto) {
    return RoutineRecommendation(
      id: dto.id,
      recommendationDate: dto.recommendationDate,
      routines: dto.routines
          .map(
            (item) => RoutineItem(
              routineId: item.routineId,
              title: item.title,
              category: item.category,
            ),
          )
          .toList(),
      primaryEmotion: dto.primaryEmotion,
      sentimentOverall: dto.sentimentOverall,
      totalEmotions: dto.totalEmotions,
    );
  }
}

