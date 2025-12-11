import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ Session 저장
import '../core/services/chat/bom_chat_service.dart';
import '../core/services/chat/permission_service.dart';
import '../data/models/chat/chat_message.dart';
import '../data/repository/chat/chat_repository.dart';
import '../data/api/chat/chat_api_client.dart';
import 'auth_provider.dart';
import 'alarm_provider.dart';
import '../core/services/audio/tts_player_service.dart'; // ✅ TTS Service

// ----- Infrastructure Providers -----

/// Permission Service provider
final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});

/// Bom Chat Service provider (Phase 2 - Big Endian)
final bomChatServiceProvider = Provider<BomChatService>((ref) {
  return BomChatService();
});

/// TTS Player Service provider
final ttsPlayerServiceProvider = Provider<TtsPlayerService>((ref) {
  return TtsPlayerService();
});

/// Chat API Client provider
final chatApiClientProvider = Provider<ChatApiClient>((ref) {
  final dio = ref.watch(dioWithAuthProvider); // ✅ Authenticated Dio
  return ChatApiClient(dio);
});

/// Chat Repository provider (✅ 텍스트 대화용)
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final apiClient = ref.watch(chatApiClientProvider);
  return ChatRepository(apiClient);
});

// ----- State Providers -----

/// Voice Interface State
enum VoiceInterfaceState {
  idle, // 대기 중
  loading, // Backend 모델 로딩 중 (잠시만 기다려주세요)
  listening, // 사용자가 말하는 중 (말씀하세요!)
  processing, // AI가 생각하는 중
  replying, // 봄이가 대답하는 중
}

/// Chat state
class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final VoiceInterfaceState voiceState;
  final String? error;
  final String sessionId;
  final String? sttPartialText; // ✅ Phase 3: STT 부분 결과
  final bool ttsEnabled; // ✅ TTS 활성화 여부

  ChatState({
    required this.messages,
    required this.isLoading,
    this.voiceState = VoiceInterfaceState.idle,
    this.error,
    required this.sessionId,
    this.sttPartialText, // ✅ Phase 3
    this.ttsEnabled = false, // ✅ 기본값: false
  });

  // 하위 호환성을 위한 getter
  bool get isRecording => voiceState == VoiceInterfaceState.listening;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    VoiceInterfaceState? voiceState,
    String? error,
    String? sessionId,
    String? sttPartialText, // ✅ Phase 3
    bool? ttsEnabled, // ✅ TTS 토글
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      voiceState: voiceState ?? this.voiceState,
      error: error,
      sessionId: sessionId ?? this.sessionId,
      sttPartialText: sttPartialText, // ✅ Phase 3
      ttsEnabled: ttsEnabled ?? this.ttsEnabled, // ✅ TTS 토글
    );
  }
}

/// Chat Notifier (Phase 2 - BomChatService 사용)
class ChatNotifier extends StateNotifier<ChatState> {
  final BomChatService _bomChatService;
  final ChatRepository _chatRepository;
  final TtsPlayerService _ttsPlayerService; // ✅ TTS Service 주입
  final int _userId;
  final PermissionService _permissionService;
  final Ref _ref;

  // ✅ Session 관리
  static const _sessionDuration = Duration(minutes: 5);
  static const _sessionIdKey = 'chat_session_id';
  static const _sessionTimeKey = 'chat_session_time';
  static const _ttsEnabledKey = 'chat_tts_enabled'; // ✅ TTS 상태 저장 키

  // 🆕 Alarm dialog callback
  void Function(Map<String, dynamic> alarmInfo, String replyText)?
      onShowAlarmDialog;
  void Function(Map<String, dynamic> alarmInfo)? onShowWarningDialog;
  
  // 🆕 음성 입력 여부 추적
  bool _isVoiceInput = false;

  ChatNotifier(
    this._bomChatService,
    this._chatRepository, // ✅ ChatRepository 주입
    this._ttsPlayerService, // ✅ TTS Service 주입
    this._userId,
    this._permissionService,
    this._ref,
  ) : super(ChatState(
          messages: [],
          isLoading: false,
          voiceState: VoiceInterfaceState.idle,
          sessionId: 'user_${_userId}_default', // 초기값, 나중에 업데이트됨
          ttsEnabled: false, // 초기값, 나중에 복원됨
        )) {
    // ✅ Session 복원 또는 생성
    _initializeSession();
    // ✅ TTS 상태 복원
    _loadTtsEnabled();
    // BomChatService 콜백 설정
    _bomChatService.onResponse = _handleAgentResponse;
    _bomChatService.onError = _handleError;
    _bomChatService.onSessionEnd = _handleSessionEnd;
    _bomChatService.onPartialText = _handlePartialText; // Phase 3 (비활성화)
    _bomChatService.onSttResult = _handleSttResult; // ✅ STT 결과
  }

  // ✅ STT 결과 처리 - 사용자 메시지 UI에 표시 및 processing 상태로 전환
  void _handleSttResult(String sttText) {
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: sttText,
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
    );
  }

  // Phase 3: STT partial 결과 처리 (비활성화)
  void _handlePartialText(String partialText) {
    state = state.copyWith(sttPartialText: partialText);
  }

  /// Start audio recording (Phase 2)
  Future<void> startAudioRecording() async {
    try {
      // 🆕 음성 입력 플래그 설정
      _isVoiceInput = true;
      
      // 권한 확인
      final hasPermission = await _permissionService.hasMicrophonePermission();
      if (!hasPermission) {
        // 권한 요청
        final (isGranted, isPermanentlyDenied) =
            await _permissionService.requestMicrophonePermission();
        if (!isGranted) {
          if (isPermanentlyDenied) {
            throw Exception('PERMANENTLY_DENIED');
          }
          throw Exception('마이크 권한이 필요합니다. 설정에서 권한을 허용해주세요.');
        }
      }

      // ✅ Backend 모델 로딩 중 상태 (사용자: "잠시만 기다려주세요")
      state = state.copyWith(
        voiceState: VoiceInterfaceState.loading,
        error: null,
      );

      // ✅ BomChatService로 음성 채팅 시작 (내부에서 Backend ready 대기)
      await _bomChatService.startVoiceChat(
        userId: _userId.toString(),
        sessionId: state.sessionId,
      );
      
      // 녹음 시작 시 TTS 중지
      await _ttsPlayerService.stop();

      // ✅ Ready 완료 후 listening으로 전환 (사용자: "말씀하세요!")
      state = state.copyWith(
        voiceState: VoiceInterfaceState.listening,
      );
    } catch (e) {
      state = state.copyWith(
        voiceState: VoiceInterfaceState.idle,
        error: null,
      );
      rethrow;
    }
  }

  /// Stop audio recording
  Future<void> stopAudioRecording() async {
    await _bomChatService.stopVoiceChat();
    state = state.copyWith(voiceState: VoiceInterfaceState.idle);
  }

  /// Handle agent response from BomChatService
  void _handleAgentResponse(Map<String, dynamic> response) {
    final replyText = response['reply_text'] as String?;
    final emotion = response['emotion'] as String?;
    final responseType = response['response_type'] as String?;
    final ttsAudio = response['tts_audio'] as String?; // ✅ TTS URL/Path
    final alarmInfo =
        response['alarm_info'] as Map<String, dynamic>?; // 🆕 alarm_info

    print('[ChatProvider] 🔍 _handleAgentResponse called');
    print('[ChatProvider] 🔍 response_type: $responseType');
    print('[ChatProvider] 🔍 alarm_info: $alarmInfo');

    if (replyText != null && replyText.isNotEmpty) {
      // AI 응답 추가
      final aiMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: replyText,
        isUser: false,
        timestamp: DateTime.now(),
        meta: {
          'emotion': emotion,
          'response_type': responseType,
          if (alarmInfo != null) 'alarm_info': alarmInfo, // 🆕 alarm_info 포함
        },
      );

      print(
          '[ChatProvider] ✅ ChatMessage created with meta: ${aiMessage.meta}');

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        voiceState: VoiceInterfaceState.replying,
      );

      print(
          '[ChatProvider] ✅ State updated, messages count: ${state.messages.length}');

      // 🆕 Alarm dialog callback trigger (음성/텍스트 모두)
      if (responseType == 'alarm' && alarmInfo != null) {
        print('[ChatProvider] 🔔 [VOICE] Alarm detected');
        print('[ChatProvider] 🔔 [VOICE] _isVoiceInput: $_isVoiceInput');
        print('[ChatProvider] 🔔 [VOICE] onShowAlarmDialog: $onShowAlarmDialog');
        
        // 🆕 음성/텍스트 모두 다이얼로그 표시
        onShowAlarmDialog?.call(alarmInfo, replyText);

        // 🆕 AlarmProvider에 알람 데이터 전달 (음성/텍스트 모두)
        final alarmDataList = alarmInfo['data'] as List<dynamic>?;
        if (alarmDataList != null && alarmDataList.isNotEmpty) {
          // 유효한 알람만 필터링
          final validAlarms = alarmDataList
              .cast<Map<String, dynamic>>()
              .where((alarm) => alarm['is_valid_alarm'] == true)
              .toList();

          if (validAlarms.isNotEmpty) {
            _ref.read(alarmProvider.notifier).addAlarms(validAlarms);
            print(
                '[ChatProvider] 📝 [VOICE] ${validAlarms.length} valid alarms sent to AlarmProvider');
          }
        }
      } else if (responseType == 'warning' && alarmInfo != null) {
        print('[ChatProvider] ⚠️ [VOICE] Triggering warning dialog callback');
        onShowWarningDialog?.call(alarmInfo);
      }

      // ✅ TTS 재생
      if (state.ttsEnabled && ttsAudio != null && ttsAudio.isNotEmpty) {
        _playTtsAudio(ttsAudio);
      }

      // ✅ WebSocket 연결 유지! - TTS 재생 후 다시 listening으로 전환
      Future.delayed(const Duration(seconds: 3), () {
        if (state.voiceState == VoiceInterfaceState.replying &&
            _bomChatService.isActive) {
          state = state.copyWith(voiceState: VoiceInterfaceState.listening);
        }
      });
    }
  }

  /// Handle error
  void _handleError(String error) {
    state = state.copyWith(
      voiceState: VoiceInterfaceState.idle,
      error: error,
    );
  }

  /// Handle session end
  void _handleSessionEnd() {
    state = state.copyWith(voiceState: VoiceInterfaceState.idle);
  }

  /// Send text message (기존 유지 - HTTP API 사용)
  /// Send text message via HTTP API
  Future<void> sendTextMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    // 🆕 텍스트 입력 플래그 설정
    _isVoiceInput = false;

    // Add user message to UI
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
      // ✅ Update session time
      await _onMessageSent();

      print('[ChatProvider] 📤 Sending text message...');

      // ✅ Call ChatRepository to send text message
      final response = await _chatRepository.sendTextMessageRaw(
        text: text,
        userId: _userId,
        sessionId: state.sessionId,
        ttsEnabled: state.ttsEnabled, // ✅ TTS 활성화 여부 전달
      );

      print('[ChatProvider] 📥 Received response: $response');

      // Extract alarm_info and response_type from raw response
      final replyText = response['reply_text'] as String?;
      final emotion = response['emotion'] as String?;
      final responseType = response['response_type'] as String?;
      final ttsAudioUrl = response['tts_audio_url'] as String?; // ✅ TTS URL
      final alarmInfo = response['alarm_info'] as Map<String, dynamic>?;

      print('[ChatProvider] 🔍 [TEXT] response_type: $responseType');
      print('[ChatProvider] 🔍 [TEXT] alarm_info: $alarmInfo');

      // Create AI message with metadata
      final aiMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: replyText ?? '',
        isUser: false,
        timestamp: DateTime.now(),
        meta: {
          if (emotion != null) 'emotion': emotion,
          if (responseType != null) 'response_type': responseType,
          if (alarmInfo != null) 'alarm_info': alarmInfo,
        },
      );

      // Add AI response to UI
      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
      );

      print('[ChatProvider] ✅ [TEXT] Message added to state');

      // 🆕 Alarm 처리 (텍스트 입력 시에도 다이얼로그 표시)
      if (responseType == 'alarm' && alarmInfo != null && replyText != null) {
        print('[ChatProvider] 🔔 [TEXT] Alarm detected');
        print('[ChatProvider] 🔔 [TEXT] onShowAlarmDialog: $onShowAlarmDialog');
        
        // 🆕 다이얼로그 표시
        onShowAlarmDialog?.call(alarmInfo, replyText);

        // 🆕 AlarmProvider에 알람 데이터 전달
        final alarmDataList = alarmInfo['data'] as List<dynamic>?;
        if (alarmDataList != null && alarmDataList.isNotEmpty) {
          // 유효한 알람만 필터링
          final validAlarms = alarmDataList
              .cast<Map<String, dynamic>>()
              .where((alarm) => alarm['is_valid_alarm'] == true)
              .toList();

          if (validAlarms.isNotEmpty) {
            _ref.read(alarmProvider.notifier).addAlarms(validAlarms);
            print(
                '[ChatProvider] 📝 [TEXT] ${validAlarms.length} valid alarms sent to AlarmProvider');
          }
        }
      }
      
      // ✅ TTS 재생
      if (state.ttsEnabled && ttsAudioUrl != null && ttsAudioUrl.isNotEmpty) {
         _playTtsAudio(ttsAudioUrl);
      }
    } catch (e) {
      print('[ChatProvider] ❌ Error in sendTextMessage: $e');
      state = state.copyWith(
        isLoading: false,
        error: '메시지 전송 실패: $e',
      );
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

  // ============================================================================
  // Session Management (5분 유지)
  // ============================================================================

  /// Initialize or restore session
  Future<void> _initializeSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSessionId = prefs.getString(_sessionIdKey);
      final savedTimeStr = prefs.getString(_sessionTimeKey);

      if (savedSessionId != null && savedTimeStr != null) {
        final savedTime = DateTime.parse(savedTimeStr);
        final elapsed = DateTime.now().difference(savedTime);

        // 5분 이내면 기존 session 재사용
        if (elapsed < _sessionDuration) {
          state = state.copyWith(sessionId: savedSessionId);
          await _updateSessionTime();
          print(
              '✅ Session restored: $savedSessionId (${elapsed.inMinutes}m ago)');
          return;
        }
      }

      // 새 session 생성
      await _createNewSession();
    } catch (e) {
      print('❌ Session init failed: $e');
      await _createNewSession();
    }
  }

  /// Create new session
  Future<void> _createNewSession() async {
    final newSessionId =
        'user_${_userId}_${DateTime.now().millisecondsSinceEpoch}';
    state = state.copyWith(sessionId: newSessionId);
    await _saveSession(newSessionId);
    print('🆕 New session created: $newSessionId');
  }

  /// Save session to SharedPreferences
  Future<void> _saveSession(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionIdKey, sessionId);
      await prefs.setString(_sessionTimeKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('❌ Session save failed: $e');
    }
  }

  /// Update session last used time
  Future<void> _updateSessionTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionTimeKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('❌ Session time update failed: $e');
    }
  }

  Future<void> loadSession(String sessionId) async {
    // 1. 현재 상태에 세션 ID 적용
    state = state.copyWith(sessionId: sessionId, isLoading: true);

    try {
      print('📥 Loading session: $sessionId');

      // TODO: 만약 서버에 '이전 대화 내역'을 요청하는 API가 있다면 여기서 호출하세요.
      // 예: final history = await _chatRepository.getChatHistory(sessionId);
      // state = state.copyWith(messages: history, isLoading: false);

      // 현재는 API가 없으므로 로딩만 해제합니다.
      state = state.copyWith(isLoading: false);

      // 세션 시간 갱신 (선택 사항)
      await _saveSession(sessionId);
      print('✅ Session loaded: $sessionId');
    } catch (e) {
      print('❌ Error loading session: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 화면에서 '세션 초기화' 버튼 등을 눌렀을 때 사용
  Future<void> resetSession() async {
    print('🔄 Resetting session manually...');

    // 1. 화면의 메시지 목록 비우기
    clearMessages();

    // 2. 새로운 세션 ID 발급 및 저장 (기존 함수 재사용)
    await _createNewSession();

    print('✅ Session reset to new id: ${state.sessionId}');
  }

  /// Update session time on message send
  Future<void> _onMessageSent() async {
    await _updateSessionTime();
  }

  // ============================================================================
  // TTS Management
  // ============================================================================

  /// Load TTS enabled state from SharedPreferences
  Future<void> _loadTtsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ttsEnabled = prefs.getBool(_ttsEnabledKey) ?? false;
      state = state.copyWith(ttsEnabled: ttsEnabled);
      print('✅ TTS enabled loaded: $ttsEnabled');
    } catch (e) {
      print('❌ TTS enabled load failed: $e');
    }
  }

  /// Toggle TTS enabled state
  Future<void> toggleTtsEnabled() async {
    final newValue = !state.ttsEnabled;
    state = state.copyWith(ttsEnabled: newValue);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_ttsEnabledKey, newValue);
      print('✅ TTS enabled toggled: $newValue');
    } catch (e) {
      print('❌ TTS enabled save failed: $e');
    }
  }

  @override
  void dispose() {
    _bomChatService.dispose();
    super.dispose();
  }
  
  /// Play TTS Audio
  Future<void> _playTtsAudio(String source) async {
    // 음성 채팅 중이면 재생하지 않음 (backend가 처리하거나 중복 방지)
    if (state.voiceState == VoiceInterfaceState.listening || 
        state.voiceState == VoiceInterfaceState.processing) {
       return;   
    }
    
    // 🆕 음성 채팅 중이 아닐 때만 (텍스트 입력 시) voiceState 변경
    final isVoiceChatActive = _bomChatService.isActive;
    
    if (!isVoiceChatActive) {
      // 텍스트 모드: replying 상태로 변경
      state = state.copyWith(voiceState: VoiceInterfaceState.replying);
    }
    
    await _ttsPlayerService.play(source);
    
    // 🆕 텍스트 모드일 때는 TTS 재생 후 idle로 복귀
    if (!isVoiceChatActive) {
      // 약간의 딜레이 후 idle로 복귀 (TTS 재생 완료 시간 고려)
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !_bomChatService.isActive) {
          state = state.copyWith(voiceState: VoiceInterfaceState.idle);
        }
      });
    }
  }
}

/// Chat provider (Phase 2 - BomChatService 사용)
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final bomChatService = ref.watch(bomChatServiceProvider);
  final chatRepository =
      ref.watch(chatRepositoryProvider); // ✅ ChatRepository 추가
  final permissionService = ref.watch(permissionServiceProvider);
  final ttsPlayerService = ref.watch(ttsPlayerServiceProvider); // ✅ TTS Service
  final currentUser = ref.watch(currentUserProvider);

  if (currentUser == null) {
    throw Exception('User not authenticated');
  }

  return ChatNotifier(
    bomChatService,
    chatRepository, // ✅ ChatRepository 주입
    ttsPlayerService, // ✅ TTS Service 주입
    currentUser.id,
    permissionService,
    ref, // 🆕 Ref 주입
  );
});
