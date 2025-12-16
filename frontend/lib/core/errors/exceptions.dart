// Base exception class
abstract class AppException implements Exception {
  final String message;
  AppException(this.message);

  @override
  String toString() => message;
}

class UnauthorizedException extends AppException {
  UnauthorizedException([String message = 'Unauthorized']) : super(message);

  @override
  String toString() => 'UnauthorizedException: $message';
}

class BadRequestException extends AppException {
  BadRequestException([String message = 'Bad request']) : super(message);

  @override
  String toString() => 'BadRequestException: $message';
}

class NotFoundException extends AppException {
  NotFoundException([String message = 'Not found']) : super(message);

  @override
  String toString() => 'NotFoundException: $message';
}

class ServerException extends AppException {
  ServerException([String message = 'Server error']) : super(message);

  @override
  String toString() => 'ServerException: $message';
}

class NetworkException extends AppException {
  NetworkException([String message = 'Network error']) : super(message);

  @override
  String toString() => 'NetworkException: $message';
}
