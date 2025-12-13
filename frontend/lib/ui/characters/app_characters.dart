import 'package:flutter/material.dart';

/// 17가지 감정 ID
enum EmotionId {
  joy,
  excitement,
  confidence,
  love,
  relief,
  enlightenment,
  interest,
  discontent,
  shame,
  sadness,
  guilt,
  depression,
  boredom,
  contempt,
  anger,
  fear,
  confusion,
}

/// 감정 메타정보
class EmotionMeta {
  final EmotionId id;
  final String nameKo; // 기쁨
  final String nameEn; // joy
  final String characterKo; // 해바라기
  final String characterEn; // sunflower
  final String shortDesc; // 한 줄 설명
  final String assetNormal;
  final String assetNormal2d;

  const EmotionMeta({
    required this.id,
    required this.nameKo,
    required this.nameEn,
    required this.characterKo,
    required this.characterEn,
    required this.shortDesc,
    required this.assetNormal,
    required this.assetNormal2d,
  });
}

/// 감정 메타데이터 맵
const Map<EmotionId, EmotionMeta> emotionMetaMap = {
  // ✅ 긍정
  EmotionId.joy: EmotionMeta(
    id: EmotionId.joy,
    nameKo: '기쁨',
    nameEn: 'joy',
    characterKo: '해바라기',
    characterEn: 'sunflower',
    shortDesc: '밝고 기분 좋은 상태',
    assetNormal: 'assets/characters/normal/char_joy.png',
    assetNormal2d: 'assets/characters/normal_2d/char_joy.png',
  ),
  EmotionId.excitement: EmotionMeta(
    id: EmotionId.excitement,
    nameKo: '흥분',
    nameEn: 'excitement',
    characterKo: '별',
    characterEn: 'star',
    shortDesc: '기대와 에너지가 치솟는 상태',
    assetNormal: 'assets/characters/normal/char_excitement.png',
    assetNormal2d: 'assets/characters/normal_2d/char_excitement.png',
  ),
  EmotionId.confidence: EmotionMeta(
    id: EmotionId.confidence,
    nameKo: '자신감',
    nameEn: 'confidence',
    characterKo: '사자',
    characterEn: 'lion',
    shortDesc: '잘 해낼 수 있다고 느끼는 상태',
    assetNormal: 'assets/characters/normal/char_confidence.png',
    assetNormal2d: 'assets/characters/normal_2d/char_confidence.png',
  ),
  EmotionId.love: EmotionMeta(
    id: EmotionId.love,
    nameKo: '사랑',
    nameEn: 'love',
    characterKo: '펭귄',
    characterEn: 'peng_gwin',
    shortDesc: '따뜻한 애정을 느끼는 상태',
    assetNormal: 'assets/characters/normal/char_love.png',
    assetNormal2d: 'assets/characters/normal_2d/char_love.png',
  ),
  EmotionId.relief: EmotionMeta(
    id: EmotionId.relief,
    nameKo: '안심',
    nameEn: 'relief',
    characterKo: '사슴',
    characterEn: 'deer',
    shortDesc: '걱정이 풀리고 편안해진 상태',
    assetNormal: 'assets/characters/normal/char_relief.png',
    assetNormal2d: 'assets/characters/normal_2d/char_relief.png',
  ),
  EmotionId.enlightenment: EmotionMeta(
    id: EmotionId.enlightenment,
    nameKo: '깨달음',
    nameEn: 'enlightenment',
    characterKo: '전구',
    characterEn: 'electric_bulb',
    shortDesc: '이해하고 시야가 트인 상태',
    assetNormal: 'assets/characters/normal/char_enlightenment.png',
    assetNormal2d: 'assets/characters/normal_2d/char_enlightenment.png',
  ),
  EmotionId.interest: EmotionMeta(
    id: EmotionId.interest,
    nameKo: '흥미',
    nameEn: 'interest',
    characterKo: '부엉이',
    characterEn: 'owl',
    shortDesc: '더 알고 싶고 해보고 싶은 상태',
    assetNormal: 'assets/characters/normal/char_interest.png',
    assetNormal2d: 'assets/characters/normal_2d/char_interest.png',
  ),

  // ❌ 부정
  EmotionId.discontent: EmotionMeta(
    id: EmotionId.discontent,
    nameKo: '불만',
    nameEn: 'discontent',
    characterKo: '당근',
    characterEn: 'carrot',
    shortDesc: '지금 상황이 못마땅한 상태',
    assetNormal: 'assets/characters/normal/char_discontent.png',
    assetNormal2d: 'assets/characters/normal_2d/char_discontent.png',
  ),
  EmotionId.shame: EmotionMeta(
    id: EmotionId.shame,
    nameKo: '수치',
    nameEn: 'shame',
    characterKo: '복숭아',
    characterEn: 'peach',
    shortDesc: '숨고 싶어지는 상태',
    assetNormal: 'assets/characters/normal/char_shame.png',
    assetNormal2d: 'assets/characters/normal_2d/char_shame.png',
  ),
  EmotionId.sadness: EmotionMeta(
    id: EmotionId.sadness,
    nameKo: '슬픔',
    nameEn: 'sadness',
    characterKo: '고래',
    characterEn: 'whale',
    shortDesc: '상실이나 상처로 마음이 아픈 상태',
    assetNormal: 'assets/characters/normal/char_sadness.png',
    assetNormal2d: 'assets/characters/normal_2d/char_sadness.png',
  ),
  EmotionId.guilt: EmotionMeta(
    id: EmotionId.guilt,
    nameKo: '죄책감',
    nameEn: 'guilt',
    characterKo: '곰',
    characterEn: 'bear',
    shortDesc: '내가 잘못했다 느끼는 상태',
    assetNormal: 'assets/characters/normal/char_guilt.png',
    assetNormal2d: 'assets/characters/normal_2d/char_guilt.png',
  ),
  EmotionId.depression: EmotionMeta(
    id: EmotionId.depression,
    nameKo: '우울',
    nameEn: 'depression',
    characterKo: '돌',
    characterEn: 'stone',
    shortDesc: '의욕이 없고 모든 게 힘든 상태',
    assetNormal: 'assets/characters/normal/char_depression.png',
    assetNormal2d: 'assets/characters/normal_2d/char_depression.png',
  ),
  EmotionId.boredom: EmotionMeta(
    id: EmotionId.boredom,
    nameKo: '무료',
    nameEn: 'boredom',
    characterKo: '나무늘보',
    characterEn: 'sloth',
    shortDesc: '아무것도 하기 싫은 상태',
    assetNormal: 'assets/characters/normal/char_boredom.png',
    assetNormal2d: 'assets/characters/normal_2d/char_boredom.png',
  ),
  EmotionId.contempt: EmotionMeta(
    id: EmotionId.contempt,
    nameKo: '경멸',
    nameEn: 'contempt',
    characterKo: '가지',
    characterEn: 'plant',
    shortDesc: '상대를 깔보고 가치 없다고 느끼는 상태',
    assetNormal: 'assets/characters/normal/char_contempt.png',
    assetNormal2d: 'assets/characters/normal_2d/char_contempt.png',
  ),
  EmotionId.anger: EmotionMeta(
    id: EmotionId.anger,
    nameKo: '화',
    nameEn: 'anger',
    characterKo: '불',
    characterEn: 'fire',
    shortDesc: '부당하다고 느껴져 치밀어 오르는 상태',
    assetNormal: 'assets/characters/normal/char_anger.png',
    assetNormal2d: 'assets/characters/normal_2d/char_anger.png',
  ),
  EmotionId.fear: EmotionMeta(
    id: EmotionId.fear,
    nameKo: '공포',
    nameEn: 'fear',
    characterKo: '쥐',
    characterEn: 'mouse',
    shortDesc: '위험을 느끼며 두려운 상태',
    assetNormal: 'assets/characters/normal/char_fear.png',
    assetNormal2d: 'assets/characters/normal_2d/char_fear.png',
  ),
  EmotionId.confusion: EmotionMeta(
    id: EmotionId.confusion,
    nameKo: '혼란',
    nameEn: 'confusion',
    characterKo: '로봇',
    characterEn: 'robot',
    shortDesc: '무엇이 맞는지 모르는 상태',
    assetNormal: 'assets/characters/normal/char_confusion.png',
    assetNormal2d: 'assets/characters/normal_2d/char_confusion.png',
  ),
};

/// 감정 캐릭터 출력용 위젯
class EmotionCharacter extends StatelessWidget {
  final EmotionId id;
  final bool use2d;
  final double size;

  const EmotionCharacter({
    super.key,
    required this.id,
    this.use2d = false,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    final meta = emotionMetaMap[id]!;
    final assetPath = use2d ? meta.assetNormal2d : meta.assetNormal;

    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
