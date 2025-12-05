const characterMap = {
  peach_worry: '🍑',
  cloud_sad: '🌧',
  sun_happy: '🌻',
  book_focus: '📚',
  nap_sleepy: '😴',
  lion_brave: '🦁',
  star_proud: '🌟'
}

export function getCharacterEmoji(key) {
  if (!key) return '🤍'
  return characterMap[key] || '🤍'
}

export function getCharacterMap() {
  return { ...characterMap }
}

// 새 감정 캐릭터 추가 시, characterMap과 emotion-code 매핑만 추가하면 됨.
// 리포트 꾸미기(배지, 모자, 배경효과)는 이후 decorations 필드 추가로 확장 예정.
