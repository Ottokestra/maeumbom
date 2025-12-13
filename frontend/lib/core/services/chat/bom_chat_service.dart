import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'audio_recorder_service.dart';
import 'chat_websocket_service.dart';

/// Bom Chat Service
/// 오디오 녹음과 WebSocket 통신을 조율하는 메인 서비스
/// 음성 채팅 시작/중지, emotion 처리, TTS 재생 관리
class BomChatService {
  final AudioRecorderService _audioService = AudioRecorderService();
  final ChatWebSocketService _wsService = ChatWebSocketService();

  StreamSubscription<Int16List>? _audioSubscription; // ✅ Float32 → Int16
  StreamSubscription<Map<String, dynamic>>? _responseSubscription;

  bool _isActive = false;

  // 응답 콜백
  Function(Map<String, dynamic>)? onResponse;
  Function(String)? onError;
  Function()? onSessionEnd;
  Function(String)? onPartialText; // Phase 3 (비활성화)
  Function(String)? onSttResult; // ✅ STT 결과 → 사용자 메시지 표시
  Function(String status, String message)? onStatusChange; // 🆕 WebSocket 상태 변경

  /// 음성 채팅 시작
  /// [userId]: 사용자 ID
  /// [sessionId]: 세션 ID (선택적)
  /// [wsUrl]: WebSocket URL (선택적, 기본값: localhost)
  Future<void> startVoiceChat({
    required String userId,
    String? sessionId,
    String? wsUrl,
  }) async {
    if (_isActive) {
      debugPrint('[BomChatService] 이미 음성 채팅이 진행 중입니다');
      return;
    }

    try {
      debugPrint('[BomChatService] 음성 채팅 시작');

      // 1. WebSocket 연결
      await _wsService.connect(
        userId: userId,
        sessionId: sessionId,
        wsUrl: wsUrl ?? 'ws://localhost:8000/agent/stream',
      );

      // 2. Backend 준비 완료 대기용 Completer
      final readyCompleter = Completer<void>();

      // 3. 응답 수신 리스너 설정
      _responseSubscription = _wsService.responseStream.listen(
        (response) {
          final type = response['type'] as String?;
          final status = response['status'] as String?;

          // ✅ Backend 준비 완료 신호 대기
          if (type == 'status' &&
              status == 'ready' &&
              !readyCompleter.isCompleted) {
            debugPrint('[BomChatService] Backend 준비 완료 - 녹음 시작');
            readyCompleter.complete();
          }

          // 일반 응답 처리
          _handleResponse(response);
        },
        onError: (error) {
          debugPrint('[BomChatService] 응답 스트림 에러: $error');
          if (!readyCompleter.isCompleted) {
            readyCompleter.completeError(error);
          }
          onError?.call('응답 수신 실패: $error');
        },
      );

      // 4. ✅ Backend 준비 완료 대기 (timeout 30초)
      await readyCompleter.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Backend 준비 시간 초과');
        },
      );

      // 5. 준비 완료 후 오디오 녹음 시작
      final audioStream = await _audioService.startRecording();

      // 5. 오디오 청크를 WebSocket으로 스트리밍
      int chunkCount = 0; // 디버그용 카운터
      _audioSubscription = audioStream.listen(
        (chunk) {
          _wsService.sendAudioChunk(chunk);
          chunkCount++;
          // 10초마다 로그 (16kHz, 512 samples = 32ms per chunk, ~31 chunks/sec)
          if (chunkCount % 310 == 0) {
            debugPrint(
                '[BomChatService] 오디오 청크 전송 중... (${chunkCount} chunks, ${chunkCount * 32 ~/ 1000}초)');
          }
        },
        onError: (error) {
          debugPrint('[BomChatService] 오디오 스트림 에러: $error');
          onError?.call('오디오 녹음 실패: $error');
        },
        onDone: () {
          debugPrint('[BomChatService] 오디오 스트림 종료됨 (onDone 호출)');
        },
      );

      _isActive = true;
      debugPrint('[BomChatService] 음성 채팅 활성화됨');
    } catch (e) {
      debugPrint('[BomChatService] 음성 채팅 시작 실패: $e');
      onError?.call('음성 채팅 시작 실패: $e');
      await stopVoiceChat();
      rethrow;
    }
  }

  /// 응답 처리
  void _handleResponse(Map<String, dynamic> response) {
    try {
      final type = response['type'] as String?;

      debugPrint('[BomChatService] 응답 타입: $type');

      switch (type) {
        case 'status':
          // 🆕 상태 메시지 처리 - 콜백 호출
          final status = response['status'] as String?;
          final message = response['message'] as String?;
          debugPrint('[BomChatService] 상태: $status - $message');
          if (status != null && message != null) {
            onStatusChange?.call(status, message);
          }
          break;

        case 'stt_result':
          // ✅ STT 결과 → 사용자 메시지로 표시
          final sttText = response['text'] as String?;
          if (sttText != null && sttText.isNotEmpty) {
            debugPrint('[BomChatService] STT 결과: $sttText');
            onSttResult?.call(sttText);
          }
          break;

        case 'stt_partial':
          // Phase 3 partial (비활성화)
          debugPrint('[BomChatService] STT Partial 수신 (무시)');
          break;

        case 'agent_response':
          _handleAgentResponse(response['data'] as Map<String, dynamic>);
          break;

        case 'session_end':
          debugPrint('[BomChatService] 세션 종료');
          onSessionEnd?.call();
          break;

        case 'error':
          final errorMsg = response['message'] as String? ?? '알 수 없는 오류';
          debugPrint('[BomChatService] 백엔드 에러: $errorMsg');
          onError?.call(errorMsg);
          break;

        case 'tts_ready':
          // 🆕 TTS 오디오 준비 완료 - URL 전달
          final audioUrl = response['audio_url'] as String?;
          if (audioUrl != null) {
            debugPrint('[BomChatService] TTS 오디오 준비: $audioUrl');
            // TTS URL을 onResponse 콜백으로 전달
            onResponse?.call({
              'tts_audio': audioUrl,
              'type': 'tts_ready',
            });
          }
          break;

        default:
          debugPrint('[BomChatService] 알 수 없는 응답 타입: $type');
      }
    } catch (e) {
      debugPrint('[BomChatService] 응답 처리 실패: $e');
      onError?.call('응답 처리 실패: $e');
    }
  }

  /// Agent 응답 처리
  void _handleAgentResponse(Map<String, dynamic> data) {
    try {
      final replyText = data['reply_text'] as String?;
      final emotion = data['emotion'] as String?;
      final responseType = data['response_type'] as String?;
      final ttsAudio = data['tts_audio'] as String?; // base64 or null
      final alarmInfo = data['alarm_info'] as Map<String, dynamic>?; // 🆕

      debugPrint('[BomChatService] Agent 응답:');
      debugPrint('  - 텍스트: $replyText');
      debugPrint('  - 감정: $emotion');
      debugPrint('  - 응답 타입: $responseType');
      debugPrint('  - TTS: ${ttsAudio != null ? "있음" : "없음"}');
      debugPrint('  - Alarm Info: ${alarmInfo != null ? "있음" : "없음"}'); // 🆕

      // 콜백 호출
      onResponse?.call({
        'reply_text': replyText,
        'emotion': emotion,
        'response_type': responseType,
        'tts_audio': ttsAudio,
        if (alarmInfo != null) 'alarm_info': alarmInfo, // 🆕
      });

      // TODO: TTS 오디오 재생 로직
      // if (ttsAudio != null) {
      //   _playTtsAudio(ttsAudio);
      // }
    } catch (e) {
      debugPrint('[BomChatService] Agent 응답 처리 실패: $e');
      onError?.call('Agent 응답 처리 실패: $e');
    }
  }

  /// 음성 채팅 중지
  Future<void> stopVoiceChat() async {
    if (!_isActive) return;

    debugPrint('[BomChatService] 음성 채팅 중지 중...');

    _isActive = false;

    // 1. 오디오 녹음 중지
    await _audioSubscription?.cancel();
    await _audioService.stopRecording();

    // 2. WebSocket 연결 종료
    await _responseSubscription?.cancel();
    await _wsService.disconnect();

    debugPrint('[BomChatService] 음성 채팅 중지 완료');
  }

  /// 현재 세션 ID
  String? get sessionId => _wsService.sessionId;

  /// 활성 상태
  bool get isActive => _isActive;

  /// 텍스트 메시지 전송 (REST API)
  /// WebSocket 없이 직접 텍스트를 전송하고 응답을 받음
  Future<Map<String, dynamic>> sendTextMessage({
    required String text,
    required int userId,
    String? sessionId,
    String? apiUrl,
  }) async {
    try {
      final Uri url = Uri.parse(
        apiUrl ?? 'http://localhost:8000/api/agent/v2/text',
      );

      final body = {
        'user_text': text,
        'user_id': userId,
        'session_id':
            sessionId ?? 'session_${DateTime.now().millisecondsSinceEpoch}',
      };

      debugPrint('[BomChatService] 텍스트 메시지 전송: $text');

      // HTTP POST 요청 (http 패키지 대신 WebSocketChannel 또는 dio 사용 고려)
      // 현재는 간단한 예시
      throw UnimplementedError(
        'HTTP POST 구현 필요: http 패키지 또는 dio 추가 필요',
      );

      // 예상 응답:
      // {
      //   'reply_text': '...',
      //   'emotion': 'happiness',
      //   'response_type': 'alarm' | 'warning' | 'normal',
      //   'alarm_info': { ... }  // alarm/warning일 때만
      // }
    } catch (e) {
      debugPrint('[BomChatService] 텍스트 메시지 전송 실패: $e');
      rethrow;
    }
  }

  /// 정리
  Future<void> dispose() async {
    await stopVoiceChat();
    await _audioService.dispose();
    await _wsService.dispose();
  }
}
