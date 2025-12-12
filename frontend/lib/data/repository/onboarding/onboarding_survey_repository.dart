import '../../api/onboarding/onboarding_survey_api_client.dart';
import '../../dtos/onboarding/onboarding_survey_request.dart';
import '../../dtos/onboarding/onboarding_survey_response.dart';
import '../../dtos/onboarding/onboarding_survey_status_response.dart';

class OnboardingSurveyRepository {
  final OnboardingSurveyApiClient _apiClient;

  OnboardingSurveyRepository(this._apiClient);

  Future<OnboardingSurveyResponse> submitSurvey(
    OnboardingSurveyRequest request,
  ) {
    return _apiClient.submitSurvey(request);
  }

  Future<OnboardingSurveyResponse> getMySurvey() {
    return _apiClient.getMyProfile();
  }

  Future<OnboardingSurveyStatusResponse> getSurveyStatus() {
    return _apiClient.getProfileStatus();
  }
}
