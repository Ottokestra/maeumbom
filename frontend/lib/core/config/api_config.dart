import 'dart:io';
import 'package:flutter/foundation.dart';

/// API Configuration - Base URLs and endpoints
class ApiConfig {
  /// 테스트용 (로컬 FastAPI / Docker)
  static const String _localDev = 'http://localhost:8000';
  static const String _androidEmulator = 'http://10.0.2.2:8000';

  /// 운영용 (Real)
  static const String _production = 'http://apricity.kr:8000';

  static String get baseUrl {
    // 환경 변수로 설정된 경우 우선 사용 (실제 디바이스용)
    // flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8000
    const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
    if (apiBaseUrl.isNotEmpty) {
      return apiBaseUrl;
    }

    // 테스트용 (에뮬레이터/시뮬레이터)
    if (!kReleaseMode) {
      if (Platform.isAndroid) {
        // Android 에뮬레이터: 10.0.2.2는 호스트 머신의 localhost를 가리킴
        // 실제 디바이스 테스트 시에는 --dart-define=API_BASE_URL=http://YOUR_IP:8000 사용
        return _androidEmulator;
      }
      // iOS 시뮬레이터: localhost 사용
      return _localDev;
    }

    // 운영용
    return _production;
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

  // Dashboard Endpoints
  static const String dashboardBase = '/api/dashboard';
  static const String emotionHistory = '$dashboardBase/emotion-history';

  // Report Endpoints
  static const String reportBase = '/api/reports/me';
  static const String dailyReport = '$reportBase/daily';
  static const String weeklyReport = '$reportBase/weekly';
  static const String monthlyReport = '$reportBase/monthly';

  // User Phase Endpoints
  static const String userPhaseBase = '/api/service/user-phase';
  static const String userPhaseSync = '$userPhaseBase/sync';
  static const String userPhaseCurrent = '$userPhaseBase/current';
  static const String userPhaseSettings = '$userPhaseBase/settings';
  static const String userPhaseAnalyze = '$userPhaseBase/analyze';
  static const String userPhasePattern = '$userPhaseBase/pattern';

  // Recommendation Endpoints
  static const String recommendationBase = '/api/v1/recommendations';
  static const String recommendationQuote = '$recommendationBase/quote';
  static const String recommendationMusic = '$recommendationBase/music';
  static const String recommendationImage = '$recommendationBase/image';
  static const String routineLatest = '$recommendationBase/routine/latest';

  // Emotion Report Endpoints
  static const String emotionReportBase = '/api/v1/reports/emotion';
  static const String emotionWeeklyReport = '$emotionReportBase/weekly';

  // Relation Training Endpoints
  static const String relationTrainingBase = '/api/service/relation-training';
  static const String relationTrainingScenarios =
      '$relationTrainingBase/scenarios';
  static String relationTrainingStart(int scenarioId) =>
      '$relationTrainingBase/scenarios/$scenarioId/start';
  static const String relationTrainingProgress =
      '$relationTrainingBase/progress';
  static const String relationTrainingGenerate =
      '$relationTrainingBase/generate-scenario';
  static String relationTrainingDelete(int scenarioId) =>
      '$relationTrainingBase/scenarios/$scenarioId';

  // Slang Quiz Endpoints
  static const String slangQuizBase = '/api/service/slang-quiz';
  static const String slangQuizStartGame = '$slangQuizBase/start-game';
  static String slangQuizGetQuestion(int gameId, int questionNumber) =>
      '$slangQuizBase/games/$gameId/questions/$questionNumber';
  static String slangQuizSubmitAnswer(int gameId) =>
      '$slangQuizBase/games/$gameId/submit-answer';
  static String slangQuizEndGame(int gameId) =>
      '$slangQuizBase/games/$gameId/end';
  static const String slangQuizHistory = '$slangQuizBase/history';
  static const String slangQuizStatistics = '$slangQuizBase/statistics';
  static const String slangQuizAdminGenerate =
      '$slangQuizBase/admin/questions/generate';

  // Target Events Endpoints
  static const String targetEventsBase = '/api/target-events';
  static const String targetEventsAnalyzeDaily =
      '$targetEventsBase/analyze-daily';
  static const String targetEventsDaily = '$targetEventsBase/daily';
  static const String targetEventsWeekly = '$targetEventsBase/weekly';
  static const String targetEventsTags = '$targetEventsBase/tags/popular';

  // Timeout Configuration
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout =
      Duration(seconds: 120); // 시나리오 생성은 20-30초 이상 소요될 수 있음
}
