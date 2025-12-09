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

/// Voice Interface State
enum VoiceInterfaceState {
  idle,       // 대기 중
  listening,  // 사용자가 말하는 중
  processing, // AI가 생각하는 중
  replying,   // 봄이가 대답하는 중
}

/// Chat state
class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final VoiceInterfaceState voiceState; // isRecording 대체 및 고도화
  final String? error;
  final String sessionId;

  ChatState({
    required this.messages,
    required this.isLoading,
    this.voiceState = VoiceInterfaceState.idle,
    this.error,
    required this.sessionId,
  });

  // 하위 호환성을 위한 getter
  bool get isRecording => voiceState == VoiceInterfaceState.listening;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    VoiceInterfaceState? voiceState,
    String? error,
    String? sessionId,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      voiceState: voiceState ?? this.voiceState,
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
          voiceState: VoiceInterfaceState.idle,
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
      // 기존 구독 취소하여 중복 방지 (두 번째 턴 버그 수정)
      await _audioSubscription?.cancel();
      _audioSubscription = null;

      state = state.copyWith(
        voiceState: VoiceInterfaceState.listening,
        error: null,
      );

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
          voiceState: VoiceInterfaceState.idle,
          error: 'Audio error: $error',
        );
      });
    } catch (e) {
      state = state.copyWith(
        voiceState: VoiceInterfaceState.idle,
        error: null, // 에러는 UI에서 직접 처리하므로 상태에 저장하지 않음
      );
      rethrow; // UI에서 에러를 처리할 수 있도록 다시 throw
    }
  }

  /// Stop audio recording
  Future<void> stopAudioRecording() async {
    await _audioSubscription?.cancel();
    _audioSubscription = null;
    await _chatService.stopAudioChat();
    state = state.copyWith(voiceState: VoiceInterfaceState.idle);
  }

  /// Handle audio response from WebSocket
  void _handleAudioResponse(Map<String, dynamic> message) {
    final type = message['type'];

    if (type == 'status') {
      // Handle status messages
      final status = message['status'] as String?;
      if (status == 'listening') {
        // 이미 startAudioRecording에서 처리됨
      } else if (status == 'processing') {
        state = state.copyWith(voiceState: VoiceInterfaceState.processing);
      } else if (status == 'speaking') {
        state = state.copyWith(voiceState: VoiceInterfaceState.replying);
      }
    } else if (type == 'stt_result') {
      // Handle STT result - add user message
      final userText = message['text'] as String?;
      final isFinal = message['is_final'] as bool? ?? false;
      
      if (userText != null && userText.isNotEmpty) {
        if (state.voiceState == VoiceInterfaceState.listening && isFinal) {
           // 사용자가 말을 마치면 처리 상태로 전환
           state = state.copyWith(voiceState: VoiceInterfaceState.processing);
        }

        // 중복 추가 방지 로직 필요 (임시로 항상 추가)
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
        // 응답 오면 speaking 상태로
        state = state.copyWith(voiceState: VoiceInterfaceState.replying);

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
            // 응답이 완료되면 idle로 돌아가야 하는데, 
            // 현재 구조에선 오디오 재생 완료 시점을 알기 어려우므로 
            // 추가적인 'audio_finished' 이벤트가 필요하거나 사용자 상호작용으로 끊어야 함.
            // 우선은 replying 상태 유지 -> 사용자가 다시 마이크 누르거나 텍스트 입력하면 초기화
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
    // super.dispose();
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
