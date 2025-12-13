import 'package:flutter/material.dart';
import '../characters/app_characters.dart';
import '../characters/app_character_colors.dart';
import '../tokens/colors.dart';

/// Tag Badge - 태그 배지 컴포넌트
///
/// 카테고리, 타입 등을 표시하는 작은 배지
/// 감정 캐릭터 색상을 기반으로 랜덤 컬러 매칭
///
/// 사용 예시:
/// ```dart
/// TagBadge(text: '친구')
/// TagBadge(text: '훈련', emotionId: EmotionId.joy)
/// TagBadge(text: '훈련', customColor: AppColors.secondaryColor)
/// TagBadge(text: '훈련', customBackgroundColor: Color(0xFFF4E6E4), customTextColor: Color(0xFFD7454D))
/// ```
class TagBadge extends StatelessWidget {
  /// 배지에 표시될 텍스트
  final String text;

  /// 감정 ID (색상 결정용, null이면 텍스트 기반 자동 선택)
  final EmotionId? emotionId;

  /// 커스텀 색상 (지정하면 감정 색상 대신 사용, 텍스트는 흰색)
  final Color? customColor;

  /// 커스텀 배경 색상 (customTextColor와 함께 사용)
  final Color? customBackgroundColor;

  /// 커스텀 텍스트 색상 (customBackgroundColor와 함께 사용)
  final Color? customTextColor;

  const TagBadge({
    super.key,
    required this.text,
    this.emotionId,
    this.customColor,
    this.customBackgroundColor,
    this.customTextColor,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    // 1순위: 커스텀 배경+텍스트 색상
    if (customBackgroundColor != null) {
      backgroundColor = customBackgroundColor!;
      textColor = customTextColor ?? Colors.white;
    }
    // 2순위: 커스텀 단색 (흰색 텍스트)
    else if (customColor != null) {
      backgroundColor = customColor!;
      textColor = Colors.white;
    }
    // 3순위: 감정 색상 (연한 배경 + 진한 텍스트)
    else {
      final emotion = emotionId ?? _getEmotionFromText(text);
      final colors = getEmotionColors(emotion);
      // 연한 배경: secondary 색상의 20% 투명도
      backgroundColor = colors.secondary.withOpacity(0.2);
      // 진한 텍스트: primary 색상
      textColor = colors.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16777200), // 매우 큰 값으로 완전 둥근 모서리
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w600,
          height: 1.33,
        ),
      ),
    );
  }

  /// 텍스트 기반으로 감정 ID 선택 (일관성 있게)
  EmotionId _getEmotionFromText(String text) {
    // 텍스트의 해시코드를 사용하여 일관된 색상 선택
    final hash = text.hashCode.abs();
    final emotions = EmotionId.values;
    return emotions[hash % emotions.length];
  }
}

/// Tag Badge Row - 여러 배지를 가로로 나열
///
/// 사용 예시:
/// ```dart
/// TagBadgeRow(tags: ['친구', '훈련'])
/// TagBadgeRow(
///   tags: ['배우자', '드라마'],
///   emotionMap: {'배우자': EmotionId.love, '드라마': EmotionId.excitement},
/// )
/// TagBadgeRow(
///   tags: ['훈련', '친구'],
///   colorMap: {'훈련': AppColors.secondaryColor},
/// )
/// TagBadgeRow(
///   tags: ['훈련', '친구'],
///   backgroundColorMap: {'훈련': Color(0xFFF4E6E4)},
///   textColorMap: {'훈련': Color(0xFFD7454D)},
/// )
/// ```
class TagBadgeRow extends StatelessWidget {
  /// 배지 텍스트 목록
  final List<String> tags;

  /// 태그별 감정 ID 매핑 (선택사항)
  final Map<String, EmotionId>? emotionMap;

  /// 태그별 커스텀 색상 매핑 (선택사항, emotionMap보다 우선)
  final Map<String, Color>? colorMap;

  /// 태그별 커스텀 배경 색상 매핑 (선택사항, colorMap보다 우선)
  final Map<String, Color>? backgroundColorMap;

  /// 태그별 커스텀 텍스트 색상 매핑 (선택사항, backgroundColorMap과 함께 사용)
  final Map<String, Color>? textColorMap;

  /// 배지 간 간격
  final double spacing;

  const TagBadgeRow({
    super.key,
    required this.tags,
    this.emotionMap,
    this.colorMap,
    this.backgroundColorMap,
    this.textColorMap,
    this.spacing = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: tags.map((tag) {
        return TagBadge(
          text: tag,
          customBackgroundColor: backgroundColorMap?[tag],
          customTextColor: textColorMap?[tag],
          customColor: colorMap?[tag],
          emotionId: emotionMap?[tag],
        );
      }).toList(),
    );
  }
}

