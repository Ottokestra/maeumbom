import '../../../core/config/api_config.dart';
import '../../../core/services/api_client.dart';
import '../../dtos/routine/routine_recommendation_response.dart';

/// 루틴 추천 API 클라이언트
class RoutineApiClient {
  RoutineApiClient(this._client);

  final ApiClient _client;

  /// 최근 루틴 추천 데이터 조회
  /// 
  /// 하루 전(어제) 데이터 우선 조회, 없으면 가장 최근 데이터 반환
  Future<RoutineRecommendationResponse> getLatestRecommendation() async {
    final response = await _client.get(
      ApiConfig.routineLatest,
    );
    return RoutineRecommendationResponse.fromJson(
      response as Map<String, dynamic>,
    );
  }
}

