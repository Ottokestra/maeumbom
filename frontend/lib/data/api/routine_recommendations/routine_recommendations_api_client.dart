import 'package:dio/dio.dart';
import '../../../core/config/api_config.dart';
import '../../../core/utils/logger.dart';
import '../../dtos/routine_recommendations/routine_recommendations_list_response.dart';
import '../../../core/errors/exceptions.dart';

/// Routine Recommendations API Client - 루틴 추천 API 호출 처리
class RoutineRecommendationsApiClient {
  final Dio _dio;

  RoutineRecommendationsApiClient(this._dio);

  /// 날짜를 YYYY-MM-DD 형식으로 변환
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 루틴 추천 목록 조회
  Future<RoutineRecommendationsListResponse> getRecommendations({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 7,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (startDate != null) queryParams['start_date'] = _formatDate(startDate);
      if (endDate != null) queryParams['end_date'] = _formatDate(endDate);
      queryParams['limit'] = limit;
      
      appLogger.d('🔵 Calling GET /api/routine-recommendations/list with params: $queryParams');
      
      final response = await _dio.get(
        '/api/routine-recommendations/list',
        queryParameters: queryParams,
      );
      
      appLogger.d('🟢 API Success - Recommendations count: ${response.data['total_count']}');
      
      return RoutineRecommendationsListResponse.fromJson(response.data);
    } on DioException catch (e) {
      appLogger.e('Get routine recommendations failed', error: e);
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

