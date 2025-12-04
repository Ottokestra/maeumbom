/// API Configuration - Base URLs and endpoints
class ApiConfig {
  // Base URL
  static const String baseUrl = 'http://localhost:8000';

  // Auth Endpoints
  static const String authBase = '/auth';
  static const String googleLogin = '$authBase/google';
  static const String kakaoLogin = '$authBase/kakao';
  static const String naverLogin = '$authBase/naver';
  static const String refreshToken = '$authBase/refresh';
  static const String logout = '$authBase/logout';
  static const String me = '$authBase/me';
  static const String authConfig = '$authBase/config';

  // Chat Endpoints
  static const String chatBase = '/api/agent/v2';
  static const String chatText = '$chatBase/text';
  static const String chatSessions = '$chatBase/sessions';
  static String chatSession(String sessionId) => '$chatBase/sessions/$sessionId';

  // WebSocket Endpoints
  static String get chatWebSocketUrl =>
      baseUrl.replaceFirst('http', 'ws') + '/agent/stream';

  // Timeout Configuration
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
