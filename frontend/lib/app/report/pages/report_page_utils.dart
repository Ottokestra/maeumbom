import '../../../ui/characters/app_characters.dart';

EmotionId mapEmotionFromCode(String? characterCode, {String? emotionLabel}) {
  final normalizedCode = characterCode?.toLowerCase() ?? '';

  if (normalizedCode.isNotEmpty) {
    for (final entry in emotionMetaMap.entries) {
      final meta = entry.value;
      if (meta.characterEn.toLowerCase() == normalizedCode ||
          meta.nameEn.toLowerCase() == normalizedCode ||
          meta.nameKo == characterCode) {
        return entry.key;
      }
    }
  }

  if (emotionLabel != null && emotionLabel.isNotEmpty) {
    final normalizedLabel = emotionLabel.toLowerCase();
    final match = emotionMetaMap.entries.firstWhere(
      (entry) =>
          entry.value.nameKo == emotionLabel ||
          entry.value.nameEn.toLowerCase() == normalizedLabel,
      orElse: () => MapEntry(
        EmotionId.relief,
        emotionMetaMap[EmotionId.relief]!,
      ),
    );
    return match.key;
  }

  return EmotionId.relief;
}

String formatWeekdayLabel(String weekday) {
  switch (weekday.toUpperCase()) {
    case 'MON':
      return '월요일';
    case 'TUE':
      return '화요일';
    case 'WED':
      return '수요일';
    case 'THU':
      return '목요일';
    case 'FRI':
      return '금요일';
    case 'SAT':
      return '토요일';
    case 'SUN':
      return '일요일';
    default:
      return weekday;
  }
}

String formatShortDate(DateTime date) {
  return '${date.month}/${date.day}';
}

String formatDateTimeLabel(DateTime dateTime) {
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${dateTime.month}/${dateTime.day} ${twoDigits(dateTime.hour)}:${twoDigits(dateTime.minute)}';
}
