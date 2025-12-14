import 'package:dio/dio.dart';
import '../../../core/config/api_config.dart';
import '../../../core/utils/logger.dart';
import '../../dtos/target_events/analyze_daily_response.dart';
import '../../dtos/target_events/daily_events_list_response.dart';
import '../../../core/errors/exceptions.dart';

/// Target Events API Client - 대상별 이벤트 API 호출 처리
class TargetEventsApiClient {
  final Dio _dio;

  TargetEventsApiClient(this._dio);

  /// 날짜를 YYYY-MM-DD 형식으로 변환
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 특정 날짜의 대화 분석 실행
  Future<AnalyzeDailyResponse> analyzeDailyEvents({
    required DateTime targetDate,
    required String accessToken,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.targetEventsAnalyzeDaily,
        data: {
          'target_date': _formatDate(targetDate),
        },
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );
      
      return AnalyzeDailyResponse.fromJson(response.data);
    } on DioException catch (e) {
      appLogger.e('Analyze daily events failed', error: e);
      throw _handleError(e);
    }
  }

  /// 일간 이벤트 목록 조회
  Future<DailyEventsListResponse> getDailyEvents({
    required String accessToken,
    String? eventType,
    List<String>? tags,
    DateTime? startDate,
    DateTime? endDate,
    String? targetType,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (eventType != null) queryParams['event_type'] = eventType;
      if (tags != null && tags.isNotEmpty) queryParams['tags'] = tags.join(',');
      if (startDate != null) {
        queryParams['start_date'] = _formatDate(startDate);
      }
      if (endDate != null) {
        queryParams['end_date'] = _formatDate(endDate);
      }
      if (targetType != null) queryParams['target_type'] = targetType;

      final response = await _dio.get(
        ApiConfig.targetEventsDaily,
        queryParameters: queryParams,
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );

      appLogger.d('Response type: ${response.data.runtimeType}');
      if (response.data is Map && response.data['daily_events'] is List) {
        final dailyEvents = response.data['daily_events'] as List;
        if (dailyEvents.isNotEmpty) {
          appLogger.d('First event: ${dailyEvents[0]}');
        }
      }

      try {
        return DailyEventsListResponse.fromJson(response.data);
      } catch (e, stack) {
        appLogger.e('Parse error', error: e, stackTrace: stack);
        rethrow;
      }
    } on DioException catch (e) {
      appLogger.e('Get daily events failed', error: e);
      throw _handleError(e);
    }
  }

  /// 인기 태그 조회
  Future<Map<String, List<String>>> getPopularTags({
    required String accessToken,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiConfig.targetEventsTags,
        queryParameters: {'limit': limit},
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );
      
      return Map<String, List<String>>.from(
        response.data.map((key, value) => MapEntry(
          key as String,
          (value as List).map((e) => e.toString()).toList(),
        )),
      );
    } on DioException catch (e) {
      appLogger.e('Get popular tags failed', error: e);
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
          return UnauthorizedException(message);
        case 404:
          return Exception('Not Found: $message');
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
