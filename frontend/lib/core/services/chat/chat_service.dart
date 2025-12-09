import 'dart:async';
import '../../../data/repository/chat/chat_repository.dart';
import '../../../data/models/chat/chat_message.dart';
import 'audio_service.dart';
import 'permission_service.dart';
import '../../utils/logger.dart';

/// Chat Service - Business logic for chat
class ChatService {
  final ChatRepository _repository;
  final AudioService _audioService;
  final PermissionService _permissionService;

  ChatService(
    this._repository,
    this._audioService,
    this._permissionService,
  );

  /// Send text message
  Future<ChatMessage> sendTextMessage({
    required String text,
    required int userId,
    String? sessionId,
  }) async {
    try {
      appLogger.i('Sending text message: $text');

      if (text.trim().isEmpty) {
        throw Exception('Message cannot be empty');
      }

      final message = await _repository.sendTextMessage(
        text: text,
        userId: userId,
        sessionId: sessionId,
      );

      appLogger.i('Text message sent successfully');
      return message;
    } catch (e) {
      appLogger.e('Failed to send text message', error: e);
      rethrow;
    }
  }

  /// Get session history
  Future<List<ChatMessage>> getSessionHistory(String sessionId) async {
    try {
      appLogger.i('Fetching session history for: $sessionId');
      return await _repository.getSessionHistory(sessionId);
    } catch (e) {
      appLogger.e('Failed to fetch session history', error: e);
      rethrow;
    }
  }

  /// Start audio recording and streaming
  Future<StreamSubscription<Map<String, dynamic>>?> startAudioChat({
    required int userId,
    String? sessionId,
  }) async {
    try {
      // Check permission status first
      final hasPermission = await _permissionService.hasMicrophonePermission();
      if (!hasPermission) {
        // Request permission
        final (granted, isPermanentlyDenied) =
            await _permissionService.requestMicrophonePermission();

        if (isPermanentlyDenied) {
          throw Exception('PERMANENTLY_DENIED');
        }

        if (!granted) {
          throw Exception('마이크 권한이 거부되었습니다.');
        }
      }

      // Connect WebSocket
      await _repository.connectAudioStream();

      // Set session ID
      final finalSessionId = sessionId ?? 'user_${userId}_default';
      _repository.setAudioSessionId(finalSessionId);

      // Start recording
      final audioStream = await _audioService.startRecording();
      if (audioStream == null) {
        throw Exception('녹음을 시작할 수 없습니다. 마이크 권한을 확인해주세요.');
      }

      // Stream audio chunks to WebSocket
      audioStream.listen((chunk) {
        _repository.sendAudioChunk(chunk);
      });

      appLogger.i('Audio chat started');

      // Return subscription to WebSocket messages
      return _repository.audioMessageStream?.listen((message) {
        appLogger.d('Received audio message: $message');
      });
    } catch (e) {
      appLogger.e('Failed to start audio chat', error: e);
      await stopAudioChat();
      rethrow;
    }
  }

  /// Stop audio recording and streaming
  Future<void> stopAudioChat() async {
    await _audioService.stopRecording();
    await _repository.disconnectAudioStream();
    appLogger.i('Audio chat stopped');
  }

  /// Stream of audio responses
  Stream<Map<String, dynamic>>? get audioResponseStream =>
      _repository.audioMessageStream;

  /// Check if audio is active
  Future<bool> isAudioActive() async {
    return await _audioService.isRecording() && _repository.isAudioConnected;
  }

  /// Dispose resources
  Future<void> dispose() async {
    await stopAudioChat();
    await _audioService.dispose();
  }
}
