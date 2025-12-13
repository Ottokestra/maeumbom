import '../../../providers/chat_provider.dart';

/// 상태 메시지 헬퍼
///
/// 현재 대화 상태에 따라 사용자에게 표시할 상태 메시지를 결정합니다.
class StatusMessageHelper {
  /// 현재 상태에 따른 사용자 메시지 반환
  ///
  /// 반환값이 null이면 상태 메시지를 표시하지 않고 일반 답변을 표시합니다.
  static String? getStatusMessage({
    required VoiceInterfaceState voiceState,
    required bool isLoading,
  }) {
    // 1. 음성 입력 중 (듣고 있음)
    if (voiceState == VoiceInterfaceState.listening) {
      return '편하게 말해봐~ 나 다 듣고 있어!';
    }

    // // 2. 음성 처리 중 (STT) - 발화 종료 감지 후
    // if (voiceState == VoiceInterfaceState.processingVoice) {
    //   return '나 목소리를 듣고 있어!';
    // }

    // 3. AI 생각 중 (Agent 처리 중)
    if (voiceState == VoiceInterfaceState.processing || isLoading) {
      return '음.. 생각해볼게. 잠시만 기다려줘!';
    }

    // 4. 상태 메시지 없음 (일반 답변 표시)
    return null;
  }
}
