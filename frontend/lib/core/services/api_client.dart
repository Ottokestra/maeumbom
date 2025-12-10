import 'package:dio/dio.dart';

/// 공통 API 예외 객체
class ApiException implements Exception {
  final String message;
  final String? code;

  ApiException(this.message, {this.code});

  @override
  String toString() => message;
}

/// 공통 API 클라이언트 래퍼
class ApiClient {
  final Dio _dio;

  ApiClient(this._dio);

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<dynamic> put(
    String path, {
    dynamic data,
  }) async {
    try {
      final response = await _dio.put(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  ApiException _toApiException(DioException e) {
    final detail = e.response?.data is Map<String, dynamic>
        ? (e.response?.data['detail'] as String?)
        : null;
    final code = e.response?.data is Map<String, dynamic>
        ? (e.response?.data['code'] as String?)
        : null;

    if (e.response?.statusCode == 401) {
      return ApiException('인증이 필요합니다. 다시 로그인해주세요.', code: code);
    }

    if (detail != null && detail.isNotEmpty) {
      return ApiException(detail, code: code);
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return ApiException('연결이 원활하지 않습니다. 네트워크를 확인해주세요.', code: code);
      case DioExceptionType.badResponse:
        return ApiException('요청을 처리하지 못했어요. 잠시 후 다시 시도해주세요.', code: code);
      default:
        return ApiException('네트워크 오류가 발생했습니다.', code: code);
    }
  }
}
