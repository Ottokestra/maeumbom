import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ui/characters/app_characters.dart';

/// 오늘의 감정 체크 상태 관리
class DailyMoodState {
  final bool hasChecked;
  final EmotionId? selectedEmotion;
  final DateTime? checkedAt;

  const DailyMoodState({
    this.hasChecked = false,
    this.selectedEmotion,
    this.checkedAt,
  });

  DailyMoodState copyWith({
    bool? hasChecked,
    EmotionId? selectedEmotion,
    DateTime? checkedAt,
  }) {
    return DailyMoodState(
      hasChecked: hasChecked ?? this.hasChecked,
      selectedEmotion: selectedEmotion ?? this.selectedEmotion,
      checkedAt: checkedAt ?? this.checkedAt,
    );
  }
}

class DailyMoodNotifier extends StateNotifier<DailyMoodState> {
  DailyMoodNotifier() : super(const DailyMoodState());

  void selectEmotion(EmotionId emotion) {
    state = state.copyWith(
      hasChecked: true,
      selectedEmotion: emotion,
      checkedAt: DateTime.now(),
    );
  }

  /// 하루가 지났는지 체크하여 리셋하는 로직이 필요하다면 여기에 추가
  void checkResetDaily() {
    if (state.checkedAt != null) {
      final now = DateTime.now();
      final last = state.checkedAt!;
      if (now.day != last.day || now.month != last.month || now.year != last.year) {
        state = const DailyMoodState(); // Reset
      }
    }
  }
}

final dailyMoodProvider = StateNotifierProvider<DailyMoodNotifier, DailyMoodState>((ref) {
  return DailyMoodNotifier();
});
