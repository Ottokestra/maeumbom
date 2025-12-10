import '../../../providers/chat_provider.dart';
import '../../../data/models/chat/chat_message.dart';

/// 애니메이션 상태 결정 헬퍼
///
/// 현재 대화 상태에 따라 캐릭터 애니메이션 상태를 결정합니다.
class AnimationStateHelper {
  /// 현재 대화 상태에 따라 애니메이션 상태를 결정
  static String determineState({
    required VoiceInterfaceState voiceState,
    required bool isLoading,
    required String? error,
    required List<ChatMessage> messages,
  }) {
    // 1. 에러 상태 체크
    if (error != null && error.isNotEmpty) {
      return 'error';
    }

    // 2. Backend 로딩 중 (모델 초기화)
    if (voiceState == VoiceInterfaceState.loading) {
      return 'thinking';
    }

    // 3. 음성 입력 중 (듣고 있음)
    if (voiceState == VoiceInterfaceState.listening) {
      return 'listening';
    }

    // 4. 분석 중 (생각 중) - STT 결과 받은 후 AI가 생각하는 중
    if (voiceState == VoiceInterfaceState.processing || isLoading) {
      return 'thinking';
    }

    // 5. 답변 중 (깨달음 → 감정 표현)
    if (voiceState == VoiceInterfaceState.replying) {
      return _getEmotionFromLatestMessage(messages);
    }

    // 6. 답변 완료 후 idle 상태 - 최신 메시지의 감정 유지
    if (voiceState == VoiceInterfaceState.idle) {
      final emotion = _getEmotionFromLatestMessage(messages);
      if (emotion != 'happiness') {
        // 기본값이 아닌 감정이 있으면 유지
        return emotion;
      }
    }

    // 7. 기본 상태 (최초 진입, 대기 중)
    return 'basic';
  }

  /// 최신 봇 메시지에서 감정 추출
  static String _getEmotionFromLatestMessage(List<ChatMessage> messages) {
    final latestBotMessage = messages.where((msg) => !msg.isUser).lastOrNull;

    if (latestBotMessage != null && latestBotMessage.meta != null) {
      final emotion = latestBotMessage.meta!['emotion'] as String?;
      if (emotion != null) {
        return emotion; // 'happiness', 'sadness', 'anger', 'fear' 등
      }
    }

    return 'happiness'; // 기본값
  }
}
