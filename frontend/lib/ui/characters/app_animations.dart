import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// 감정군 및 상태 카테고리
enum EmotionCategory {
  // 4가지 감정
  happiness,
  sadness,
  anger,
  fear,
  // 5가지 상태
  basic,
  listening,
  thinking,
  realization,
  error,
}

/// 애니메이션 캐릭터 메타정보
class AnimationMeta {
  final String id; // 캐릭터 고유 ID (예: 'relief', 'joy' 등)
  final String nameKo; // 한글 이름
  final EmotionCategory category; // 감정군
  final String assetPath; // Lottie JSON 파일 경로

  const AnimationMeta({
    required this.id,
    required this.nameKo,
    required this.category,
    required this.assetPath,
  });
}

/// 애니메이션 캐릭터 데이터 맵
/// relief 캐릭터의 4가지 감정 + 5가지 상태 애니메이션
/// 향후 다른 캐릭터 추가 시 '{characterId}_{emotion}' 패턴으로 추가
const Map<String, AnimationMeta> animationMetaMap = {
  // relief 캐릭터 - 4가지 감정
  'relief_happiness': AnimationMeta(
    id: 'relief_happiness',
    nameKo: '안심(기쁨)',
    category: EmotionCategory.happiness,
    assetPath: 'assets/characters/animation/happiness/char_relief.json',
  ),
  'relief_sadness': AnimationMeta(
    id: 'relief_sadness',
    nameKo: '안심(슬픔)',
    category: EmotionCategory.sadness,
    assetPath: 'assets/characters/animation/sadness/char_relief.json',
  ),
  'relief_anger': AnimationMeta(
    id: 'relief_anger',
    nameKo: '안심(분노)',
    category: EmotionCategory.anger,
    assetPath: 'assets/characters/animation/anger/char_relief.json',
  ),
  'relief_fear': AnimationMeta(
    id: 'relief_fear',
    nameKo: '안심(공포)',
    category: EmotionCategory.fear,
    assetPath: 'assets/characters/animation/fear/char_relief.json',
  ),

  // relief 캐릭터 - 5가지 상태
  'relief_basic': AnimationMeta(
    id: 'relief_basic',
    nameKo: '안심(기본)',
    category: EmotionCategory.basic,
    assetPath: 'assets/characters/animation/basic/char_relief.json',
  ),
  'relief_listening': AnimationMeta(
    id: 'relief_listening',
    nameKo: '안심(듣는중)',
    category: EmotionCategory.listening,
    assetPath: 'assets/characters/animation/listening/char_relief.json',
  ),
  'relief_thinking': AnimationMeta(
    id: 'relief_thinking',
    nameKo: '안심(생각중)',
    category: EmotionCategory.thinking,
    assetPath: 'assets/characters/animation/thinking/char_relief.json',
  ),
  'relief_realization': AnimationMeta(
    id: 'relief_realization',
    nameKo: '안심(깨달음)',
    category: EmotionCategory.realization,
    assetPath: 'assets/characters/animation/realization/char_relief.json',
  ),
  'relief_error': AnimationMeta(
    id: 'relief_error',
    nameKo: '안심(오류)',
    category: EmotionCategory.error,
    assetPath: 'assets/characters/animation/error/char_relief.json',
  ),

  // love 캐릭터 - 4가지 감정
  'love_happiness': AnimationMeta(
    id: 'love_happiness',
    nameKo: '사랑(기쁨)',
    category: EmotionCategory.happiness,
    assetPath: 'assets/characters/animation/happiness/char_love.json',
  ),
  'love_sadness': AnimationMeta(
    id: 'love_sadness',
    nameKo: '사랑(슬픔)',
    category: EmotionCategory.sadness,
    assetPath: 'assets/characters/animation/sadness/char_love.json',
  ),
  'love_anger': AnimationMeta(
    id: 'love_anger',
    nameKo: '사랑(분노)',
    category: EmotionCategory.anger,
    assetPath: 'assets/characters/animation/anger/char_love.json',
  ),
  'love_fear': AnimationMeta(
    id: 'love_fear',
    nameKo: '사랑(공포)',
    category: EmotionCategory.fear,
    assetPath: 'assets/characters/animation/fear/char_love.json',
  ),

  // love 캐릭터 - 5가지 상태
  'love_basic': AnimationMeta(
    id: 'love_basic',
    nameKo: '사랑(기본)',
    category: EmotionCategory.basic,
    assetPath: 'assets/characters/animation/basic/char_love.json',
  ),
  'love_listening': AnimationMeta(
    id: 'love_listening',
    nameKo: '사랑(듣는중)',
    category: EmotionCategory.listening,
    assetPath: 'assets/characters/animation/listening/char_love.json',
  ),
  'love_thinking': AnimationMeta(
    id: 'love_thinking',
    nameKo: '사랑(생각중)',
    category: EmotionCategory.thinking,
    assetPath: 'assets/characters/animation/thinking/char_love.json',
  ),
  'love_realization': AnimationMeta(
    id: 'love_realization',
    nameKo: '사랑(깨달음)',
    category: EmotionCategory.realization,
    assetPath: 'assets/characters/animation/realization/char_love.json',
  ),
  'love_error': AnimationMeta(
    id: 'love_error',
    nameKo: '사랑(오류)',
    category: EmotionCategory.error,
    assetPath: 'assets/characters/animation/error/char_love.json',
  ),

  // sadness 캐릭터 - 4가지 감정
  'sadness_happiness': AnimationMeta(
    id: 'sadness_happiness',
    nameKo: '슬픔(기쁨)',
    category: EmotionCategory.happiness,
    assetPath: 'assets/characters/animation/happiness/char_sadness.json',
  ),
  'sadness_sadness': AnimationMeta(
    id: 'sadness_sadness',
    nameKo: '슬픔(슬픔)',
    category: EmotionCategory.sadness,
    assetPath: 'assets/characters/animation/sadness/char_sadness.json',
  ),
  'sadness_anger': AnimationMeta(
    id: 'sadness_anger',
    nameKo: '슬픔(분노)',
    category: EmotionCategory.anger,
    assetPath: 'assets/characters/animation/anger/char_sadness.json',
  ),
  'sadness_fear': AnimationMeta(
    id: 'sadness_fear',
    nameKo: '슬픔(공포)',
    category: EmotionCategory.fear,
    assetPath: 'assets/characters/animation/fear/char_sadness.json',
  ),

  // sadness 캐릭터 - 5가지 상태
  'sadness_basic': AnimationMeta(
    id: 'sadness_basic',
    nameKo: '슬픔(기본)',
    category: EmotionCategory.basic,
    assetPath: 'assets/characters/animation/basic/char_sadness.json',
  ),
  'sadness_listening': AnimationMeta(
    id: 'sadness_listening',
    nameKo: '슬픔(듣는중)',
    category: EmotionCategory.listening,
    assetPath: 'assets/characters/animation/listening/char_sadness.json',
  ),
  'sadness_thinking': AnimationMeta(
    id: 'sadness_thinking',
    nameKo: '슬픔(생각중)',
    category: EmotionCategory.thinking,
    assetPath: 'assets/characters/animation/thinking/char_sadness.json',
  ),
  'sadness_realization': AnimationMeta(
    id: 'sadness_realization',
    nameKo: '슬픔(깨달음)',
    category: EmotionCategory.realization,
    assetPath: 'assets/characters/animation/realization/char_sadness.json',
  ),
  'sadness_error': AnimationMeta(
    id: 'sadness_error',
    nameKo: '슬픔(오류)',
    category: EmotionCategory.error,
    assetPath: 'assets/characters/animation/error/char_sadness.json',
  ),

  // bg_love 배경 캐릭터 - 4가지 감정
  'bg_love_happiness': AnimationMeta(
    id: 'bg_love_happiness',
    nameKo: '사랑 배경(기쁨)',
    category: EmotionCategory.happiness,
    assetPath: 'assets/characters/animation/happiness/bg_char_love.json',
  ),
  'bg_love_sadness': AnimationMeta(
    id: 'bg_love_sadness',
    nameKo: '사랑 배경(슬픔)',
    category: EmotionCategory.sadness,
    assetPath: 'assets/characters/animation/sadness/bg_char_love.json',
  ),
  'bg_love_anger': AnimationMeta(
    id: 'bg_love_anger',
    nameKo: '사랑 배경(분노)',
    category: EmotionCategory.anger,
    assetPath: 'assets/characters/animation/anger/bg_char_love.json',
  ),
  'bg_love_fear': AnimationMeta(
    id: 'bg_love_fear',
    nameKo: '사랑 배경(공포)',
    category: EmotionCategory.fear,
    assetPath: 'assets/characters/animation/fear/bg_char_love.json',
  ),

  // bg_love 배경 캐릭터 - 5가지 상태
  'bg_love_basic': AnimationMeta(
    id: 'bg_love_basic',
    nameKo: '사랑 배경(기본)',
    category: EmotionCategory.basic,
    assetPath: 'assets/characters/animation/basic/bg_char_love.json',
  ),
  'bg_love_listening': AnimationMeta(
    id: 'bg_love_listening',
    nameKo: '사랑 배경(듣는중)',
    category: EmotionCategory.listening,
    assetPath: 'assets/characters/animation/listening/bg_char_love.json',
  ),
  'bg_love_thinking': AnimationMeta(
    id: 'bg_love_thinking',
    nameKo: '사랑 배경(생각중)',
    category: EmotionCategory.thinking,
    assetPath: 'assets/characters/animation/thinking/bg_char_love.json',
  ),
  'bg_love_realization': AnimationMeta(
    id: 'bg_love_realization',
    nameKo: '사랑 배경(깨달음)',
    category: EmotionCategory.realization,
    assetPath: 'assets/characters/animation/realization/bg_char_love.json',
  ),
  'bg_love_error': AnimationMeta(
    id: 'bg_love_error',
    nameKo: '사랑 배경(오류)',
    category: EmotionCategory.error,
    assetPath: 'assets/characters/animation/error/bg_char_love.json',
  ),

  // TODO: 향후 추가될 캐릭터들
  // 예시:
  // 'joy_happiness': AnimationMeta(
  //   id: 'joy_happiness',
  //   nameKo: '기쁨(기쁨)',
  //   category: EmotionCategory.happiness,
  //   assetPath: 'assets/characters/animation/happiness/char_joy.json',
  // ),
};

/// 감정군별 캐릭터 목록 조회 헬퍼 함수
List<AnimationMeta> getAnimationsByCategory(EmotionCategory category) {
  return animationMetaMap.values
      .where((meta) => meta.category == category)
      .toList();
}

/// 캐릭터 ID와 감정 카테고리로 애니메이션 조회
/// 예: getAnimationByCharacterAndEmotion('relief', EmotionCategory.happiness)
/// 반환: 'relief_happiness' 애니메이션 메타정보
AnimationMeta? getAnimationByCharacterAndEmotion(
  String characterId,
  EmotionCategory category,
) {
  final key = '${characterId}_${category.name}';
  return animationMetaMap[key];
}

/// 애니메이션 캐릭터 위젯
/// Lottie JSON 애니메이션을 표시하는 위젯
class AnimatedCharacter extends StatelessWidget {
  final String characterId; // 'relief_happiness', 'relief_sadness' 등 조합 ID
  final double size;
  final BoxFit fit;
  final bool repeat;
  final bool animate;

  /// 기본 생성자: characterId와 emotion을 받아서 조합
  /// 예: AnimatedCharacter(characterId: 'relief', emotion: 'happiness')
  const AnimatedCharacter({
    super.key,
    required String characterId,
    String emotion = 'happiness',
    this.size = 120,
    this.fit = BoxFit.contain,
    this.repeat = true,
    this.animate = true,
  }) : characterId = '${characterId}_$emotion';

  /// 조합 ID를 직접 사용하는 생성자
  /// 예: AnimatedCharacter.fromId(characterId: 'relief_happiness')
  const AnimatedCharacter.fromId({
    super.key,
    required this.characterId,
    this.size = 120,
    this.fit = BoxFit.contain,
    this.repeat = true,
    this.animate = true,
  });

  /// 캐릭터 ID와 감정 카테고리 enum을 사용하는 생성자
  /// 예: AnimatedCharacter.withCategory(characterId: 'relief', category: EmotionCategory.happiness)
  AnimatedCharacter.withCategory({
    super.key,
    required String characterId,
    required EmotionCategory category,
    this.size = 120,
    this.fit = BoxFit.contain,
    this.repeat = true,
    this.animate = true,
  }) : characterId = '${characterId}_${category.name}';

  @override
  Widget build(BuildContext context) {
    final meta = animationMetaMap[characterId];

    if (meta == null) {
      // 캐릭터를 찾을 수 없는 경우 에러 표시
      return Container(
        width: size,
        height: size,
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.error_outline, color: Colors.red),
        ),
      );
    }

    return Lottie.asset(
      meta.assetPath,
      width: size,
      height: size,
      fit: fit,
      repeat: repeat,
      animate: animate,
      errorBuilder: (context, error, stackTrace) {
        // Lottie 로딩 실패 시 에러 표시
        return Container(
          width: size,
          height: size,
          color: Colors.grey[300],
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.red),
          ),
        );
      },
    );
  }
}
