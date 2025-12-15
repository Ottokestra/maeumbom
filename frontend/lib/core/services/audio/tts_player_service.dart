import 'dart:async';
import 'dart:io';
import 'dart:typed_data'; // 🆕 For Uint8List
import 'package:audioplayers/audioplayers.dart';
import '../../utils/logger.dart';

/// TTS Player Service
/// Handles audio playback for TTS (Text-to-Speech) responses.
/// Uses [AudioPlayer] from `audioplayers` package.
class TtsPlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Completer<void>? _playbackCompleter; // 🆕 재생 완료 추적

  /// Constructor
  TtsPlayerService() {
    _initAudioPlayer();
  }

  /// Initialize AudioPlayer with listeners
  void _initAudioPlayer() async {
    // 🆕 오디오 포커스 설정: TTS 재생 시 다른 오디오 중단
    await _audioPlayer.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {
            AVAudioSessionOptions.mixWithOthers,
            AVAudioSessionOptions.duckOthers,
          },
        ),
        android: AudioContextAndroid(
          isSpeakerphoneOn: true, // 🆕 스피커폰 강제 사용
          stayAwake: false,
          contentType: AndroidContentType.speech,
          usageType: AndroidUsageType.assistanceSonification,
          audioFocus: AndroidAudioFocus.gain, // 🔑 GAIN으로 변경 (가장 강력한 포커스)
        ),
      ),
    );

    _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      appLogger.d('[TtsPlayerService] Player state changed: $state');
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      _isPlaying = false;
      appLogger.d('[TtsPlayerService] Playback completed');
      // 🆕 재생 완료 시 Completer 완료
      _playbackCompleter?.complete();
      _playbackCompleter = null;
    });
  }

  /// Play audio from local file path or URL
  /// Returns a Future that completes when playback finishes
  Future<void> play(String source) async {
    try {
      if (_isPlaying) {
        await stop();
      }

      appLogger.i('[TtsPlayerService] Playing TTS from: $source');

      // 🆕 재생 완료 추적을 위한 Completer 생성
      _playbackCompleter = Completer<void>();

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
          // Try DeviceFileSource anyway just in case it's a weird path string,
          // but likely will fail.
          await _audioPlayer.play(DeviceFileSource(source));
        }
      }

      // 🆕 재생 완료를 기다림 (onPlayerComplete에서 complete됨)
      await _playbackCompleter?.future;
    } catch (e) {
      appLogger.e('[TtsPlayerService] Playback failed: $e');
      // 🆕 에러 발생 시에도 Completer 완료
      _playbackCompleter?.complete();
      _playbackCompleter = null;
      rethrow;
    }
  }

  /// 🆕 Play audio from Uint8List bytes (for base64 audio)
  Future<void> playBytes(Uint8List bytes, String mimeType) async {
    try {
      if (_isPlaying) {
        await stop();
      }

      appLogger.i(
          '[TtsPlayerService] Playing TTS from bytes (${bytes.length} bytes, $mimeType)');

      // 재생 완료 추적을 위한 Completer 생성
      _playbackCompleter = Completer<void>();

      // BytesSource로 재생
      await _audioPlayer.play(BytesSource(bytes));

      // 재생 완료를 기다림
      await _playbackCompleter?.future;
    } catch (e) {
      appLogger.e('[TtsPlayerService] Bytes playback failed: $e');
      _playbackCompleter?.complete();
      _playbackCompleter = null;
      rethrow;
    }
  }

  /// Stop playback
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
      // 🆕 중지 시 Completer 완료
      _playbackCompleter?.complete();
      _playbackCompleter = null;
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
