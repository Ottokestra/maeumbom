import 'package:dio/dio.dart';
import '../../../core/config/api_config.dart';
import '../../../core/utils/logger.dart';
import '../../dtos/onboarding/onboarding_survey_request.dart';
import '../../dtos/onboarding/onboarding_survey_response.dart';

/// Onboarding Survey API Client
class OnboardingSurveyApiClient {
  final Dio _dio;

  OnboardingSurveyApiClient(this._dio) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => appLogger.d(obj),
      ),
    );
  }

  /// Submit onboarding survey
  Future<OnboardingSurveyResponse> submitSurvey(
    OnboardingSurveyRequest request,
    String accessToken,
  ) async {
    try {
      final response = await _dio.post(
        ApiConfig.onboardingSurveySubmit,
        data: request.toJson(),
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );
      return OnboardingSurveyResponse.fromJson(response.data);
    } on DioException catch (e) {
      appLogger.e('Onboarding survey submission failed', error: e);
      throw _handleError(e);
    }
  }

  /// Get my profile
  Future<OnboardingSurveyResponse> getMyProfile(String accessToken) async {
    try {
      final response = await _dio.get(
        ApiConfig.onboardingSurveyMe,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );
      return OnboardingSurveyResponse.fromJson(response.data);
    } on DioException catch (e) {
      appLogger.e('Failed to get profile', error: e);
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final message = e.response!.data['detail'] ?? 'Unknown error';
      
      switch (statusCode) {
        case 401:
          return Exception('인증이 필요합니다. 다시 로그인해주세요.');
        case 404:
          return Exception('프로필을 찾을 수 없습니다.');
        case 500:
          return Exception('서버 오류가 발생했습니다: $message');
        default:
          return Exception('오류가 발생했습니다: $message');
      }
    } else {
      return Exception('네트워크 오류가 발생했습니다.');
    }
  }
}

