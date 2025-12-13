import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  DailyMoodNotifier() : super(const DailyMoodState()) {
    _loadFromStorage();
  }

  static const String _keyEmotion = 'daily_mood_emotion';
  static const String _keyCheckedAt = 'daily_mood_checked_at';

  /// SharedPreferences에서 감정 데이터 로드
  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();

    final emotionIndex = prefs.getInt(_keyEmotion);
    final checkedAtStr = prefs.getString(_keyCheckedAt);

    if (emotionIndex != null && checkedAtStr != null) {
      final emotion = EmotionId.values[emotionIndex];
      final checkedAt = DateTime.parse(checkedAtStr);

      // 하루가 지났는지 확인
      final now = DateTime.now();
      if (now.day == checkedAt.day &&
          now.month == checkedAt.month &&
          now.year == checkedAt.year) {
        // 같은 날이면 저장된 감정 복원
        state = DailyMoodState(
          hasChecked: true,
          selectedEmotion: emotion,
          checkedAt: checkedAt,
        );
      } else {
        // 날짜가 바뀌었으면 초기화
        await _clearStorage();
      }
    }
  }

  /// 감정 선택 및 저장
  Future<void> selectEmotion(EmotionId emotion) async {
    final now = DateTime.now();

    state = state.copyWith(
      hasChecked: true,
      selectedEmotion: emotion,
      checkedAt: now,
    );

    // SharedPreferences에 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyEmotion, emotion.index);
    await prefs.setString(_keyCheckedAt, now.toIso8601String());
  }

  /// 저장된 데이터 삭제
  Future<void> _clearStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyEmotion);
    await prefs.remove(_keyCheckedAt);
    state = const DailyMoodState();
  }

  /// 하루가 지났는지 체크하여 리셋
  Future<void> checkResetDaily() async {
    if (state.checkedAt != null) {
      final now = DateTime.now();
      final last = state.checkedAt!;
      if (now.day != last.day || now.month != last.month || now.year != last.year) {
        await _clearStorage();
      }
    }
  }
}

final dailyMoodProvider = StateNotifierProvider<DailyMoodNotifier, DailyMoodState>((ref) {
  return DailyMoodNotifier();
});
