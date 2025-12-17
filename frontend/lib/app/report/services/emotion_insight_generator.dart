import '../../../ui/app_ui.dart';
import '../../../core/utils/emotion_mapper.dart';

/// 감정 분석 텍스트 생성기 (템플릿 기반)
///
/// 주요 감정과 전체 감정 경향에 따라 미리 정의된 메시지를 반환합니다.
/// 루틴 추천 데이터가 있으면 구체적인 루틴을 포함한 메시지를 생성합니다.
class EmotionInsightGenerator {
  /// 감정 분석 텍스트 생성
  ///
  /// [primaryEmotion] 주요 감정 (EmotionId)
  /// [sentimentOverall] 전체 감정 경향 (positive/negative/neutral)
  /// [topEmotionPercentage] 주요 감정의 퍼센트 (예: 32.5)
  /// [recommendedRoutines] 추천된 루틴 제목 목록 (최대 3개)
  ///
  /// Returns: 감정 분석 텍스트
  static String generate({
    required EmotionId primaryEmotion,
    String? sentimentOverall,
    double? topEmotionPercentage,
    List<String>? recommendedRoutines,
  }) {
    // sentiment가 없거나 neutral인 경우
    if (sentimentOverall == null || sentimentOverall == 'neutral') {
      return _getNeutralMessage(
        primaryEmotion,
        topEmotionPercentage,
        recommendedRoutines,
      );
    }

    // positive인 경우
    if (sentimentOverall == 'positive') {
      return _getPositiveMessage(
        primaryEmotion,
        topEmotionPercentage,
        recommendedRoutines,
      );
    }

    // negative인 경우
    if (sentimentOverall == 'negative') {
      return _getNegativeMessage(
        primaryEmotion,
        topEmotionPercentage,
        recommendedRoutines,
      );
    }

    // 기본 메시지
    return '이번 주는 다양한 감정을 경험하셨네요. 여러 감정을 느끼는 것은 자연스러운 일이에요.';
  }

  /// 루틴 추천 문장 생성
  static String _buildRoutineText(List<String>? routines) {
    if (routines == null || routines.isEmpty) {
      return '';
    }

    if (routines.length == 1) {
      return ' 이런 감정을 위해 \'${routines[0]}\'를 추천드려요.';
    } else if (routines.length == 2) {
      return ' \'${routines[0]}\', \'${routines[1]}\' 같은 활동을 추천드려요.';
    } else {
      return ' \'${routines[0]}\', \'${routines[1]}\', \'${routines[2]}\' 같은 활동을 추천드려요.';
    }
  }

  /// 감정명을 한글로 변환
  static String _getEmotionKoreanName(EmotionId emotion) {
    return EmotionMapper.toKoreanName(
      EmotionMapper.toCode(emotion) ?? ''
    ) ?? '감정';
  }

  /// 퍼센트 텍스트 생성
  static String _getPercentText(double? percentage) {
    if (percentage == null) return '';
    return '${percentage.toStringAsFixed(0)}%';
  }

  /// 긍정적 감정 메시지
  static String _getPositiveMessage(
    EmotionId emotion,
    double? percentage,
    List<String>? routines,
  ) {
    final emotionName = _getEmotionKoreanName(emotion);
    final percentText = _getPercentText(percentage);
    final routineText = _buildRoutineText(routines);

    switch (emotion) {
      case EmotionId.joy:
        return '이번 주는 기쁨을 $percentText 느끼셨네요! 행복한 순간들이 많았던 한 주였어요.$routineText 이런 긍정적인 에너지를 계속 유지해보세요.';

      case EmotionId.love:
        return '이번 주는 사랑을 $percentText 느끼셨어요. 따뜻한 관계 속에서 행복을 느끼셨네요.$routineText 이 따뜻함을 더 키워보세요.';

      case EmotionId.relief:
        return '이번 주는 안심을 $percentText 느끼셨네요. 마음이 편안하고 안정적인 한 주였어요.$routineText 이런 평온함을 잘 유지하시면 좋겠어요.';

      case EmotionId.excitement:
        return '이번 주는 흥분을 $percentText 느끼셨어요! 활력이 넘치는 한 주였습니다.$routineText 이런 열정을 계속 이어가세요.';

      case EmotionId.confidence:
        return '이번 주는 자신감을 $percentText 느끼셨네요! 스스로를 믿는 마음이 강해지고 있어요.$routineText 계속해서 자신을 응원해주세요.';

      case EmotionId.enlightenment:
        return '이번 주는 깨달음을 $percentText 느끼셨네요! 새로운 통찰이 마음을 밝게 비추고 있어요.$routineText 이런 성장을 계속 이어가세요.';

      case EmotionId.interest:
        return '이번 주는 흥미를 $percentText 느끼셨네요! 호기심과 관심이 가득한 한 주였어요.$routineText 이런 탐구심을 계속 유지하세요.';

      default:
        return '이번 주는 ${emotionName}을 $percentText 느끼셨네요. 긍정적인 감정이 주를 이루었어요.$routineText 이런 좋은 에너지를 계속 유지하시면 좋겠어요.';
    }
  }

  /// 부정적 감정 메시지
  static String _getNegativeMessage(
    EmotionId emotion,
    double? percentage,
    List<String>? routines,
  ) {
    final emotionName = _getEmotionKoreanName(emotion);
    final percentText = _getPercentText(percentage);
    final routineText = _buildRoutineText(routines);

    switch (emotion) {
      case EmotionId.sadness:
        return '이번 주는 슬픔을 $percentText 느끼셨네요. 힘든 시간을 보내셨어요.$routineText 천천히 마음을 돌보는 시간을 가져보세요.';

      case EmotionId.fear:
        return '이번 주는 공포를 $percentText 느끼셨네요. 불안한 마음이 많으셨어요.$routineText 깊은 호흡과 함께 차분히 마음을 가라앉혀보세요.';

      case EmotionId.anger:
        return '이번 주는 화를 $percentText 느끼셨네요. 화가 나는 일들이 있으셨나봐요.$routineText 감정을 건강하게 표현하고 해소해보세요.';

      case EmotionId.confusion:
        return '이번 주는 혼란을 $percentText 느끼셨네요. 복잡한 마음이 많으셨어요.$routineText 하나씩 차근차근 정리해나가면 괜찮아질 거예요.';

      case EmotionId.depression:
        return '이번 주는 우울을 $percentText 느끼셨네요. 무기력한 순간들이 많으셨을 거예요.$routineText 작은 활동부터 천천히 시작해보세요.';

      case EmotionId.guilt:
        return '이번 주는 죄책감을 $percentText 느끼셨네요. 자신을 많이 탓하셨나봐요.$routineText 스스로를 너그럽게 대해주세요.';

      case EmotionId.shame:
        return '이번 주는 수치를 $percentText 느끼셨네요. 부끄러운 마음이 많았어요.$routineText 자신을 있는 그대로 받아들여보세요.';

      case EmotionId.discontent:
        return '이번 주는 불만을 $percentText 느끼셨네요. 마음이 불편한 순간들이 있으셨나봐요.$routineText 작은 변화부터 시도해보세요.';

      case EmotionId.boredom:
        return '이번 주는 무료함을 $percentText 느끼셨네요. 지루한 시간이 많았어요.$routineText 새로운 활동으로 활력을 찾아보세요.';

      case EmotionId.contempt:
        return '이번 주는 경멸을 $percentText 느끼셨네요. 불편한 감정이 많았어요.$routineText 자신의 감정을 건강하게 표현해보세요.';

      default:
        return '이번 주는 ${emotionName}을 $percentText 느끼셨네요. 조금 힘든 시간이었어요.$routineText 천천히 마음을 돌보는 시간을 가져보세요.';
    }
  }

  /// 중립적 감정 메시지
  static String _getNeutralMessage(
    EmotionId emotion,
    double? percentage,
    List<String>? routines,
  ) {
    final emotionName = _getEmotionKoreanName(emotion);
    final percentText = _getPercentText(percentage);
    final routineText = _buildRoutineText(routines);

    switch (emotion) {
      case EmotionId.joy:
        return '이번 주는 기쁨을 $percentText 느끼셨네요. 다양한 감정을 경험하면서 균형을 찾아가고 있어요.$routineText';

      case EmotionId.love:
        return '이번 주는 사랑을 $percentText 느끼셨네요. 여러 감정을 느끼는 것은 자연스러운 일이에요.$routineText';

      case EmotionId.sadness:
        return '이번 주는 슬픔을 $percentText 느끼셨네요. 다른 감정들도 함께 느끼면서 균형을 찾아가고 있어요.$routineText';

      case EmotionId.relief:
        return '이번 주는 안심을 $percentText 느끼셨네요. 마음의 평화를 찾아가고 있어요.$routineText';

      default:
        return '이번 주는 ${emotionName}을 $percentText 느끼셨네요. 다양한 감정을 경험하는 것은 자연스러운 일이에요.$routineText';
    }
  }
}
