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
    bool? ttsEnabled, // ✅ TTS 활성화 여부
  }) async {
    final request = TextChatRequest(
      userText: text,
      sessionId: sessionId ?? 'user_${userId}_default',
      sttQuality: sttQuality,
      ttsEnabled: ttsEnabled, // ✅ TTS 활성화 여부 전달
    );

    appLogger
        .i('Sending text message via repository (ttsEnabled: $ttsEnabled)');

    // 🔍 DEBUG: Check what's being sent
    print(
        '[ChatRepository] 🔍 Request payload: ttsEnabled=$ttsEnabled, session=$sessionId');

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

  /// Send text message and return raw response (for alarm processing)
  Future<Map<String, dynamic>> sendTextMessageRaw({
    required String text,
    required int userId,
    String? sessionId,
    String? sttQuality,
    bool? ttsEnabled, // ✅ TTS 활성화 여부
  }) async {
    final request = TextChatRequest(
      userText: text,
      sessionId: sessionId ?? 'user_${userId}_default',
      sttQuality: sttQuality,
      ttsEnabled: ttsEnabled, // ✅ TTS 활성화 여부 전달
    );

    appLogger.i(
        'Sending text message via repository (raw, ttsEnabled: $ttsEnabled)');
    final response = await _apiClient.sendTextMessage(request);

    print('[ChatRepository] Raw response meta: ${response.meta}');
    print('[ChatRepository] Reply text: ${response.replyText}');

    // Return raw response as map
    final result = {
      'reply_text': response.replyText,
      'emotion': response.meta?['emotion'],
      'response_type': response.meta?['response_type'],
      'alarm_info': response.meta?['alarm_info'],
      'tts_audio_base64':
          response.meta?['tts_audio_base64'], // 🆕 TTS base64 오디오
      'tts_audio_format': response.meta?['tts_audio_format'], // 🆕 TTS 포맷 (mp3)
      'tts_status': response.meta?['tts_status'], // ✅ TTS 상태
    };

    print('[ChatRepository] Returning result: $result');
    return result;
  }

  // ❌ 삭제: 음성 채팅 관련 메서드는 BomChatService로 이동
  // - connectAudioStream()
  // - disconnectAudioStream()
  // - setAudioSessionId()
  // - sendAudioChunk()
  // - audioMessageStream
  // - isAudioConnected
}
