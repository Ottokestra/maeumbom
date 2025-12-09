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
      appLogger.i('🎤 [5/6] Starting audio recording...');
      final audioStream = await _audioService.startRecording();
      if (audioStream == null) {
        appLogger.e('❌ Audio stream is null!');
        throw Exception('녹음을 시작할 수 없습니다. 마이크 권한을 확인해주세요.');
      }
      appLogger.i('🎤 [5/6] ✅ Audio stream created');

      // Stream audio chunks to WebSocket
      appLogger.i('🎤 [6/6] Setting up audio streaming...');
      var chunkCount = 0;
      audioStream.listen(
        (chunk) {
          chunkCount++;
          if (chunkCount % 50 == 0) {
            // Every 50 chunks
            appLogger.i(
                '🎤 Audio chunk #$chunkCount sent (${chunk.length} samples)');
          }
          _repository.sendAudioChunk(chunk);
        },
        onError: (error) {
          appLogger.e('❌ Audio stream error', error: error);
        },
        onDone: () {
          appLogger.i('🎤 Audio stream ended (total chunks: $chunkCount)');
        },
      );

      appLogger.i('🎤 ✅ Audio chat started, listening for chunks...');

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
