export const CHARACTER_MAP = {
  PEACH_WORRY: { emoji: "🍑", label: "걱정 복숭아" },
  FIRE_ANGRY: { emoji: "🔥", label: "화난 불꽃" },
  CLOUD_SAD: { emoji: "🌧️", label: "슬픈 구름" },
  BREEZE_RELIEF: { emoji: "🍃", label: "시원한 바람" },
  STAR_HOPE: { emoji: "✨", label: "반짝이는 희망" },
  BEAR_CALM: { emoji: "🐻", label: "포근한 곰" },
  HAMSTER_BOOMI: { emoji: "🐹", label: "봄이" },
};

export function getCharacterByKey(key) {
  if (!key) return null;
  return CHARACTER_MAP[key] || null;
}
