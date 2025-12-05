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
      _channel!.sink.add(audioChunk.buffer.asUint8List());
    }
  }

  /// Stream of incoming messages
  Stream<Map<String, dynamic>>? get messageStream =>
      _messageController?.stream;

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
