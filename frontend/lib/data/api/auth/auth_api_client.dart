import 'package:dio/dio.dart';
import '../../../core/config/api_config.dart';
import '../../../core/utils/logger.dart';
import '../../dtos/auth/google_login_request.dart';
import '../../dtos/auth/kakao_login_request.dart';
import '../../dtos/auth/naver_login_request.dart';
import '../../dtos/auth/token_response.dart';
import '../../dtos/auth/user_response.dart';

/// Auth API Client - Handles all authentication API calls
class AuthApiClient {
  final Dio _dio;

  AuthApiClient(this._dio) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    // HTTP 로그는 에러 발생시에만 출력하도록 비활성화
    // 필요시 주석 해제하여 디버깅 가능
    // _dio.interceptors.add(
    //   LogInterceptor(
    //     requestBody: true,
    //     responseBody: true,
    //     logPrint: (obj) => appLogger.d(obj),
    //   ),
    // );
  }

  /// Login with Google OAuth
  Future<TokenResponse> googleLogin(GoogleLoginRequest request) async {
    try {
      final response = await _dio.post(
        ApiConfig.googleLogin,
        data: request.toJson(),
      );
      return TokenResponse.fromJson(response.data);
    } on DioException catch (e) {
      appLogger.e('Google login failed', error: e);
      throw _handleError(e);
    }
  }

  /// Login with Kakao OAuth
  Future<TokenResponse> kakaoLogin(KakaoLoginRequest request) async {
    try {
      final response = await _dio.post(
        ApiConfig.kakaoLogin,
        data: request.toJson(),
      );
      return TokenResponse.fromJson(response.data);
    } on DioException catch (e) {
      appLogger.e('Kakao login failed', error: e);
      throw _handleError(e);
    }
  }

  /// Login with Naver OAuth
  Future<TokenResponse> naverLogin(NaverLoginRequest request) async {
    try {
      final response = await _dio.post(
        ApiConfig.naverLogin,
        data: request.toJson(),
      );
      return TokenResponse.fromJson(response.data);
    } on DioException catch (e) {
      appLogger.e('Naver login failed', error: e);
      throw _handleError(e);
    }
  }

  /// Refresh access token
  Future<TokenResponse> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post(
        ApiConfig.refreshToken,
        data: {'refresh_token': refreshToken},
      );
      return TokenResponse.fromJson(response.data);
    } on DioException catch (e) {
      appLogger.e('Token refresh failed', error: e);
      throw _handleError(e);
    }
  }

  /// Get current user profile
  Future<UserResponse> getCurrentUser(String accessToken) async {
    try {
      final response = await _dio.get(
        ApiConfig.me,
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );
      return UserResponse.fromJson(response.data);
    } on DioException catch (e) {
      appLogger.e('Get user failed', error: e);
      throw _handleError(e);
    }
  }

  /// Logout
  Future<void> logout(String accessToken) async {
    try {
      await _dio.post(
        ApiConfig.logout,
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );
    } on DioException catch (e) {
      appLogger.e('Logout failed', error: e);
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final message = e.response!.data?['detail'] ?? 'Unknown error';

      switch (statusCode) {
        case 400:
          return Exception('Bad Request: $message');
        case 401:
          return Exception('Unauthorized: $message');
        case 500:
          return Exception('Server Error: $message');
        default:
          return Exception('Error $statusCode: $message');
      }
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception('Connection timeout. Please check your internet.');
    }

    return Exception('Network error: ${e.message}');
  }
}
