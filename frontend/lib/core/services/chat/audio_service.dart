import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';
import '../../utils/logger.dart';

/// Audio Service - Handles audio recording using flutter_sound
class AudioService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  StreamController<Uint8List>? _streamController;
  StreamController<Float32List>? _outputController;
  StreamSubscription<Uint8List>? _streamSubscription;
  bool _isRecorderInitialized = false;
  bool _pcm16DiagDone = false;

  // Buffer for accumulating samples to create 512-sample chunks
  final List<double> _sampleBuffer = [];

  /// Initialize the recorder
  Future<void> _initRecorder() async {
    if (_isRecorderInitialized) return;

    await _recorder.openRecorder();
    _isRecorderInitialized = true;
    appLogger.i('FlutterSoundRecorder initialized');
  }

  /// Start recording audio stream
  /// Note: Permission should be checked/requested before calling this method
  Future<Stream<Float32List>?> startRecording() async {
    try {
      await _initRecorder();

      // Create stream controllers
      _streamController = StreamController<Uint8List>();
      _outputController = StreamController<Float32List>();
      _sampleBuffer.clear();
      _pcm16DiagDone = false;

      // Start recording to stream
      await _recorder.startRecorder(
        toStream: _streamController!.sink,
        codec: Codec.pcm16,
        sampleRate: 16000, // 16kHz for Whisper
        numChannels: 1, // Mono
      );

      // Listen to the PCM16 stream and convert to Float32 chunks
      _streamSubscription = _streamController!.stream.listen(
        (pcm16Bytes) {
          if (pcm16Bytes.isEmpty) return;

          // Convert Uint8List (PCM16) to Int16List
          final int16Data = Int16List.view(pcm16Bytes.buffer);

          // 🔍 원본 PCM16 데이터 품질 확인 (첫 청크만)
          if (!_pcm16DiagDone && int16Data.length > 100) {
            _pcm16DiagDone = true;
            final maxValue =
                int16Data.reduce((a, b) => a.abs() > b.abs() ? a : b);
            final minValue = int16Data.reduce((a, b) => a < b ? a : b);
            final avgValue =
                int16Data.reduce((a, b) => a + b) / int16Data.length;

            appLogger.i('🎤 RAW PCM16 DIAGNOSTIC:');
            appLogger.i('  - Samples: ${int16Data.length}');
            appLogger.i('  - Min: $minValue, Max: $maxValue');
            appLogger.i('  - Avg: ${avgValue.toStringAsFixed(1)}');
            appLogger.i('  - First 10 values: ${int16Data.sublist(0, 10)}');

            // 전부 0이거나 일정한 값이면 마이크 문제
            final allZero = int16Data.every((v) => v == 0);
            final allSame = int16Data.every((v) => v == int16Data[0]);
            if (allZero) {
              appLogger
                  .e('❌ PCM16 data is ALL ZEROS - Microphone not working!');
            } else if (allSame) {
              appLogger.e('❌ PCM16 data is CONSTANT - Microphone not working!');
            } else if (maxValue.abs() < 100) {
              appLogger.e(
                  '❌ PCM16 amplitude too low (max=${maxValue}) - No real audio!');
            } else {
              appLogger.i('✅ PCM16 looks like real audio data');
            }
          }

          // Convert Int16 to Float32 and add to buffer
          // 🔧 Unsigned → Signed 변환 (flutter_sound가 0~32767 범위 제공)
          for (int i = 0; i < int16Data.length; i++) {
            // Unsigned → Signed: 16384를 빼서 중심을 0으로
            final signedValue = int16Data[i] - 16384;
            final normalized = signedValue / 16384.0; // -1.0 to 1.0
            _sampleBuffer.add(normalized);

            // Send in 512-sample chunks
            while (_sampleBuffer.length >= 512) {
              final chunk = Float32List.fromList(_sampleBuffer.sublist(0, 512));
              _outputController?.add(chunk);
              _sampleBuffer.removeRange(0, 512);
            }
          }
        },
        onError: (error) {
          appLogger.e('Recording stream error', error: error);
          _outputController?.addError(error);
        },
        onDone: () {
          appLogger.i('Recording stream ended');
          _outputController?.close();
        },
      );

      appLogger.i('Audio recording started with flutter_sound');
      return _outputController?.stream;
    } catch (e) {
      appLogger.e('Failed to start recording', error: e);
      return null;
    }
  }

  /// Stop recording
  Future<void> stopRecording() async {
    try {
      await _streamSubscription?.cancel();
      _streamSubscription = null;

      await _recorder.stopRecorder();

      await _streamController?.close();
      _streamController = null;

      await _outputController?.close();
      _outputController = null;

      _sampleBuffer.clear();

      appLogger.i('Audio recording stopped');
    } catch (e) {
      appLogger.e('Error stopping recording', error: e);
    }
  }

  /// Check if recording
  Future<bool> isRecording() async {
    return _recorder.isRecording;
  }

  /// Dispose resources
  Future<void> dispose() async {
    await stopRecording();

    if (_isRecorderInitialized) {
      await _recorder.closeRecorder();
      _isRecorderInitialized = false;
    }

    appLogger.i('AudioService disposed');
  }
}
