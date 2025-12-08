import 'package:dio/dio.dart';
import '../../../core/config/api_config.dart';
import '../../../core/utils/logger.dart';
import '../../dtos/chat/text_chat_request.dart';
import '../../dtos/chat/text_chat_response.dart';
import '../../dtos/chat/sessions_response.dart';
import '../../dtos/chat/session_detail_response.dart';

/// Chat API Client - Handles text-based chat API calls
class ChatApiClient {
  final Dio _dio;

  ChatApiClient(this._dio);

  /// Send text message to chat API
  Future<TextChatResponse> sendTextMessage(TextChatRequest request) async {
    try {
      appLogger.i('Sending text message to ${ApiConfig.chatText}');

      final response = await _dio.post(
        ApiConfig.chatText,
        data: request.toJson(),
      );

      appLogger.d('Chat response received: ${response.statusCode}');
      return TextChatResponse.fromJson(response.data);
    } on DioException catch (e) {
      appLogger.e('Text chat failed', error: e);
      throw _handleError(e);
    }
  }

  /// Get all sessions for current user
  Future<SessionsResponse> getSessions() async {
    try {
      appLogger.i('Fetching sessions from ${ApiConfig.chatSessions}');

      final response = await _dio.get(ApiConfig.chatSessions);

      appLogger.d('Sessions response received: ${response.statusCode}');
      return SessionsResponse.fromJson(response.data);
    } on DioException catch (e) {
      appLogger.e('Failed to fetch sessions', error: e);
      throw _handleError(e);
    }
  }

  /// Get session history by session ID
  Future<SessionDetailResponse> getSessionHistory(
    String sessionId, {
    int? limit,
  }) async {
    try {
      final url = ApiConfig.chatSession(sessionId);
      final queryParams = limit != null ? {'limit': limit} : null;

      appLogger.i('Fetching session history: $sessionId');

      final response = await _dio.get(
        url,
        queryParameters: queryParams,
      );

      appLogger.d('Session history response received: ${response.statusCode}');
      return SessionDetailResponse.fromJson(response.data);
    } on DioException catch (e) {
      appLogger.e('Failed to fetch session history', error: e);
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
          return Exception('Unauthorized: $message');
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
