import 'dart:typed_data';
import '../../api/chat/chat_api_client.dart';
import '../../api/chat/chat_websocket_client.dart';
import '../../dtos/chat/text_chat_request.dart';
import '../../models/chat/chat_message.dart';
import '../../../core/utils/logger.dart';

/// Chat Repository - Abstracts data sources
class ChatRepository {
  final ChatApiClient _apiClient;
  final ChatWebSocketClient _webSocketClient;

  ChatRepository(this._apiClient, this._webSocketClient);

  /// Send text message and return ChatMessage
  Future<ChatMessage> sendTextMessage({
    required String text,
    required int userId,
    String? sessionId,
    String? sttQuality,
  }) async {
    final request = TextChatRequest(
      userText: text,
      sessionId: sessionId ?? 'user_${userId}_default',
      sttQuality: sttQuality,
    );

    appLogger.i('Sending text message via repository');
    final response = await _apiClient.sendTextMessage(request);

    // Convert response to ChatMessage
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: response.replyText,
      isUser: false,
      timestamp: DateTime.now(),
      meta: response.meta,
    );
  }

  /// Connect to audio WebSocket
  Future<void> connectAudioStream() async {
    await _webSocketClient.connect();
  }

  /// Disconnect audio WebSocket
  Future<void> disconnectAudioStream() async {
    await _webSocketClient.disconnect();
  }

  /// Set session for audio streaming
  void setAudioSessionId(String sessionId) {
    _webSocketClient.setSessionId(sessionId);
  }

  /// Send audio chunk
  void sendAudioChunk(Float32List audioChunk) {
    _webSocketClient.sendAudioChunk(audioChunk);
  }

  /// Stream of audio responses
  Stream<Map<String, dynamic>>? get audioMessageStream =>
      _webSocketClient.messageStream;

  /// Check if audio is connected
  bool get isAudioConnected => _webSocketClient.isConnected;
}
