import 'dart:io';

/// API Configuration - Base URLs and endpoints
class ApiConfig {
  // Base URL - 플랫폼별로 다른 URL 사용
  static String get baseUrl {
    // Android 에뮬레이터는 10.0.2.2를 사용 (호스트 머신의 localhost)
    if (Platform.isAndroid) {
      return 'http://localhost:8000';
    }
    // iOS 시뮬레이터 및 웹은 localhost 사용
    return 'http://localhost:8000';
  }

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
  static String chatSession(String sessionId) =>
      '$chatBase/sessions/$sessionId';

  // WebSocket Endpoints
  static String get chatWebSocketUrl =>
      baseUrl.replaceFirst('http', 'ws') + '/agent/stream';

  // Onboarding Survey Endpoints
  static const String onboardingSurveyBase = '/api/onboarding-survey';
  static const String onboardingSurveySubmit = '$onboardingSurveyBase/submit';
  static const String onboardingSurveyMe = '$onboardingSurveyBase/me';
  static const String onboardingSurveyStatus = '$onboardingSurveyBase/status';

  // User Phase Endpoints
  static const String userPhaseBase = '/api/service/user-phase';
  static const String userPhaseSync = '$userPhaseBase/sync';
  static const String userPhaseCurrent = '$userPhaseBase/current';
  static const String userPhaseSettings = '$userPhaseBase/settings';
  static const String userPhaseAnalyze = '$userPhaseBase/analyze';
  static const String userPhasePattern = '$userPhaseBase/pattern';

  // Timeout Configuration
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
