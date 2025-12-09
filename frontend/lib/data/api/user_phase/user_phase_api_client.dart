import 'package:dio/dio.dart';
import '../../../core/config/api_config.dart';
import '../../../core/utils/logger.dart';
import '../../dtos/user_phase/health_sync_request.dart';
import '../../dtos/user_phase/user_phase_response.dart';
import '../../dtos/user_phase/user_pattern_response.dart';
import '../../dtos/user_phase/user_pattern_setting_update.dart';
import '../../dtos/user_phase/user_pattern_setting_response.dart';

/// User Phase API Client
class UserPhaseApiClient {
  final Dio _dio;

  UserPhaseApiClient(this._dio) {
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

  /// 건강 데이터 동기화
  Future<UserPhaseResponse> syncHealthData(
    HealthSyncRequest request,
  ) async {
    try {
      final response = await _dio.post(
        ApiConfig.userPhaseSync,
        data: request.toJson(),
      );
      return UserPhaseResponse.fromJson(response.data);
    } on DioException catch (e) {
      appLogger.e('Health data sync failed', error: e);
      throw _handleError(e);
    }
  }

  /// 현재 Phase 조회
  Future<UserPhaseResponse> getCurrentPhase() async {
    try {
      final response = await _dio.get(
        ApiConfig.userPhaseCurrent,
      );
      return UserPhaseResponse.fromJson(response.data);
    } on DioException catch (e) {
      appLogger.e('Failed to get current phase', error: e);
      throw _handleError(e);
    }
  }

  /// 사용자 설정 조회
  Future<UserPatternSettingResponse> getSettings() async {
    try {
      final response = await _dio.get(
        ApiConfig.userPhaseSettings,
      );
      return UserPatternSettingResponse.fromJson(response.data);
    } on DioException catch (e) {
      appLogger.e('Failed to get settings', error: e);
      throw _handleError(e);
    }
  }

  /// 사용자 설정 업데이트
  Future<UserPatternSettingResponse> updateSettings(
    UserPatternSettingUpdate request,
  ) async {
    try {
      final response = await _dio.put(
        ApiConfig.userPhaseSettings,
        data: request.toJson(),
      );
      return UserPatternSettingResponse.fromJson(response.data);
    } on DioException catch (e) {
      appLogger.e('Failed to update settings', error: e);
      throw _handleError(e);
    }
  }

  /// 주간 패턴 분석 (수동 트리거)
  Future<UserPatternResponse> analyzePattern() async {
    try {
      final response = await _dio.post(
        ApiConfig.userPhaseAnalyze,
      );
      return UserPatternResponse.fromJson(response.data);
    } on DioException catch (e) {
      appLogger.e('Failed to analyze pattern', error: e);
      throw _handleError(e);
    }
  }

  /// 패턴 분석 결과 조회
  Future<UserPatternResponse> getPattern() async {
    try {
      final response = await _dio.get(
        ApiConfig.userPhasePattern,
      );
      return UserPatternResponse.fromJson(response.data);
    } on DioException catch (e) {
      appLogger.e('Failed to get pattern', error: e);
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final message = e.response!.data?['detail'] ?? 'Unknown error';

      switch (statusCode) {
        case 400:
          return Exception('잘못된 요청입니다: $message');
        case 401:
          return Exception('인증이 필요합니다. 다시 로그인해주세요.');
        case 404:
          return Exception('데이터를 찾을 수 없습니다: $message');
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

