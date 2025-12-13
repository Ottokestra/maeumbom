import 'package:flutter/material.dart';
import '../../ui/tokens/app_tokens.dart';
import '../../ui/characters/app_characters.dart';
import 'emotion_classifier.dart';

/// 감정(Emotion)과 기분(Mood) 기반 색상 관리 헬퍼
///
/// PROMPT_GUIDE.md의 컬러 규칙에 따라 일관된 색상을 제공합니다.
/// - 감정(EmotionId)은 좋음/보통/나쁨(MoodCategory)으로 분류
/// - Home 배경, 게이지, 버튼 등의 색상을 통합 관리
class MoodColorHelper {
  /// 기분 카테고리에 따른 홈 배경색 반환
  ///
  /// PROMPT_GUIDE.md 106-109줄 규칙:
  /// - 좋음: homeGoodYellow
  /// - 보통: homeNormalGreen
  /// - 나쁨: homeBadBlue
  static Color getBackgroundColor(MoodCategory category) {
    switch (category) {
      case MoodCategory.good:
        return AppColors.homeGoodYellow;
      case MoodCategory.neutral:
        return AppColors.homeNormalGreen;
      case MoodCategory.bad:
        return AppColors.homeBadBlue;
    }
  }

  /// 기분 카테고리에 따른 포인트 색상 (버튼, 강조 요소)
  static Color getBorderColor(MoodCategory category) {
    switch (category) {
      case MoodCategory.good:
        return AppColors.homeGoodYellow;
      case MoodCategory.neutral:
        return AppColors.homeNormalGreen;
      case MoodCategory.bad:
        return AppColors.homeBadBlue;
    }
  }

  /// 기분 카테고리에 따른 텍스트 색상
  ///
  /// 모든 배경이 밝은 계열이므로 가독성을 위해 통일된 텍스트 색상 사용
  static Color getContentColor(MoodCategory category) {
    // 모든 배경에서 흰색 텍스트 사용 (배경이 밝은 파스텔 톤)
    return AppColors.textWhite;
  }

  /// 감정 ID에 따른 메인 색상 반환 (게이지, 배지용)
  ///
  /// Emotion Color Primary 컬러 반환
  static Color getEmotionColor(EmotionId emotion) {
    switch (emotion) {
      case EmotionId.joy:
        return AppColors.emotionHappinessPrimary;
      case EmotionId.love:
        return AppColors.emotionLovePrimary;
      case EmotionId.relief:
        return AppColors.emotionStabilityPrimary;
      case EmotionId.excitement:
        return AppColors.emotionMotivationPrimary;
      case EmotionId.anger:
        return AppColors.emotionAngerPrimary;
      case EmotionId.fear:
        return AppColors.emotionWorryPrimary;
      case EmotionId.sadness:
        return AppColors.emotionWorryPrimary;
      case EmotionId.boredom:
        return AppColors.emotionConfusionPrimary;
      default:
        return AppColors.primaryColor;
    }
  }

  /// 감정 ID에서 직접 배경색을 가져오는 편의 메서드
  static Color getBackgroundColorFromEmotion(EmotionId emotion) {
    final category = EmotionClassifier.classify(emotion);
    return getBackgroundColor(category);
  }

  /// 감정 ID에서 직접 포인트 색상을 가져오는 편의 메서드
  static Color getBorderColorFromEmotion(EmotionId emotion) {
    final category = EmotionClassifier.classify(emotion);
    return getBorderColor(category);
  }

  /// 감정 ID에서 직접 텍스트 색상을 가져오는 편의 메서드
  static Color getContentColorFromEmotion(EmotionId emotion) {
    final category = EmotionClassifier.classify(emotion);
    return getContentColor(category);
  }
}
