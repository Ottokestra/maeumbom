import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../../core/utils/logger.dart';
import '../../dtos/report/user_report_response.dart';

class ReportApiClient {
  ReportApiClient(this._dio) {
    _setupInterceptors();
  }

  final Dio _dio;

  void _setupInterceptors() {
    // Enable when network debugging is needed
    // _dio.interceptors.add(
    //   LogInterceptor(
    //     requestBody: true,
    //     responseBody: true,
    //     logPrint: (obj) => appLogger.d(obj),
    //   ),
    // );
  }

  Future<UserReportResponse> fetchDailyReport() {
    return _fetchReport(ApiConfig.dailyReport);
  }

  Future<UserReportResponse> fetchWeeklyReport() {
    return _fetchReport(ApiConfig.weeklyReport);
  }

  Future<UserReportResponse> fetchMonthlyReport() {
    return _fetchReport(ApiConfig.monthlyReport);
  }

  Future<UserReportResponse> _fetchReport(String path) async {
    try {
      final response = await _dio.get(path);
      return UserReportResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      appLogger.e('Failed to fetch report', error: e);
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
          return Exception('리포트를 찾을 수 없습니다: $message');
        case 500:
          return Exception('서버 오류가 발생했습니다: $message');
        default:
          return Exception('오류가 발생했습니다: $message');
      }
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception('연결이 원활하지 않습니다. 네트워크를 확인해주세요.');
    }

    return Exception('네트워크 오류가 발생했습니다.');
  }
}
