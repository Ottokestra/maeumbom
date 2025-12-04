import 'dart:async';
import 'dart:typed_data';
import 'package:record/record.dart';
import '../../utils/logger.dart';

/// Audio Service - Handles audio recording
class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _audioStreamSubscription;

  /// Start recording audio stream
  /// Note: Permission should be checked/requested before calling this method
  Future<Stream<Float32List>?> startRecording() async {
    try {
      // Create stream controller
      final controller = StreamController<Float32List>();

      // Start recording with stream
      // Permission is assumed to be granted (checked by caller)
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000, // 16kHz for Whisper
          numChannels: 1, // Mono
        ),
      );

      // Convert Uint8List to Float32List (512 samples chunks)
      _audioStreamSubscription = stream.listen(
        (chunk) {
          // Convert PCM16 to Float32
          final float32Chunk = _convertPcm16ToFloat32(chunk);

          // Send in 512-sample chunks
          for (int i = 0; i < float32Chunk.length; i += 512) {
            final end =
                (i + 512 < float32Chunk.length) ? i + 512 : float32Chunk.length;
            final chunkData = float32Chunk.sublist(i, end);

            if (chunkData.length == 512) {
              controller.add(chunkData);
            }
          }
        },
        onError: (error) {
          appLogger.e('Audio stream error', error: error);
          controller.addError(error);
        },
        onDone: () {
          controller.close();
        },
      );

      appLogger.i('Audio recording started');
      return controller.stream;
    } catch (e) {
      appLogger.e('Failed to start recording', error: e);
      return null;
    }
  }

  /// Stop recording
  Future<void> stopRecording() async {
    await _audioStreamSubscription?.cancel();
    await _recorder.stop();
    appLogger.i('Audio recording stopped');
  }

  /// Check if recording
  Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }

  /// Dispose resources
  Future<void> dispose() async {
    await stopRecording();
    _recorder.dispose();
  }

  /// Convert PCM16 to Float32 (normalized to -1.0 to 1.0)
  Float32List _convertPcm16ToFloat32(Uint8List pcm16Data) {
    final int16Data = Int16List.view(pcm16Data.buffer);
    final float32Data = Float32List(int16Data.length);

    for (int i = 0; i < int16Data.length; i++) {
      float32Data[i] = int16Data[i] / 32768.0; // Normalize to -1.0 to 1.0
    }

    return float32Data;
  }
}
