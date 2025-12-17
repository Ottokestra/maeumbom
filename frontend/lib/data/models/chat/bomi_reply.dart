/// 봄이의 Quick Reply 응답 모델
/// 
/// 단순 스몰톡에 대한 즉각적인 응답을 위한 데이터 모델입니다.
/// 서버 응답과 동일한 JSON 구조로 변환 가능합니다.
class BoomiReply {
  /// 응답 텍스트 (반말)
  final String text;
  
  /// 감정 ID (app_animations.dart EmotionCategory 기준)
  /// - happiness: 행복/기쁨
  /// - sadness: 슬픔
  /// - anger: 분노
  /// - fear: 공포/두려움
  final String emotion;
  
  const BoomiReply({
    required this.text,
    required this.emotion,
  });
  
  /// 서버 응답 JSON 포맷으로 변환
  /// 
  /// Quick Reply는 response_type이 "quick"으로 설정되며,
  /// alarm_info와 TTS 관련 필드는 null/skip으로 설정됩니다.
  Map<String, dynamic> toServerFormat() {
    return {
      'reply_text': text,
      'emotion': emotion,
      'response_type': 'quick',
      'alarm_info': null,
      'tts_audio_url': null,
      'tts_status': 'skip',
    };
  }
}
