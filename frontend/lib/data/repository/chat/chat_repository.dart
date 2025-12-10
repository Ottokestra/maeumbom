import '../../api/chat/chat_api_client.dart';
import '../../dtos/chat/text_chat_request.dart';
import '../../models/chat/chat_message.dart';
import '../../../core/utils/logger.dart';

/// Chat Repository - Abstracts data sources
/// Phase 2: 음성 채팅은 BomChatService로 이동, 텍스트 채팅만 유지
class ChatRepository {
  final ChatApiClient _apiClient;

  ChatRepository(this._apiClient);

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

  // ❌ 삭제: 음성 채팅 관련 메서드는 BomChatService로 이동
  // - connectAudioStream()
  // - disconnectAudioStream()
  // - setAudioSessionId()
  // - sendAudioChunk()
  // - audioMessageStream
  // - isAudioConnected
}
