import 'package:dio/dio.dart';
import '../../../core/config/api_config.dart';
import '../../../core/utils/logger.dart';
import '../../models/dashboard/emotion_history_model.dart';
import '../../../core/errors/exceptions.dart';

/// Dashboard API Client - 대시보드 API 호출 처리
class DashboardApiClient {
  final Dio _dio;

  DashboardApiClient(this._dio);

  /// 날짜를 YYYY-MM-DD 형식으로 변환
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 일간 감정 데이터 조회 (TB_DAILY_TARGET_EVENTS)
  /// 
  /// [startDate]: 조회 시작 날짜 (필수)
  /// [endDate]: 조회 종료 날짜 (필수)
  Future<List<Map<String, dynamic>>> getDailyEmotions({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final queryParams = {
        'start_date': _formatDate(startDate),
        'end_date': _formatDate(endDate),
      };

      appLogger.d('🔵 Calling GET /api/dashboard/daily-emotions with params: $queryParams');

      final response = await _dio.get(
        '/api/dashboard/daily-emotions',
        queryParameters: queryParams,
      );

      appLogger.d('🟢 API Success - Daily emotions count: ${(response.data as List).length}');

      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      appLogger.e('Get daily emotions failed', error: e);
      throw _handleError(e);
    }
  }

  /// 감정 이력 조회
  /// 
  /// [startDate]: 조회 시작 날짜 (옵션)
  /// [endDate]: 조회 종료 날짜 (옵션)
  /// [limit]: 조회할 레코드 수 (기본값: 100)
  Future<List<EmotionHistoryModel>> getEmotionHistory({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
      };

      if (startDate != null) {
        queryParams['start_date'] = _formatDate(startDate);
      }
      if (endDate != null) {
        queryParams['end_date'] = _formatDate(endDate);
      }

      appLogger.d('🔵 Calling GET ${ApiConfig.emotionHistory} with params: $queryParams');

      final response = await _dio.get(
        ApiConfig.emotionHistory,
        queryParameters: queryParams,
      );

      appLogger.d('🟢 API Success - Emotion history count: ${(response.data as List).length}');

      // API 응답은 배열 형태
      final List<dynamic> dataList = response.data as List<dynamic>;
      return dataList
          .map((json) => EmotionHistoryModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      appLogger.e('Get emotion history failed', error: e);
      throw _handleError(e);
    }
  }

  /// Dio 에러 처리
  AppException _handleError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final message = e.response!.data?['detail'] ?? 'Unknown error';

      switch (statusCode) {
        case 400:
          return BadRequestException(message);
        case 401:
          return UnauthorizedException(message);
        case 404:
          return NotFoundException(message);
        case 500:
          return ServerException(message);
        default:
          return NetworkException('HTTP $statusCode: $message');
      }
    } else {
      return NetworkException(e.message ?? 'Network error occurred');
    }
  }
}
