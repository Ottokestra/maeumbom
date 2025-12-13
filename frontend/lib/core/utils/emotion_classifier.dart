import '../../ui/characters/app_characters.dart';

enum MoodCategory {
  good,
  neutral,
  bad,
}

class EmotionClassifier {
  static MoodCategory classify(EmotionId id) {
    switch (id) {
      // Good
      case EmotionId.joy:
      case EmotionId.excitement:
      case EmotionId.confidence:
      case EmotionId.love:
      case EmotionId.enlightenment:
        return MoodCategory.good;

      // Neutral
      case EmotionId.relief:
      case EmotionId.interest:
      case EmotionId.boredom:
      case EmotionId.confusion:
        return MoodCategory.neutral;

      // Bad
      case EmotionId.discontent:
      case EmotionId.shame:
      case EmotionId.sadness:
      case EmotionId.guilt:
      case EmotionId.depression:
      case EmotionId.contempt:
      case EmotionId.anger:
      case EmotionId.fear:
        return MoodCategory.bad;
    }
  }

  static List<EmotionId> getEmotionsByCategory(MoodCategory category) {
    return EmotionId.values.where((id) => classify(id) == category).toList();
  }
}
