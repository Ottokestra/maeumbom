export const EMOTION_CHARACTERS = {
  PEACH_WORRY: {
    code: 'PEACH_WORRY',
    emoji: '🍑',
    label: '걱정이 복숭아',
    description: '걱정과 불안이 조금 느껴지는 한 주',
  },
  SUNFLOWER_JOY: {
    code: 'SUNFLOWER_JOY',
    emoji: '🌻',
    label: '햇살 해바라기',
    description: '따뜻한 기쁨이 가득한 한 주',
  },
  STAR_PROUD: {
    code: 'STAR_PROUD',
    emoji: '🌟',
    label: '반짝 별자랑',
    description: '스스로가 자랑스러운 마음이 커진 한 주',
  },
  CAT_CURIOUS: {
    code: 'CAT_CURIOUS',
    emoji: '🐱',
    label: '호기심 고양이',
    description: '새로운 것이 궁금해지는 한 주',
  },
  BULB_IDEA: {
    code: 'BULB_IDEA',
    emoji: '💡',
    label: '아이디어 전구',
    description: '영감이 번쩍이는 순간이 많았던 한 주',
  },
  CLOUD_CALM: {
    code: 'CLOUD_CALM',
    emoji: '☁️',
    label: '차분 구름',
    description: '고요하고 평온한 마음이 유지된 한 주',
  },
  FISH_FLOW: {
    code: 'FISH_FLOW',
    emoji: '🐠',
    label: '유영 물고기',
    description: '자연스럽게 흘러가는 하루들을 보낸 한 주',
  },
  FLAME_PASSION: {
    code: 'FLAME_PASSION',
    emoji: '🔥',
    label: '열정 불꽃',
    description: '열정과 의지가 활활 타오른 한 주',
  },
  RAINY_CLOUD: {
    code: 'RAINY_CLOUD',
    emoji: '🌧️',
    label: '눈물비 구름',
    description: '슬픔과 우울이 스며든 한 주',
  },
  GHOST_SHY: {
    code: 'GHOST_SHY',
    emoji: '👻',
    label: '수줍은 유령',
    description: '낯을 가리며 조심스러웠던 한 주',
  },
  ROCK_STEADY: {
    code: 'ROCK_STEADY',
    emoji: '🪨',
    label: '든든한 바위',
    description: '흔들리지 않고 묵직하게 버틴 한 주',
  },
  PUMPKIN_WARM: {
    code: 'PUMPKIN_WARM',
    emoji: '🎃',
    label: '포근한 호박',
    description: '따뜻하고 편안한 순간이 많았던 한 주',
  },
  SLOTH_RELAX: {
    code: 'SLOTH_RELAX',
    emoji: '🦥',
    label: '느긋한 나무늘보',
    description: '쉬어가며 여유를 챙긴 한 주',
  },
  DEVIL_MISCHIEF: {
    code: 'DEVIL_MISCHIEF',
    emoji: '😈',
    label: '장난꾸러기 악마',
    description: '장난기와 반항심이 살짝 올라온 한 주',
  },
  ALIEN_WONDER: {
    code: 'ALIEN_WONDER',
    emoji: '👽',
    label: '미지 탐험가',
    description: '색다른 경험과 호기심이 가득한 한 주',
  },
  ROBOT_STEADY: {
    code: 'ROBOT_STEADY',
    emoji: '🤖',
    label: '성실한 로봇',
    description: '꾸준히 계획을 실행한 한 주',
  },
}

export function resolveCharacterMeta(code) {
  if (!code) return EMOTION_CHARACTERS.PEACH_WORRY

  const normalizedCode = String(code).toUpperCase()
  return EMOTION_CHARACTERS[normalizedCode] || EMOTION_CHARACTERS.PEACH_WORRY
}
