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
  final String nameKo;      // 기쁨
  final String nameEn;      // joy
  final String characterKo; // 해바라기
  final String characterEn; // sunflower
  final String shortDesc;   // 한 줄 설명
  final String assetnormal;
  final String assetHigh;

  const EmotionMeta({
    required this.id,
    required this.nameKo,
    required this.nameEn,
    required this.characterKo,
    required this.characterEn,
    required this.shortDesc,
    required this.assetnormal,
    required this.assetHigh,
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
    shortDesc: '행복/에너지 UP → 밝고 기분 좋은 상태',
    assetnormal: 'assets/characters/normal/char_joy.png',
    assetHigh: 'assets/characters/high/char_joy.png',
  ),
  EmotionId.excitement: EmotionMeta(
    id: EmotionId.excitement,
    nameKo: '흥분',
    nameEn: 'excitement',
    characterKo: '별',
    characterEn: 'star',
    shortDesc: '흥분/기대 → 기대와 에너지가 치솟는 상태',
    assetnormal: 'assets/characters/normal/char_excitement.png',
    assetHigh: 'assets/characters/high/char_excitement.png',
  ),
  EmotionId.confidence: EmotionMeta(
    id: EmotionId.confidence,
    nameKo: '자신감',
    nameEn: 'confidence',
    characterKo: '사자',
    characterEn: 'lion',
    shortDesc: '확신/추진력 → 잘 해낼 수 있다고 느끼는 상태',
    assetnormal: 'assets/characters/normal/char_confidence.png',
    assetHigh: 'assets/characters/high/char_confidence.png',
  ),
  EmotionId.love: EmotionMeta(
    id: EmotionId.love,
    nameKo: '사랑',
    nameEn: 'love',
    characterKo: '펭귄',
    characterEn: 'peng_gwin',
    shortDesc: '애착/온기 → 따뜻한 애정을 느끼는 상태',
    assetnormal: 'assets/characters/normal/char_love.png',
    assetHigh: 'assets/characters/high/char_love.png',
  ),
  EmotionId.relief: EmotionMeta(
    id: EmotionId.relief,
    nameKo: '안심',
    nameEn: 'relief',
    characterKo: '사슴',
    characterEn: 'deer',
    shortDesc: '평온/안정 → 걱정이 풀리고 편안해진 상태',
    assetnormal: 'assets/characters/normal/char_relief.png',
    assetHigh: 'assets/characters/high/char_relief.png',
  ),
  EmotionId.enlightenment: EmotionMeta(
    id: EmotionId.enlightenment,
    nameKo: '깨달음',
    nameEn: 'enlightenment',
    characterKo: '전구',
    characterEn: 'electric_bulb',
    shortDesc: '통찰/성장 → 이해하고 시야가 트인 상태',
    assetnormal: 'assets/characters/normal/char_enlightenment.png',
    assetHigh: 'assets/characters/high/char_enlightenment.png',
  ),
  EmotionId.interest: EmotionMeta(
    id: EmotionId.interest,
    nameKo: '흥미',
    nameEn: 'interest',
    characterKo: '부엉이',
    characterEn: 'owl',
    shortDesc: '호기심/몰입 → 더 알고 싶고 해보고 싶은 상태',
    assetnormal: 'assets/characters/normal/char_interest.png',
    assetHigh: 'assets/characters/high/char_interest.png',
  ),

  // ❌ 부정
  EmotionId.discontent: EmotionMeta(
    id: EmotionId.discontent,
    nameKo: '불만',
    nameEn: 'discontent',
    characterKo: '당근',
    characterEn: 'carrot',
    shortDesc: '거슬림/답답함 → 지금 상황이 못마땅한 상태',
    assetnormal: 'assets/characters/normal/char_discontent.png',
    assetHigh: 'assets/characters/high/char_discontent.png',
  ),
  EmotionId.shame: EmotionMeta(
    id: EmotionId.shame,
    nameKo: '수치',
    nameEn: 'shame',
    characterKo: '복숭아',
    characterEn: 'peach',
    shortDesc: '창피함/자기비난 → 숨고 싶어지는 상태',
    assetnormal: 'assets/characters/normal/char_shame.png',
    assetHigh: 'assets/characters/high/char_shame.png',
  ),
  EmotionId.sadness: EmotionMeta(
    id: EmotionId.sadness,
    nameKo: '슬픔',
    nameEn: 'sadness',
    characterKo: '고래',
    characterEn: 'whale',
    shortDesc: '상실감 → 상실이나 상처로 마음이 아픈 상태',
    assetnormal: 'assets/characters/normal/char_sadness.png',
    assetHigh: 'assets/characters/high/char_sadness.png',
  ),
  EmotionId.guilt: EmotionMeta(
    id: EmotionId.guilt,
    nameKo: '죄책감',
    nameEn: 'guilt',
    characterKo: '곰',
    characterEn: 'bear',
    shortDesc: '미안함/자기책임 → 내가 잘못했다 느끼는 상태',
    assetnormal: 'assets/characters/normal/char_guilt.png',
    assetHigh: 'assets/characters/high/char_guilt.png',
  ),
  EmotionId.depression: EmotionMeta(
    id: EmotionId.depression,
    nameKo: '우울',
    nameEn: 'depression',
    characterKo: '돌',
    characterEn: 'stone',
    shortDesc: '무기력 → 의욕이 없고 모든 게 힘든 상태',
    assetnormal: 'assets/characters/normal/char_depression.png',
    assetHigh: 'assets/characters/high/char_depression.png',
  ),
  EmotionId.boredom: EmotionMeta(
    id: EmotionId.boredom,
    nameKo: '무료',
    nameEn: 'boredom',
    characterKo: '나무늘보',
    characterEn: 'sloth',
    shortDesc: '심심함/무의욕 → 아무것도 하기 싫은 상태',
    assetnormal: 'assets/characters/normal/char_boredom.png',
    assetHigh: 'assets/characters/high/char_boredom.png',
  ),
  EmotionId.contempt: EmotionMeta(
    id: EmotionId.contempt,
    nameKo: '경멸',
    nameEn: 'contempt',
    characterKo: '가지',
    characterEn: 'plant',
    shortDesc: '무시/냉소 → 상대를 깔보고 가치 없다고 느끼는 상태',
    assetnormal: 'assets/characters/normal/char_contempt.png',
    assetHigh: 'assets/characters/high/char_contempt.png',
  ),
  EmotionId.anger: EmotionMeta(
    id: EmotionId.anger,
    nameKo: '화',
    nameEn: 'anger',
    characterKo: '불',
    characterEn: 'fire',
    shortDesc: '분노/폭발 → 부당하다고 느껴져 치밀어 오르는 상태',
    assetnormal: 'assets/characters/normal/char_anger.png',
    assetHigh: 'assets/characters/high/char_anger.png',
  ),
  EmotionId.fear: EmotionMeta(
    id: EmotionId.fear,
    nameKo: '공포',
    nameEn: 'fear',
    characterKo: '쥐',
    characterEn: 'mouse',
    shortDesc: '위협감/긴장 → 위험을 느끼며 두려운 상태',
    assetnormal: 'assets/characters/normal/char_fear.png',
    assetHigh: 'assets/characters/high/char_fear.png',
  ),
  EmotionId.confusion: EmotionMeta(
    id: EmotionId.confusion,
    nameKo: '혼란',
    nameEn: 'confusion',
    characterKo: '로봇',
    characterEn: 'robot',
    shortDesc: '갈피상실/혼동 → 무엇이 맞는지 모르는 상태',
    assetnormal: 'assets/characters/normal/char_confusion.png',
    assetHigh: 'assets/characters/high/char_confusion.png',
  ),
};

/// 감정 캐릭터 출력용 위젯
class EmotionCharacter extends StatelessWidget {
  final EmotionId id;
  final bool highRes;
  final double size;

  const EmotionCharacter({
    super.key,
    required this.id,
    this.highRes = false,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    final meta = emotionMetaMap[id]!;
    final assetPath = highRes ? meta.assetHigh : meta.assetnormal;

    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}