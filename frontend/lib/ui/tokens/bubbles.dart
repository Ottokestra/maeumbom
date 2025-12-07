import 'package:flutter/material.dart';
import 'app_tokens.dart';

/// Bubble Tokens - 말풍선 관련 디자인 토큰
///
/// 채팅 말풍선, 시스템 말풍선, 감정 말풍선에 사용되는 스타일 정의
class BubbleTokens {
  BubbleTokens._();

  // ============================================================
  // Chat Bubble (ChatBubble)
  // ============================================================

  /// 채팅 말풍선 패딩
  static const EdgeInsets chatPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.sm,
    vertical: 12,
  );

  /// 채팅 말풍선 반경
  static const double chatRadius = AppRadius.lg;

  /// 말풍선 간 간격
  static const double bubbleSpacing = AppSpacing.sm;

  /// 말풍선 최대 너비 비율 (화면 너비 대비)
  static const double maxWidthRatio = 0.85;

  /// 사용자 말풍선 배경색
  static const Color userBg = AppColors.accentRed;

  /// 사용자 말풍선 텍스트 색상
  static const Color userText = AppColors.textWhite;

  /// 봄이 말풍선 배경색
  static const Color botBg = AppColors.pureWhite;

  /// 봄이 말풍선 텍스트 색상
  static const Color botText = AppColors.textPrimary;

  /// 봄이 말풍선 테두리 색상
  static const Color botBorder = AppColors.borderLight;

  /// 말풍선 테두리 두께
  static const double borderWidth = 1.0;

  // ============================================================
  // System Bubble (SystemBubble)
  // ============================================================

  /// 시스템 말풍선 패딩
  static const EdgeInsets systemPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.sm,
    vertical: AppSpacing.xs,
  );

  /// 시스템 말풍선 반경
  static const double systemRadius = AppRadius.pill;

  /// 시스템 말풍선 텍스트 색상
  static const Color systemText = AppColors.textSecondary;

  /// 시스템 말풍선 배경색 (info)
  static const Color systemBgInfo = AppColors.warmWhite;

  /// 시스템 말풍선 배경색 (success)
  static const Color systemBgSuccess = AppColors.bgSoftMint;

  /// 시스템 말풍선 배경색 (warning)
  static const Color systemBgWarning = AppColors.bgLightPink;

  // ============================================================
  // Emotion Bubble (EmotionBubble)
  // ============================================================

  /// 감정 말풍선 패딩
  static const EdgeInsets emotionPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.sm,
    vertical: AppSpacing.xs,
  );

  /// 감정 말풍선 반경
  static const double emotionRadius = AppRadius.md;

  /// 감정 말풍선 배경색
  static const Color emotionBg = AppColors.bgLightPink;

  /// 감정 말풍선 테두리 색상
  static const Color emotionBorder = AppColors.borderLight;

  /// 감정 말풍선 텍스트 색상
  static const Color emotionText = AppColors.textPrimary;
}
