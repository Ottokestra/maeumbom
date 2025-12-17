import '../../ui/characters/app_characters.dart';

/// 감정 코드 매핑 유틸리티
/// 백엔드 API의 감정 코드(영문)를 프론트엔드 EmotionId enum으로 변환
class EmotionMapper {
  /// 감정 코드(영문)를 EmotionId로 변환
  /// 
  /// 백엔드 API에서 제공하는 17개 감정 코드:
  /// - 긍정: joy, excitement, confidence, love, relief, enlightenment, interest
  /// - 부정: discontent, shame, sadness, guilt, depression, boredom, contempt, anger, fear, confusion
  static EmotionId? fromCode(String code) {
    switch (code.toLowerCase()) {
      // 긍정 감정
      case 'joy':
        return EmotionId.joy;
      case 'excitement':
        return EmotionId.excitement;
      case 'confidence':
        return EmotionId.confidence;
      case 'love':
        return EmotionId.love;
      case 'relief':
        return EmotionId.relief;
      case 'enlightenment':
        return EmotionId.enlightenment;
      case 'interest':
        return EmotionId.interest;

      // 부정 감정
      case 'discontent':
        return EmotionId.discontent;
      case 'shame':
        return EmotionId.shame;
      case 'sadness':
        return EmotionId.sadness;
      case 'guilt':
        return EmotionId.guilt;
      case 'depression':
        return EmotionId.depression;
      case 'boredom':
        return EmotionId.boredom;
      case 'contempt':
        return EmotionId.contempt;
      case 'anger':
        return EmotionId.anger;
      case 'fear':
        return EmotionId.fear;
      case 'confusion':
        return EmotionId.confusion;

      default:
        return null;
    }
  }

  /// 감정 코드(영문)를 한글 이름으로 변환
  static String? toKoreanName(String code) {
    final emotionId = fromCode(code);
    if (emotionId == null) return null;
    
    final meta = emotionMetaMap[emotionId];
    return meta?.nameKo;
  }

  /// EmotionId를 감정 코드(영문)로 변환
  static String? toCode(EmotionId emotionId) {
    final meta = emotionMetaMap[emotionId];
    return meta?.nameEn;
  }
}

