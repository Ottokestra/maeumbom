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
  processingVoice, // 🆕 음성 처리 중 (STT) - 발화 종료 감지 후
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
  static const _sessionDuration = Duration(minutes: 10);
  static const _sessionIdKey = 'chat_session_id';
  static const _sessionTimeKey = 'chat_session_time';
  static const _ttsEnabledKey = 'chat_tts_enabled'; // ✅ TTS 상태 저장 키

  // 🆕 Alarm dialog callback
  void Function(Map<String, dynamic> alarmInfo, String replyText)?
      onShowAlarmDialog;

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
    _bomChatService.onStatusChange = _handleStatusChange; // 🆕 WebSocket 상태 변경
    _bomChatService.onSpeechEnd = _handleSpeechEnd; // 🆕 발화 종료
    _bomChatService.onLowQuality = _handleLowQuality; // 🆕 low_quality STT
  }

  // 🆕 발화 종료 처리
  void _handleSpeechEnd() {
    print('[ChatProvider] ⚡⚡⚡ 발화 종료 콜백 호출됨! ⚡⚡⚡');
    print('[ChatProvider] 이전 상태: ${state.voiceState}');
    state = state.copyWith(voiceState: VoiceInterfaceState.processingVoice);
    _bomChatService.pauseAudioTransmission(); // 🆕 오디오 전송 일시 중지
    print(
        '[ChatProvider] ✅ 상태 변경 완료 → processingVoice (노란색 버튼, STT 처리, 오디오 중지)');
  }

  // 🆕 low_quality STT 처리
  void _handleLowQuality(String message) {
    print('[ChatProvider] ⚠️⚠️⚠️ low_quality STT 감지! ⚠️⚠️⚠️');
    print('[ChatProvider] 메시지: $message');
    print('[ChatProvider] 이전 상태: ${state.voiceState}');

    // 🆕 품질이 낮으면 대화 중지
    print('[ChatProvider] 품질 낮음으로 인한 대화 중지');
    stopAudioRecording();
  }

  // ✅ STT 결과 처리 - 사용자 메시지 UI에 표시 및 processing 상태로 전환
  void _handleSttResult(String sttText) {
    print('[ChatProvider] 📝 STT 결과 수신: "$sttText"');
    print('[ChatProvider] 현재 상태: ${state.voiceState}');

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: sttText,
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
    );

    print('[ChatProvider] ✅ STT 메시지 추가 완료 (상태는 유지: ${state.voiceState})');
  }

  // Phase 3: STT partial 결과 처리 (비활성화)
  void _handlePartialText(String partialText) {
    state = state.copyWith(sttPartialText: partialText);
  }

  // 🆕 WebSocket 상태 변경 처리
  void _handleStatusChange(String status, String message) {
    print('[ChatProvider] 🔔 Status change: $status - $message');

    switch (status) {
      case 'connecting':
        // 모델 로딩 중 - 이미 loading 상태로 설정되어 있음
        break;

      case 'ready':
        // 준비 완료 - listening 상태로 전환 (startAudioRecording에서 처리)
        break;

      case 'processing_voice':
        // 🆕 음성 처리 중 (STT) - 발화 종료 감지 후
        state = state.copyWith(voiceState: VoiceInterfaceState.processingVoice);
        break;

      case 'processing':
        // AI 생각 중
        state = state.copyWith(voiceState: VoiceInterfaceState.processing);
        break;
    }
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
        ttsEnabled: state.ttsEnabled, // 🆕 TTS 토글 설정 전달
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
    // 🆕 tts_ready 타입 처리
    if (response['type'] == 'tts_ready') {
      final ttsAudio = response['tts_audio'] as String?;
      print('[ChatProvider] 🎵 TTS 준비 완료: $ttsAudio');

      if (state.ttsEnabled && ttsAudio != null && ttsAudio.isNotEmpty) {
        // TTS URL을 완전한 HTTP URL로 변환
        String ttsUrl = ttsAudio;
        if (ttsAudio.startsWith('/')) {
          ttsUrl = 'http://10.0.2.2:8000$ttsAudio';
        }

        print('[ChatProvider] 🎵 TTS 재생 시작: $ttsUrl');

        // 🆕 TTS 재생 (이제 play()가 완료를 기다림)
        _ttsPlayerService.play(ttsUrl).then((_) {
          print('[ChatProvider] ✅ TTS 재생 완료');
          if (state.voiceState == VoiceInterfaceState.replying &&
              _bomChatService.isActive) {
            state = state.copyWith(voiceState: VoiceInterfaceState.listening);
            _bomChatService.resumeAudioTransmission();
            print('[ChatProvider] TTS 재생 완료 - listening으로 전환 (오디오 재개)');
          }
        }).catchError((error) {
          print('[ChatProvider] ❌ TTS 재생 실패: $error');
          // 실패해도 listening으로 전환 + 오디오 재개
          if (state.voiceState == VoiceInterfaceState.replying &&
              _bomChatService.isActive) {
            state = state.copyWith(voiceState: VoiceInterfaceState.listening);
            _bomChatService.resumeAudioTransmission();
            print('[ChatProvider] TTS 실패 - listening으로 전환 (오디오 재개)');
          }
        });
      } else {
        // TTS가 비활성화되었거나 URL이 없는 경우
        if (state.voiceState == VoiceInterfaceState.replying &&
            _bomChatService.isActive) {
          state = state.copyWith(voiceState: VoiceInterfaceState.listening);
          _bomChatService.resumeAudioTransmission();
          print('[ChatProvider] TTS 비활성화 - listening으로 전환 (오디오 재개)');
        }
      }
      return;
    }

    // 기존 agent_response 처리
    final replyText = response['reply_text'] as String?;
    final emotion = response['emotion'] as String?;
    final responseType = response['response_type'] as String?;
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
        print(
            '[ChatProvider] 🔔 [VOICE] onShowAlarmDialog: $onShowAlarmDialog');

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
      }

      // 🆕 TTS 비활성화 시 즉시 listening으로 전환
      if (_bomChatService.isActive && !state.ttsEnabled) {
        print('[ChatProvider] 🔇 TTS OFF - 즉시 listening으로 전환');
        state = state.copyWith(voiceState: VoiceInterfaceState.listening);
        _bomChatService.resumeAudioTransmission();
      }
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

    // 🆕 세션 만료 감지 (메시지 전송 전에 체크)
    String? expiredSessionId;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTimeStr = prefs.getString(_sessionTimeKey);

      if (savedTimeStr != null) {
        final savedTime = DateTime.parse(savedTimeStr);
        final elapsed = DateTime.now().difference(savedTime);

        // 세션 시간 초과 감지 (하지만 아직 변경하지 않음)
        if (elapsed >= _sessionDuration) {
          expiredSessionId = state.sessionId;
          print('⏰ [Session Expiry] Detected: $expiredSessionId');
          print(
              '⏰ [Session Expiry] Elapsed: ${elapsed.inMinutes}m ${elapsed.inSeconds % 60}s');
          print('⏰ [Session Expiry] Will trigger analysis AFTER message send');
        }
      }
    } catch (e) {
      print('❌ Session expiry check failed: $e');
    }

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
      print('[ChatProvider] 📤 Sending text message...');

      // ✅ Call ChatRepository to send text message (기존 세션으로 전송)
      final response = await _chatRepository.sendTextMessageRaw(
        text: text,
        userId: _userId,
        sessionId: state.sessionId, // 만료된 세션 ID로 전송
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

      // TTS 플레이
      if (state.ttsEnabled && ttsAudioUrl != null && ttsAudioUrl.isNotEmpty) {
        await _playTtsAudio(ttsAudioUrl);
      }

      print('[ChatProvider] ✅ Text message sent successfully');

      // 🆕 메시지 전송 완료 후 세션 처리
      if (expiredSessionId != null) {
        // 세션이 만료되었으므로 새 세션 생성 및 감정분석 trigger
        print('⏰ [Session Expiry] Message sent. Now creating new session...');
        await _createNewSession(expiredSessionId: expiredSessionId);
      } else {
        // 세션 시간만 업데이트
        await _updateSessionTime();
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
        } else {
          // 🆕 5분 초과 → 세션 만료 → 감정분석 trigger
          print(
              '⏰ Session expired: $savedSessionId (${elapsed.inMinutes}m ago)');
          await _createNewSession(expiredSessionId: savedSessionId);
          return;
        }
      }

      // 새 session 생성 (처음 실행)
      await _createNewSession();
    } catch (e) {
      print('❌ Session init failed: $e');
      await _createNewSession();
    }
  }

  /// Create new session
  Future<void> _createNewSession({String? expiredSessionId}) async {
    final newSessionId =
        'user_${_userId}_${DateTime.now().millisecondsSinceEpoch}';
    state = state.copyWith(sessionId: newSessionId);
    await _saveSession(newSessionId);
    print('🆕 New session created: $newSessionId');

    // 🆕 이전 세션이 있었다면 감정분석 trigger
    if (expiredSessionId != null && !expiredSessionId.endsWith('_default')) {
      _triggerSessionEmotionAnalysis(expiredSessionId);
    }
  }

  /// 🆕 세션 만료 시 감정분석 트리거
  Future<void> _triggerSessionEmotionAnalysis(String expiredSessionId) async {
    try {
      print('[Emotion] 🔄 Session expired: $expiredSessionId');
      print('[Emotion] 📊 Triggering emotion analysis...');

      final dio = _ref.read(dioWithAuthProvider);
      await dio.post('/emotion/api/analyze-session', data: {
        'session_id': expiredSessionId,
      });

      print('[Emotion] ✅ Session emotion analysis completed');
    } catch (e) {
      // 404는 메시지가 없는 정상 상황
      if (e.toString().contains('404') ||
          e.toString().contains('No user messages')) {
        print('[Emotion] ⚠️ No messages in session (skipped analysis)');
      } else {
        print('[Emotion] ❌ Session emotion analysis failed: $e');
      }
      // Silent fail - 백그라운드 작업이므로 UI에 영향 없음
    }
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
    // 🆕 세션 만료 감지 (메시지 전송 시점에 체크)
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTimeStr = prefs.getString(_sessionTimeKey);

      if (savedTimeStr != null) {
        final savedTime = DateTime.parse(savedTimeStr);
        final elapsed = DateTime.now().difference(savedTime);

        // 세션 시간 초과 시 → 이전 세션 만료로 처리
        if (elapsed >= _sessionDuration) {
          final expiredSessionId = state.sessionId;
          print(
              '⏰ [Session Expiry] Detected during message send: $expiredSessionId');
          print(
              '⏰ [Session Expiry] Elapsed: ${elapsed.inMinutes}m ${elapsed.inSeconds % 60}s');

          // 새 세션 생성 (감정분석 trigger 포함)
          await _createNewSession(expiredSessionId: expiredSessionId);
          return;
        }
      }
    } catch (e) {
      print('❌ Session expiry check failed: $e');
    }

    // 세션 시간 갱신
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
    print('[ChatProvider] ✅ TTS 재생 완료');

    // 🆕 음성 모드 vs 텍스트 모드 처리 분리
    if (isVoiceChatActive) {
      // 음성 모드: listening 전환 + 오디오 재개
      if (state.voiceState == VoiceInterfaceState.replying) {
        state = state.copyWith(voiceState: VoiceInterfaceState.listening);
        _bomChatService.resumeAudioTransmission(); // 🆕 오디오 전송 재개
        print('[ChatProvider] [VOICE] TTS 완료 - listening 전환 (오디오 재개)');
      }
    } else {
      // 텍스트 모드: idle로 복귀
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
