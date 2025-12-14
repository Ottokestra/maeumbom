import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Chat WebSocket Service
/// /agent/stream 엔드포인트용 WebSocket 클라이언트
/// session_id 전송, TTS 토글, 오디오 청크 전송, 응답 수신
class ChatWebSocketService {
  WebSocketChannel? _channel;
  final _responseController =
      StreamController<Map<String, dynamic>>.broadcast();

  bool _isConnected = false;
  String? _currentSessionId;
  bool _ttsEnabled = true; // 🆕 TTS 설정 저장

  /// Web Socket 연결
  /// [userId]: 사용자 ID
  /// [sessionId]: 세션 ID (생성된 경우)
  /// [wsUrl]: WebSocket URL (기본값: localhost)
  /// [ttsEnabled]: TTS 생성 여부 (기본값: true)
  Future<void> connect({
    required String userId,
    String? sessionId,
    String wsUrl = 'ws://10.0.2.2:8000/agent/stream', // Android 에뮬레이터용
    bool ttsEnabled = true, // 🆕 TTS 토글 설정
  }) async {
    if (_isConnected) {
      debugPrint('[ChatWebSocketService] 이미 연결되어 있습니다');
      return;
    }

    // 🆕 TTS 설정 저장
    _ttsEnabled = ttsEnabled;

    try {
      debugPrint('[ChatWebSocketService] 연결 시작: $wsUrl');

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _isConnected = true;

      // session_id 생성 (제공되지 않은 경우)
      _currentSessionId =
          sessionId ?? 'session_${DateTime.now().millisecondsSinceEpoch}';

      debugPrint('[ChatWebSocketService] Session ID: $_currentSessionId');

      // 연결 후 초기화 메시지 전송
      await Future.delayed(const Duration(milliseconds: 100));
      _sendSessionInit(userId);

      // 응답 수신 리스너
      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          debugPrint('[ChatWebSocketService] 에러: $error');
          _isConnected = false;
        },
        onDone: () {
          debugPrint('[ChatWebSocketService] 연결 종료');
          _isConnected = false;
        },
      );

      debugPrint('[ChatWebSocketService] 연결 완료');
    } catch (e) {
      debugPrint('[ChatWebSocketService] 연결 실패: $e');
      _isConnected = false;
      rethrow;
    }
  }

  /// 세션 초기화 메시지 전송
  void _sendSessionInit(String userId) {
    if (!_isConnected || _channel == null) return;

    try {
      // ✅ session_id를 텍스트 메시지로 전송 (백엔드 프로토콜)
      final initMessage = jsonEncode({
        'type': 'session_init',
        'user_id': userId,
        'session_id': _currentSessionId,
        'tts_enabled': _ttsEnabled ? 1 : 0, // 🆕 TTS 토글 (사용자 설정 반영)
      });

      debugPrint('[ChatWebSocketService] 🔍 세션 초기화 메시지: $initMessage');
      _channel!.sink.add(initMessage);
      debugPrint('[ChatWebSocketService] 세션 초기화 메시지 전송');
    } catch (e) {
      debugPrint('[ChatWebSocketService] 세션 초기화 실패: $e');
    }
  }

  /// 오디오 청크 전송
  /// [chunk]: Int16List (512 samples) - PCM16 직접 전송
  void sendAudioChunk(Int16List chunk) {
    if (!_isConnected || _channel == null) {
      debugPrint('[ChatWebSocketService] 연결되지 않음');
      return;
    }

    try {
      // Int16List → Uint8List 변환
      final bytes = chunk.buffer.asUint8List();
      _channel!.sink.add(bytes);
    } catch (e) {
      debugPrint('[ChatWebSocketService] 오디오 전송 실패: $e');
    }
  }

  /// 메시지 처리
  void _handleMessage(dynamic message) {
    try {
      if (message is String) {
        // JSON 응답
        final data = jsonDecode(message) as Map<String, dynamic>;
        debugPrint(
            '[ChatWebSocketService] 응답 수신: ${data['type'] ?? 'unknown'}');
        _responseController.add(data);
      } else {
        debugPrint('[ChatWebSocketService] 바이너리 메시지 수신 (무시)');
      }
    } catch (e) {
      debugPrint('[ChatWebSocketService] 메시지 처리 실패: $e');
    }
  }

  /// 응답 스트림
  Stream<Map<String, dynamic>> get responseStream => _responseController.stream;

  /// 현재 세션 ID
  String? get sessionId => _currentSessionId;

  /// 연결 상태
  bool get isConnected => _isConnected;

  /// 연결 종료
  Future<void> disconnect() async {
    if (!_isConnected) return;

    debugPrint('[ChatWebSocketService] 연결 종료 중...');

    await _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _currentSessionId = null;

    debugPrint('[ChatWebSocketService] 연결 종료 완료');
  }

  /// 정리
  Future<void> dispose() async {
    await disconnect();
    await _responseController.close();
  }
}
