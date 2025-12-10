import '../../api/recommendation/recommendation_api_client.dart';
import '../../dtos/recommendation/recommendation_response.dart';

class RecommendationRepository {
  RecommendationRepository(this._apiClient);

  final RecommendationApiClient _apiClient;

  Future<RecommendationResponse> fetchQuote(Map<String, dynamic> payload) {
    return _apiClient.fetchQuote(payload);
  }

  Future<RecommendationResponse> fetchMusic(Map<String, dynamic> payload) {
    return _apiClient.fetchMusic(payload);
  }

  Future<RecommendationResponse> fetchImage(Map<String, dynamic> payload) {
    return _apiClient.fetchImage(payload);
  }
}
