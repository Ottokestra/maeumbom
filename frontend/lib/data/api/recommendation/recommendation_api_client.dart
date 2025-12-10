import '../../../core/config/api_config.dart';
import '../../../core/services/api_client.dart';
import '../../dtos/recommendation/recommendation_response.dart';

class RecommendationApiClient {
  RecommendationApiClient(this._client);

  final ApiClient _client;

  Future<RecommendationResponse> fetchQuote(Map<String, dynamic> payload) async {
    final response = await _client.post(
      ApiConfig.recommendationQuote,
      data: payload,
    );
    return RecommendationResponse.fromJson(
      response as Map<String, dynamic>,
      'quote',
    );
  }

  Future<RecommendationResponse> fetchMusic(Map<String, dynamic> payload) async {
    final response = await _client.post(
      ApiConfig.recommendationMusic,
      data: payload,
    );
    return RecommendationResponse.fromJson(
      response as Map<String, dynamic>,
      'music',
    );
  }

  Future<RecommendationResponse> fetchImage(Map<String, dynamic> payload) async {
    final response = await _client.post(
      ApiConfig.recommendationImage,
      data: payload,
    );
    return RecommendationResponse.fromJson(
      response as Map<String, dynamic>,
      'image',
    );
  }
}
