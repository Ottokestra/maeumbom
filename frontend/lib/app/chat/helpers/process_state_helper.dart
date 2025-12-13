import '../../../ui/components/process_indicator.dart';
import '../../../providers/chat_provider.dart';

/// Process 상태 결정 헬퍼
///
/// ProcessIndicator의 모드와 단계를 결정합니다.
class ProcessStateHelper {
  /// Process 모드 결정 (음성/텍스트)
  static ProcessMode determineMode({
    required bool showInputBar,
    required bool isLoading,
    required VoiceInterfaceState voiceState,
  }) {
    if (showInputBar || (isLoading && voiceState == VoiceInterfaceState.idle)) {
      return ProcessMode.text;
    }
    return ProcessMode.voice;
  }

  /// Process 단계 결정
  static ProcessStep determineStep({
    required ProcessMode mode,
    required VoiceInterfaceState voiceState,
    required bool isLoading,
    required bool showTextCompletion,
    required bool hasRecentMessage,
  }) {
    if (mode == ProcessMode.voice) {
      return _determineVoiceStep(voiceState, hasRecentMessage);
    } else {
      return _determineTextStep(isLoading, showTextCompletion);
    }
  }

  /// 음성 모드 단계 결정
  static ProcessStep _determineVoiceStep(
    VoiceInterfaceState voiceState,
    bool hasRecentMessage,
  ) {
    switch (voiceState) {
      case VoiceInterfaceState.loading:
        return ProcessStep.preparation; // Backend 로딩 중

      case VoiceInterfaceState.idle:
        return ProcessStep.standby;

      case VoiceInterfaceState.listening:
        return ProcessStep.input;

      case VoiceInterfaceState.processingVoice: // 🆕 음성 처리 중 (STT)
        return ProcessStep.analysis;

      case VoiceInterfaceState.processing:
        return ProcessStep.analysis;

      case VoiceInterfaceState.replying:
        return ProcessStep.completion;
    }
  }

  /// 텍스트 모드 단계 결정
  static ProcessStep _determineTextStep(
    bool isLoading,
    bool showTextCompletion,
  ) {
    if (isLoading) {
      return ProcessStep.analysis;
    } else if (showTextCompletion) {
      return ProcessStep.completion;
    } else {
      return ProcessStep.standby;
    }
  }
}
