import 'package:flutter/material.dart';
import 'package:frontend/ui/tokens/colors.dart';
import 'package:frontend/ui/characters/app_characters.dart';

/// 감정 캐릭터별 컬러 정보
class EmotionColorPair {
  final Color primary;
  final Color secondary;

  const EmotionColorPair({
    required this.primary,
    required this.secondary,
  });
}

/// 감정 ID별 컬러 매핑
///
/// 사용 예시:
/// ```dart
/// final colors = emotionColorMap[EmotionId.joy]!;
/// Container(
///   decoration: BoxDecoration(
///     gradient: LinearGradient(
///       colors: [colors.primary, colors.secondary],
///     ),
///   ),
/// )
/// ```
const Map<EmotionId, EmotionColorPair> emotionColorMap = {
  // ✅ 긍정 감정

  // 기쁨 - 해바라기 (노란색 계열)
  EmotionId.joy: EmotionColorPair(
    primary: AppColors.emotionHappinessPrimary, // #FFB84C
    secondary: AppColors.emotionHappinessSecondary, // #FFD749
  ),

  // 흥분 - 별 (주황색 계열)
  EmotionId.excitement: EmotionColorPair(
    primary: Color(0xFFFF9800), // Orange
    secondary: Color(0xFFFFB74D),
  ),

  // 자신감 - 사자 (골드 계열)
  EmotionId.confidence: EmotionColorPair(
    primary: Color(0xFFFFC107), // Gold
    secondary: Color(0xFFFFD54F),
  ),

  // 사랑 - 펭귄 (핑크 계열)
  EmotionId.love: EmotionColorPair(
    primary: AppColors.emotionLovePrimary, // #FF6FAE
    secondary: AppColors.emotionLoveSecondary, // #FF8EC3
  ),

  // 안심 - 사슴 (민트/하늘색 계열)
  EmotionId.relief: EmotionColorPair(
    primary: AppColors.emotionStabilityPrimary, // #76D6FF
    secondary: AppColors.emotionStabilitySecondary, // #A1E8FF
  ),

  // 깨달음 - 전구 (밝은 파란색 계열)
  EmotionId.enlightenment: EmotionColorPair(
    primary: Color(0xFF4FC3F7), // LightBlue
    secondary: Color(0xFF81D4FA),
  ),

  // 흥미 - 부엉이 (보라색 계열)
  EmotionId.interest: EmotionColorPair(
    primary: Color(0xFFAB47BC), // Purple
    secondary: Color(0xFFBA68C8),
  ),

  // ❌ 부정 감정

  // 불만 - 당근 (갈색 계열)
  EmotionId.discontent: EmotionColorPair(
    primary: Color(0xFF8D6E63), // Brown
    secondary: Color(0xFFA1887F),
  ),

  // 수치 - 복숭아 (복숭아 핑크 계열)
  EmotionId.shame: EmotionColorPair(
    primary: Color(0xFFFFAB91), // PeachPink
    secondary: Color(0xFFFFCCBC),
  ),

  // 슬픔 - 고래 (진한 파란색 계열)
  EmotionId.sadness: EmotionColorPair(
    primary: Color(0xFF5C6BC0), // DeepBlue
    secondary: Color(0xFF7986CB),
  ),

  // 죄책감 - 곰 (어두운 갈색 계열)
  EmotionId.guilt: EmotionColorPair(
    primary: Color(0xFF6D4C41), // DarkBrown
    secondary: Color(0xFF8D6E63),
  ),

  // 우울 - 돌 (회색 계열)
  EmotionId.depression: EmotionColorPair(
    primary: AppColors.emotionWorryPrimary, // #6C8CD5
    secondary: AppColors.emotionWorrySecondary, // #8AA7E2
  ),

  // 무료 - 나무늘보 (연한 회색 계열)
  EmotionId.boredom: EmotionColorPair(
    primary: Color(0xFFB0BEC5), // LightGray
    secondary: Color(0xFFCFD8DC),
  ),

  // 경멸 - 가지 (보라색 계열)
  EmotionId.contempt: EmotionColorPair(
    primary: Color(0xFF7E57C2), // Purple
    secondary: Color(0xFF9575CD),
  ),

  // 화 - 불 (빨간색 계열)
  EmotionId.anger: EmotionColorPair(
    primary: AppColors.emotionAngerPrimary, // #FF5E4A
    secondary: AppColors.emotionAngerSecondary, // #FF7A5C
  ),

  // 공포 - 쥐 (어두운 회색 계열)
  EmotionId.fear: EmotionColorPair(
    primary: Color(0xFF546E7A), // DarkGray
    secondary: Color(0xFF78909C),
  ),

  // 혼란 - 로봇 (실버/보라 계열)
  EmotionId.confusion: EmotionColorPair(
    primary: AppColors.emotionConfusionPrimary, // #B28CFF
    secondary: AppColors.emotionConfusionSecondary, // #C7A4FF
  ),
};

/// EmotionCharacter 위젯에 컬러 옵션을 추가한 확장 위젯
class EmotionCharacterWithColor extends StatelessWidget {
  final EmotionId id;
  final bool use2d;
  final double size;
  final bool showColorBackground;
  final double backgroundOpacity;

  const EmotionCharacterWithColor({
    super.key,
    required this.id,
    this.use2d = false,
    this.size = 120,
    this.showColorBackground = false,
    this.backgroundOpacity = 0.1,
  });

  @override
  Widget build(BuildContext context) {
    final colors = emotionColorMap[id]!;

    if (!showColorBackground) {
      return EmotionCharacter(
        id: id,
        use2d: use2d,
        size: size,
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withOpacity(backgroundOpacity),
            colors.secondary.withOpacity(backgroundOpacity),
          ],
        ),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: EmotionCharacter(
        id: id,
        use2d: use2d,
        size: size,
      ),
    );
  }
}

/// 감정별 컬러를 가져오는 헬퍼 함수
EmotionColorPair getEmotionColors(EmotionId id) {
  return emotionColorMap[id] ?? emotionColorMap[EmotionId.relief]!;
}

/// 감정별 Primary 컬러만 가져오는 헬퍼 함수
Color getEmotionPrimaryColor(EmotionId id) {
  return emotionColorMap[id]?.primary ??
      emotionColorMap[EmotionId.relief]!.primary;
}

/// 감정별 Secondary 컬러만 가져오는 헬퍼 함수
Color getEmotionSecondaryColor(EmotionId id) {
  return emotionColorMap[id]?.secondary ??
      emotionColorMap[EmotionId.relief]!.secondary;
}
