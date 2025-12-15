import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/chat/bom_chat_service.dart';
import '../core/services/chat/permission_service.dart';
import '../data/models/chat/chat_message.dart';
import '../data/repository/chat/chat_repository.dart';
import 'chat_provider.dart';
import 'auth_provider.dart';
import 'alarm_provider.dart';

/// 알림 음성 상태
class AlarmVoiceState {
  final List<ChatMessage> conversationMessages;
  final VoiceInterfaceState voiceState;
  final bool isRecording;
  final String? error;
  final String sessionId;

  AlarmVoiceState({
    required this.conversationMessages,
    this.voiceState = VoiceInterfaceState.idle,
    this.isRecording = false,
    this.error,
    required this.sessionId,
  });

  AlarmVoiceState copyWith({
    List<ChatMessage>? conversationMessages,
    VoiceInterfaceState? voiceState,
    bool? isRecording,
    String? error,
    String? sessionId,
  }) {
    return AlarmVoiceState(
      conversationMessages: conversationMessages ?? this.conversationMessages,
      voiceState: voiceState ?? this.voiceState,
      isRecording: isRecording ?? this.isRecording,
      error: error,
      sessionId: sessionId ?? this.sessionId,
    );
  }
}

/// 알림 음성 Notifier
class AlarmVoiceNotifier extends StateNotifier<AlarmVoiceState> {
  final BomChatService _bomChatService;
  final PermissionService _permissionService;
  final int _userId;
  final Ref _ref;

  // 알림 다이얼로그 콜백
  void Function(Map<String, dynamic> alarmInfo, String replyText)?
      onShowAlarmDialog;

  AlarmVoiceNotifier(
    this._bomChatService,
    this._permissionService,
    this._userId,
    this._ref,
  ) : super(AlarmVoiceState(
          conversationMessages: [],
          sessionId: 'alarm_user_${_userId}_${DateTime.now().millisecondsSinceEpoch}',
        )) {
    // BomChatService 콜백 설정
    _bomChatService.onResponse = _handleAgentResponse;
    _bomChatService.onError = _handleError;
    _bomChatService.onSessionEnd = _handleSessionEnd;
    _bomChatService.onSttResult = _handleSttResult;
  }

  /// STT 결과 처리 - 사용자 메시지 추가
  void _handleSttResult(String sttText) {
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: sttText,
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      conversationMessages: [...state.conversationMessages, userMessage],
    );
  }

  /// 에이전트 응답 처리
  void _handleAgentResponse(Map<String, dynamic> response) {
    final replyText = response['reply_text'] as String?;
    final responseType = response['response_type'] as String?;
    final alarmInfo = response['alarm_info'] as Map<String, dynamic>?;

    print('[AlarmVoiceProvider] 🔍 _handleAgentResponse called');
    print('[AlarmVoiceProvider] 🔍 response_type: $responseType');
    print('[AlarmVoiceProvider] 🔍 alarm_info: $alarmInfo');

    if (replyText != null && replyText.isNotEmpty) {
      // 봄이 응답 메시지 추가
      final aiMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: replyText,
        isUser: false,
        timestamp: DateTime.now(),
        meta: {
          'response_type': responseType,
          if (alarmInfo != null) 'alarm_info': alarmInfo,
        },
      );

      state = state.copyWith(
        conversationMessages: [...state.conversationMessages, aiMessage],
        voiceState: VoiceInterfaceState.replying,
      );

      print('[AlarmVoiceProvider] ✅ Message added, total: ${state.conversationMessages.length}');

      // 알림 다이얼로그 표시 콜백 호출
      if (responseType == 'alarm' && alarmInfo != null) {
        print('[AlarmVoiceProvider] 🔔 Triggering alarm dialog callback');
        onShowAlarmDialog?.call(alarmInfo, replyText);

        // AlarmProvider에 알림 데이터 전달
        final alarmDataList = alarmInfo['data'] as List<dynamic>?;
        if (alarmDataList != null && alarmDataList.isNotEmpty) {
          final validAlarms = alarmDataList
              .cast<Map<String, dynamic>>()
              .where((alarm) => alarm['is_valid_alarm'] == true)
              .toList();

          if (validAlarms.isNotEmpty) {
            print('[AlarmVoiceProvider] 📝 Adding ${validAlarms.length} valid alarms');
            _ref.read(alarmProvider.notifier).addAlarms(validAlarms);
          }
        }
      }

      // 처리 완료 후 idle 상태로 전환
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          state = state.copyWith(voiceState: VoiceInterfaceState.idle);
        }
      });
    }
  }

  /// 에러 처리
  void _handleError(String error) {
    print('[AlarmVoiceProvider] ❌ Error: $error');
    state = state.copyWith(
      voiceState: VoiceInterfaceState.idle,
      isRecording: false,
      error: error,
    );
  }

  /// 세션 종료 처리
  void _handleSessionEnd() {
    print('[AlarmVoiceProvider] 🔚 Session ended');
    state = state.copyWith(
      voiceState: VoiceInterfaceState.idle,
      isRecording: false,
    );
  }

  /// 음성 녹음 시작
  Future<void> startVoiceRecording() async {
    try {
      // 마이크 권한 확인
      final hasPermission = await _permissionService.hasMicrophonePermission();
      if (!hasPermission) {
        final (isGranted, isPermanentlyDenied) =
            await _permissionService.requestMicrophonePermission();
        if (!isGranted) {
          if (isPermanentlyDenied) {
            throw Exception('PERMANENTLY_DENIED');
          }
          throw Exception('마이크 권한이 필요합니다. 설정에서 권한을 허용해주세요.');
        }
      }

      // 로딩 상태로 전환
      state = state.copyWith(
        voiceState: VoiceInterfaceState.loading,
        isRecording: true,
        error: null,
      );

      // 음성 채팅 시작
      await _bomChatService.startVoiceChat(
        userId: _userId.toString(),
        sessionId: state.sessionId,
      );

      // 녹음 중 상태로 전환
      state = state.copyWith(
        voiceState: VoiceInterfaceState.listening,
      );
    } catch (e) {
      state = state.copyWith(
        voiceState: VoiceInterfaceState.idle,
        isRecording: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// 음성 녹음 중지
  Future<void> stopVoiceRecording() async {
    await _bomChatService.stopVoiceChat();
    state = state.copyWith(
      voiceState: VoiceInterfaceState.processing,
      isRecording: false,
    );
  }

  /// 대화 메시지 추가
  void addConversationMessage(ChatMessage message) {
    state = state.copyWith(
      conversationMessages: [...state.conversationMessages, message],
    );
  }

  /// 텍스트 메시지 전송
  Future<void> sendTextMessage(String text) async {
    if (text.trim().isEmpty) return;

    // 사용자 메시지 추가
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      conversationMessages: [...state.conversationMessages, userMessage],
      voiceState: VoiceInterfaceState.processing,
    );

    try {
      print('[AlarmVoiceProvider] 📤 Sending text message...');

      // ChatRepository를 통해 텍스트 메시지 전송
      final chatRepository = _ref.read(chatRepositoryProvider);
      final response = await chatRepository.sendTextMessageRaw(
        text: text,
        userId: _userId,
        sessionId: state.sessionId,
        ttsEnabled: false, // 알림 화면에서는 TTS 비활성화
      );

      print('[AlarmVoiceProvider] 📥 Received response: $response');

      // 응답 처리
      _handleAgentResponse(response);
    } catch (e) {
      print('[AlarmVoiceProvider] ❌ Error in sendTextMessage: $e');
      state = state.copyWith(
        voiceState: VoiceInterfaceState.idle,
        error: '메시지 전송 실패: $e',
      );
    }
  }

  /// 대화 초기화
  void clearConversation() {
    state = state.copyWith(
      conversationMessages: [],
      voiceState: VoiceInterfaceState.idle,
      isRecording: false,
      error: null,
    );
  }

  /// 알림 응답 처리 (외부에서 호출 가능)
  void handleAlarmResponse(Map<String, dynamic> alarmInfo) {
    // 이미 _handleAgentResponse에서 처리되므로 필요 시 추가 로직만
    print('[AlarmVoiceProvider] 📥 handleAlarmResponse called');
  }
}

/// 알림 음성 Provider
final alarmVoiceProvider =
    StateNotifierProvider<AlarmVoiceNotifier, AlarmVoiceState>((ref) {
  final bomChatService = ref.watch(bomChatServiceProvider);
  final permissionService = ref.watch(permissionServiceProvider);
  final authState = ref.watch(authProvider);
  final userId = authState.whenData((user) => user?.id ?? 0).value ?? 0;

  return AlarmVoiceNotifier(
    bomChatService,
    permissionService,
    userId,
    ref,
  );
});
