import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

/// Audio Recorder Service (record 패키지 - Int16 직접 녹음)
/// PCM16/Mono/16kHz - Int16 데이터를 직접 4096-sample chunks로 전송
class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  StreamController<Int16List>? _chunkController; // ✅ Float32 → Int16로 변경
  StreamSubscription<Uint8List>? _recordSubscription;

  bool _isRecording = false;

  /// 녹음 시작
  /// Returns: 4096-sample Int16List chunks stream
  Future<Stream<Int16List>> startRecording() async {
    if (_isRecording) {
      throw Exception('이미 녹음 중입니다');
    }

    debugPrint('[AudioRecorderService] 녹음 시작 (Int16 직접 전송)');

    _chunkController = StreamController<Int16List>();

    // ✅ 에뮬레이터 호환 최소 설정 (가장 단순한 포맷)
    final config = RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 16000,
      numChannels: 1,
      // bitRate 제거 - PCM에서는 불필요
      autoGain: false, // 자동 게인 끄기
      echoCancel: false, // 에코 캔슬 끄기
      noiseSuppress: false, // 노이즈 억제 끄기 (가공 최소화)
    );

    // 녹음 시작 및 스트림 수신
    final stream = await _recorder.startStream(config);

    // PCM16 → Int16 chunks (Float32 변환 제거)
    _processInt16Chunks(stream);

    _isRecording = true;
    return _chunkController!.stream;
  }

  /// PCM16 데이터를 4096-sample Int16 chunks로 처리
  void _processInt16Chunks(Stream<Uint8List> pcm16Stream) {
    final List<int> buffer = []; // Int16 값 저장

    _recordSubscription = pcm16Stream.listen((data) {
      if (data.isEmpty) return;

      // ✅ 테스트: Big Endian으로 읽기
      final byteData = ByteData.view(data.buffer);

      for (int i = 0; i < data.length; i += 2) {
        if (i + 1 < data.length) {
          final sample = byteData.getInt16(i, Endian.big); // ★ Big Endian 테스트
          buffer.add(sample);

          // 4096-sample 청크 생성 (256ms @ 16kHz)
          if (buffer.length >= 4096) {
            final chunk = Int16List.fromList(buffer.sublist(0, 4096));
            _chunkController?.add(chunk);
            buffer.removeRange(0, 4096);
          }
        }
      }
    });
  }

  /// 녹음 중지
  Future<void> stopRecording() async {
    if (!_isRecording) return;

    debugPrint('[AudioRecorderService] 녹음 중지');

    await _recorder.stop();
    await _recordSubscription?.cancel();
    await _chunkController?.close();

    _chunkController = null;
    _recordSubscription = null;
    _isRecording = false;
  }

  /// 녹음 일시 중지
  Future<void> pauseRecording() async {
    if (!_isRecording) return;

    debugPrint('[AudioRecorderService] 녹음 일시 중지');
    await _recorder.pause();
  }

  /// 녹음 재개
  Future<void> resumeRecording() async {
    if (!_isRecording) {
      debugPrint('[AudioRecorderService] ⚠️ 녹음이 시작되지 않았습니다');
      return;
    }

    debugPrint('[AudioRecorderService] 녹음 재개');
    await _recorder.resume();
  }

  /// 정리
  Future<void> dispose() async {
    await stopRecording();
    await _recorder.dispose();
    debugPrint('[AudioRecorderService] 정리 완료');
  }

  /// 현재 녹음 상태
  bool get isRecording => _isRecording;
}
