import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../core/config/api_config.dart';
import '../../../core/utils/logger.dart';

/// WebSocket Client for audio streaming
class ChatWebSocketClient {
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _messageController;

  /// Connect to WebSocket
  Future<void> connect() async {
    try {
      appLogger.i('Connecting to WebSocket: ${ApiConfig.chatWebSocketUrl}');
      _channel = WebSocketChannel.connect(
        Uri.parse(ApiConfig.chatWebSocketUrl),
      );
      _messageController = StreamController<Map<String, dynamic>>.broadcast();

      // Listen to WebSocket messages
      _channel!.stream.listen(
        (message) {
          try {
            final data = json.decode(message as String);
            appLogger.d('WebSocket message received: $data');
            _messageController?.add(data);
          } catch (e) {
            appLogger.e('Failed to parse WebSocket message', error: e);
          }
        },
        onError: (error) {
          appLogger.e('WebSocket error', error: error);
          _messageController?.addError(error);
        },
        onDone: () {
          appLogger.i('WebSocket connection closed');
          _messageController?.close();
        },
      );
    } catch (e) {
      appLogger.e('WebSocket connection failed', error: e);
      rethrow;
    }
  }

  /// Set session ID
  void setSessionId(String sessionId) {
    if (_channel != null) {
      _channel!.sink.add(json.encode({'session_id': sessionId}));
      appLogger.i('Session ID sent: $sessionId');
    }
  }

  /// Send audio chunk (Float32Array, 512 samples)
  void sendAudioChunk(Float32List audioChunk) {
    if (_channel != null && audioChunk.length == 512) {
      // 🔍 바이트 변환 진단 (첫 청크만)
      if (!_diagDone) {
        _diagDone = true;
        final bytes = audioChunk.buffer.asUint8List();

        print(
            '[FLUTTER DIAG] Float32 first 4 values: ${audioChunk.sublist(0, 4)}');
        print('[FLUTTER DIAG] Bytes length: ${bytes.length}');
        print(
            '[FLUTTER DIAG] First 16 bytes (hex): ${bytes.sublist(0, 16).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

        // Float32 값을 수동으로 바이트로 변환하여 비교
        final byteData = ByteData(16);
        for (int i = 0; i < 4; i++) {
          byteData.setFloat32(i * 4, audioChunk[i], Endian.little);
        }
        print(
            '[FLUTTER DIAG] Manual conversion (little-endian): ${byteData.buffer.asUint8List().map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
      }

      _channel!.sink.add(audioChunk.buffer.asUint8List());
    } else {
      print(
          '[WebSocket] ⚠️ Cannot send chunk: channel=${_channel != null}, length=${audioChunk.length}');
    }
  }

  bool _diagDone = false;

  /// Stream of incoming messages
  Stream<Map<String, dynamic>>? get messageStream => _messageController?.stream;

  /// Disconnect WebSocket
  Future<void> disconnect() async {
    await _channel?.sink.close();
    await _messageController?.close();
    _channel = null;
    _messageController = null;
    appLogger.i('WebSocket disconnected');
  }

  /// Check if connected
  bool get isConnected => _channel != null;
}
