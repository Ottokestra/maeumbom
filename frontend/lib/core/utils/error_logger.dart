import 'package:dio/dio.dart';

import 'logger.dart';

/// API 에러 로깅용 공통 인터페이스
abstract class ErrorLogger {
  void logError(
    Object error,
    StackTrace stackTrace,
    RequestOptions options, [
    Response<dynamic>? response,
  ]);
}

/// 기본 구현: 앱 로거를 통해 네트워크 에러를 기록
class AppErrorLogger implements ErrorLogger {
  const AppErrorLogger();

  @override
  void logError(
    Object error,
    StackTrace stackTrace,
    RequestOptions options, [
    Response<dynamic>? response,
  ]) {
    final buffer = StringBuffer()
      ..writeln('HTTP ${options.method} ${options.uri}')
      ..writeln('Headers: ${options.headers}');

    if (response != null) {
      buffer
        ..writeln('Status: ${response.statusCode}')
        ..writeln('Response: ${response.data}');
    }

    appLogger.e(
      buffer.toString(),
      error: error,
      stackTrace: stackTrace,
    );
  }
}
