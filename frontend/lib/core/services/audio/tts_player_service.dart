import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import '../../utils/logger.dart';

/// TTS Player Service
/// Handles audio playback for TTS (Text-to-Speech) responses.
/// Uses [AudioPlayer] from `audioplayers` package.
class TtsPlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  /// Constructor
  TtsPlayerService() {
    _initAudioPlayer();
  }

  /// Initialize AudioPlayer with listeners
  void _initAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      appLogger.d('[TtsPlayerService] Player state changed: $state');
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      _isPlaying = false;
      appLogger.d('[TtsPlayerService] Playback completed');
    });
  }

  /// Play audio from local file path or URL
  Future<void> play(String source) async {
    try {
      if (_isPlaying) {
        await stop();
      }

      appLogger.i('[TtsPlayerService] Playing TTS from: $source');

      if (_isUrl(source)) {
        await _audioPlayer.play(UrlSource(source));
      } else {
        // Assume local file path
        if (await File(source).exists()) {
           // For local files, we use DeviceFileSource
           await _audioPlayer.play(DeviceFileSource(source));
        } else {
           // Fallback or error if file doesn't exist
           appLogger.w('[TtsPlayerService] Local file does not exist: $source');
           // Try UrlSource anyway just in case it's a weird path string, 
           // but likely will fail.
           await _audioPlayer.play(DeviceFileSource(source)); 
        }
      }
    } catch (e) {
      appLogger.e('[TtsPlayerService] Playback failed: $e');
    }
  }

  /// Stop playback
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
    } catch (e) {
      appLogger.e('[TtsPlayerService] Stop failed: $e');
    }
  }

  /// Check if source looks like a URL
  bool _isUrl(String source) {
    return source.startsWith('http://') || source.startsWith('https://');
  }

  /// Dispose
  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
