import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/chat/chat_service.dart';
import '../core/services/chat/audio_service.dart';
import '../core/services/chat/permission_service.dart';
import '../data/api/chat/chat_api_client.dart';
import '../data/api/chat/chat_websocket_client.dart';
import '../data/repository/chat/chat_repository.dart';
import '../data/models/chat/chat_message.dart';
import 'auth_provider.dart';

// ----- Infrastructure Providers -----

/// Chat API Client provider
final chatApiClientProvider = Provider<ChatApiClient>((ref) {
  final dio = ref.watch(dioWithAuthProvider);
  return ChatApiClient(dio);
});

/// Chat WebSocket Client provider
final chatWebSocketClientProvider = Provider<ChatWebSocketClient>((ref) {
  return ChatWebSocketClient();
});

/// Chat Repository provider
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final apiClient = ref.watch(chatApiClientProvider);
  final webSocketClient = ref.watch(chatWebSocketClientProvider);
  return ChatRepository(apiClient, webSocketClient);
});

/// Audio Service provider
final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService();
});

/// Permission Service provider
final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});

/// Chat Service provider
final chatServiceProvider = Provider<ChatService>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  final audioService = ref.watch(audioServiceProvider);
  final permissionService = ref.watch(permissionServiceProvider);

  return ChatService(repository, audioService, permissionService);
});

// ----- State Providers -----

/// Chat state
class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isRecording;
  final String? error;
  final String sessionId;

  ChatState({
    required this.messages,
    required this.isLoading,
    required this.isRecording,
    this.error,
    required this.sessionId,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isRecording,
    String? error,
    String? sessionId,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isRecording: isRecording ?? this.isRecording,
      error: error,
      sessionId: sessionId ?? this.sessionId,
    );
  }
}

/// Chat Notifier
class ChatNotifier extends StateNotifier<ChatState> {
  final ChatService _chatService;
  final int _userId;
  final PermissionService _permissionService;
  StreamSubscription<Map<String, dynamic>>? _audioSubscription;

  ChatNotifier(
    this._chatService,
    this._userId,
    this._permissionService,
  ) : super(ChatState(
          messages: [],
          isLoading: false,
          isRecording: false,
          sessionId: 'user_${_userId}_default',
        ));

  /// Send text message
  Future<void> sendTextMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message immediately
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    try {
      // Get AI response
      final aiMessage = await _chatService.sendTextMessage(
        text: text,
        userId: _userId,
        sessionId: state.sessionId,
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Start audio recording
  Future<void> startAudioRecording() async {
    try {
      state = state.copyWith(isRecording: true, error: null);

      _audioSubscription = await _chatService.startAudioChat(
        userId: _userId,
        sessionId: state.sessionId,
      );

      if (_audioSubscription == null) {
        throw Exception('마이크 권한이 필요합니다. 설정에서 권한을 허용해주세요.');
      }

      // Listen to audio responses
      _audioSubscription?.onData((message) {
        _handleAudioResponse(message);
      });

      _audioSubscription?.onError((error) {
        state = state.copyWith(
          isRecording: false,
          error: 'Audio error: $error',
        );
      });
    } catch (e) {
      state = state.copyWith(
        isRecording: false,
        error: null, // 에러는 UI에서 직접 처리하므로 상태에 저장하지 않음
      );
      rethrow; // UI에서 에러를 처리할 수 있도록 다시 throw
    }
  }

  /// Stop audio recording
  Future<void> stopAudioRecording() async {
    await _audioSubscription?.cancel();
    await _chatService.stopAudioChat();
    state = state.copyWith(isRecording: false);
  }

  /// Handle audio response from WebSocket
  void _handleAudioResponse(Map<String, dynamic> message) {
    final type = message['type'];

    if (type == 'status') {
      // Handle status messages (connecting, ready, etc.)
      // Just log for now
    } else if (type == 'stt_result') {
      // Handle STT result - add user message
      final userText = message['text'] as String?;
      if (userText != null && userText.isNotEmpty) {
        final userMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: userText,
          isUser: true,
          timestamp: DateTime.now(),
        );
        state = state.copyWith(
          messages: [...state.messages, userMessage],
        );
      }
    } else if (type == 'agent_response') {
      // Handle agent response - add AI message
      final data = message['data'] as Map<String, dynamic>?;
      if (data != null) {
        final replyText = data['reply_text'] as String?;
        if (replyText != null) {
          final aiMessage = ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: replyText,
            isUser: false,
            timestamp: DateTime.now(),
            meta: data['meta'] as Map<String, dynamic>?,
          );
          state = state.copyWith(
            messages: [...state.messages, aiMessage],
          );
        }
      }
    }
  }

  /// Clear messages
  void clearMessages() {
    state = state.copyWith(messages: []);
  }

  /// Open app settings
  Future<void> openAppSettings() async {
    await _permissionService.openSettings();
  }

  /// Check if microphone permission is granted
  Future<bool> hasMicrophonePermission() async {
    return await _permissionService.hasMicrophonePermission();
  }

  /// Check if microphone permission is permanently denied
  Future<bool> isPermanentlyDenied() async {
    return await _permissionService.isPermanentlyDenied();
  }

  /// Check if microphone permission was never requested
  Future<bool> isNeverRequested() async {
    return await _permissionService.isNeverRequested();
  }

  @override
  void dispose() {
    _audioSubscription?.cancel();
    _chatService.dispose();
    super.dispose();
  }
}

/// Chat provider
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  final permissionService = ref.watch(permissionServiceProvider);
  final currentUser = ref.watch(currentUserProvider);

  if (currentUser == null) {
    throw Exception('User not authenticated');
  }

  return ChatNotifier(chatService, currentUser.id, permissionService);
});
