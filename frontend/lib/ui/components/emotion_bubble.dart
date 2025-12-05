import 'package:flutter/material.dart';
import 'package:frontend/ui/tokens/app_tokens.dart';
import 'package:frontend/ui/characters/app_characters.dart';

/// 감정 캐릭터와 메시지를 함께 표시하는 말풍선 위젯
///
/// 감정 캐릭터 아이콘과 짧은 메시지를 함께 표시합니다.
/// 감정 추천, 감정 히스토리 등에 사용합니다.
///
/// 사용 예시:
/// ```dart
/// // 감정 추천
/// EmotionBubble(
///   emotion: EmotionId.joy,
///   message: '기분 좋은 하루네요!',
///   onTap: () => _showEmotionDetail(EmotionId.joy),
/// )
///
/// // 감정 히스토리
/// EmotionBubble(
///   emotion: EmotionId.sadness,
///   message: '어제는 조금 슬펐어요',
/// )
/// ```
class EmotionBubble extends StatelessWidget {
  /// 표시할 감정 ID
  final EmotionId emotion;

  /// 표시할 메시지
  final String message;

  /// 탭 콜백
  final VoidCallback? onTap;

  const EmotionBubble({
    super.key,
    required this.emotion,
    required this.message,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: BubbleTokens.emotionPadding,
        decoration: BoxDecoration(
          color: BubbleTokens.emotionBg,
          border: Border.all(
            color: BubbleTokens.emotionBorder,
            width: BubbleTokens.borderWidth,
          ),
          borderRadius: BorderRadius.circular(BubbleTokens.emotionRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 감정 캐릭터 아이콘
            EmotionCharacter(
              id: emotion,
              size: 32,
              highRes: false,
            ),
            SizedBox(width: AppSpacing.xs),
            // 메시지 텍스트
            Flexible(
              child: Text(
                message,
                style: AppTypography.body.copyWith(
                  color: BubbleTokens.emotionText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
