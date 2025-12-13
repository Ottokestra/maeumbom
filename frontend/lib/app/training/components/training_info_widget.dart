import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../ui/characters/app_characters.dart';
import '../../../ui/components/progress_card.dart';
import '../../../providers/daily_mood_provider.dart';

/// 연습 기록 카드 위젯
///
/// 마음연습실(관계 연습, 신조어 퀴즈)에서 사용하는 공통 정보 카드
/// 사용자의 오늘 감정 캐릭터와 진행도를 표시합니다.
///
/// 사용 예시:
/// ```dart
/// TrainingInfoWidget(
///   completedCount: 2,
///   totalCount: 4,
/// )
/// ```
class TrainingInfoWidget extends ConsumerWidget {
  /// 완료한 연습/퀴즈 개수
  final int completedCount;

  /// 전체 연습/퀴즈 개수
  final int totalCount;

  /// 좌우 패딩 (기본값: 없음, 부모에서 관리)
  final EdgeInsets? padding;

  const TrainingInfoWidget({
    super.key,
    required this.completedCount,
    required this.totalCount,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 실제 사용자의 오늘의 감정 가져오기
    final dailyState = ref.watch(dailyMoodProvider);
    final EmotionId emotionId = dailyState.selectedEmotion ?? EmotionId.relief;

    return ProgressCard(
      topLabel: '내 연습 기록',
      currentValue: completedCount,
      totalValue: totalCount,
      bottomMessage: null, // 기본 메시지 사용: "n개 완료 / 전체 m개"
      leadingWidget: EmotionCharacter(
        id: emotionId,
        size: 45,
      ),
      padding: padding,
    );
  }
}
