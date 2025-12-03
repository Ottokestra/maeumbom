import 'package:dio/dio.dart';
import '../services/auth_service.dart';
import 'logger.dart';

/// Auth Interceptor - Automatically adds access token and handles refresh
class AuthInterceptor extends Interceptor {
  final AuthService _authService;
  final Dio _dio;

  AuthInterceptor(this._authService, this._dio);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Don't add token to auth endpoints
    if (_isAuthEndpoint(options.path)) {
      return handler.next(options);
    }

    // Add access token to request
    final accessToken = await _authService.getAccessToken();
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    handler.next(options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Handle 401 Unauthorized - Token expired
    if (err.response?.statusCode == 401 &&
        !_isAuthEndpoint(err.requestOptions.path)) {
      appLogger.w('Token expired, attempting refresh...');

      try {
        // Refresh token
        await _authService.refreshToken();

        // Retry original request with new token
        final accessToken = await _authService.getAccessToken();
        if (accessToken != null) {
          err.requestOptions.headers['Authorization'] = 'Bearer $accessToken';

          final response = await _dio.fetch(err.requestOptions);
          return handler.resolve(response);
        }
      } catch (e) {
        appLogger.e('Token refresh failed during interceptor', error: e);
        // If refresh fails, logout user
        await _authService.logout();
      }
    }

    handler.next(err);
  }

  bool _isAuthEndpoint(String path) {
    return path.contains('/api/auth/google') ||
        path.contains('/api/auth/kakao') ||
        path.contains('/api/auth/naver') ||
        path.contains('/api/auth/refresh');
  }
}
