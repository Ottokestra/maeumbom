import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// 4가지 감정군 카테고리
enum EmotionCategory {
  happiness,
  sedness,
  anger,
  fear,
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
/// relief 캐릭터의 4가지 감정 애니메이션
/// 향후 다른 캐릭터 추가 시 '{characterId}_{emotion}' 패턴으로 추가
const Map<String, AnimationMeta> animationMetaMap = {
  'relief_happiness': AnimationMeta(
    id: 'relief_happiness',
    nameKo: '안심(기쁨)',
    category: EmotionCategory.happiness,
    assetPath: 'assets/characters/animation/happiness/char_relief.json',
  ),
  'relief_sedness': AnimationMeta(
    id: 'relief_sedness',
    nameKo: '안심(슬픔)',
    category: EmotionCategory.sedness,
    assetPath: 'assets/characters/animation/sedness/char_relief.json',
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
  final String characterId; // 'relief_happiness', 'relief_sedness' 등 조합 ID
  final double size;
  final BoxFit fit;
  final bool repeat;
  final bool animate;

  /// 기본 생성자: characterId와 emotion을 받아서 조합
  /// 예: AnimatedCharacter(characterId: 'relief', emotion: 'happiness')
  AnimatedCharacter({
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
