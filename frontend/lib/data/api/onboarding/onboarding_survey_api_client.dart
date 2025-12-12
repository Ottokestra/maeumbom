import '../../../core/config/api_config.dart';
import '../../../core/services/api_client.dart';
import '../../../core/utils/logger.dart';
import '../../dtos/onboarding/onboarding_survey_request.dart';
import '../../dtos/onboarding/onboarding_survey_response.dart';
import '../../dtos/onboarding/onboarding_survey_status_response.dart';

/// Onboarding Survey API Client
class OnboardingSurveyApiClient {
  final ApiClient _client;

  OnboardingSurveyApiClient(this._client);

  /// Submit onboarding survey
  /// AuthInterceptor가 자동으로 토큰을 추가함
  Future<OnboardingSurveyResponse> submitSurvey(
    OnboardingSurveyRequest request,
  ) async {
    try {
      final response = await _client.post(
        ApiConfig.onboardingSurveySubmit,
        data: request.toJson(),
      );
      return OnboardingSurveyResponse.fromJson(response as Map<String, dynamic>);
    } on ApiException catch (e) {
      appLogger.e('Onboarding survey submission failed', error: e);
      throw e;
    }
  }

  /// Get my profile
  /// AuthInterceptor가 자동으로 토큰을 추가함
  Future<OnboardingSurveyResponse> getMyProfile() async {
    try {
      final response = await _client.get(ApiConfig.onboardingSurveyMe);
      return OnboardingSurveyResponse.fromJson(response as Map<String, dynamic>);
    } on ApiException catch (e) {
      appLogger.e('Failed to get profile', error: e);
      throw e;
    }
  }

  /// Get profile status (check if user has completed onboarding survey)
  /// AuthInterceptor가 자동으로 토큰을 추가함
  Future<OnboardingSurveyStatusResponse> getProfileStatus() async {
    try {
      final response = await _client.get(ApiConfig.onboardingSurveyStatus);
      return OnboardingSurveyStatusResponse.fromJson(
        response as Map<String, dynamic>,
      );
    } on ApiException catch (e) {
      appLogger.e('Failed to get profile status', error: e);
      throw e;
    }
  }
}
