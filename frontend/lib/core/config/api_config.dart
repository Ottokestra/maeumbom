/// API Configuration - Base URLs and endpoints
class ApiConfig {
  // Base URL
  static const String baseUrl = 'http://localhost:8000';

  // Auth Endpoints
  static const String authBase = '/api/auth';
  static const String googleLogin = '$authBase/google';
  static const String kakaoLogin = '$authBase/kakao';
  static const String naverLogin = '$authBase/naver';
  static const String refreshToken = '$authBase/refresh';
  static const String logout = '$authBase/logout';
  static const String me = '$authBase/me';
  static const String authConfig = '$authBase/config';

  // Timeout Configuration
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
