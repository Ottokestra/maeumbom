import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../ui/characters/app_characters.dart';

part 'memory_item.freezed.dart';
part 'memory_item.g.dart';

/// 기억서랍 아이템 모델
/// 과거 기억과 미래 일정을 타임라인 형식으로 표시하기 위한 데이터 모델
@freezed
class MemoryItem with _$MemoryItem {
  const MemoryItem._();

  const factory MemoryItem({
    required int id,
    required String content,
    required DateTime timestamp,
    required MemoryCategory category,
    required bool isPast, // true=과거(회색), false=미래(핑크)
    String? title,
  }) = _MemoryItem;

  /// JSON 역직렬화
  factory MemoryItem.fromJson(Map<String, dynamic> json) =>
      _$MemoryItemFromJson(json);

  /// 시간 표시 문자열 (UI용)
  /// 예: "오후 2:30"
  String get timeString {
    final hour = timestamp.hour > 12 ? timestamp.hour - 12 : timestamp.hour == 0 ? 12 : timestamp.hour;
    final period = timestamp.hour >= 12 ? '오후' : '오전';
    final minuteStr = timestamp.minute.toString().padLeft(2, '0');
    return '$period $hour:$minuteStr';
  }

  /// 날짜 인디케이터 문자열 (UI용)
  /// 예: "16화" (16일 화요일)
  String get dateIndicator {
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[timestamp.weekday - 1];
    return '${timestamp.day}$weekday';
  }
}

/// 기억 카테고리
enum MemoryCategory {
  spouse, // 배우자
  children, // 자식
  friend, // 친구
  workplace; // 직장

  /// 카테고리 라벨
  String get label {
    switch (this) {
      case MemoryCategory.spouse:
        return '배우자';
      case MemoryCategory.children:
        return '자식';
      case MemoryCategory.friend:
        return '친구';
      case MemoryCategory.workplace:
        return '직장';
    }
  }

  /// 감정 ID 매핑 (TagBadge 컴포넌트에서 색상 결정에 사용)
  EmotionId get emotionId {
    switch (this) {
      case MemoryCategory.spouse:
        return EmotionId.love; // 핑크
      case MemoryCategory.children:
        return EmotionId.joy; // 노란색
      case MemoryCategory.friend:
        return EmotionId.interest; // 파란색
      case MemoryCategory.workplace:
        return EmotionId.enlightenment; // 밝은색
    }
  }

  /// JSON 직렬화를 위한 문자열 변환
  String toJson() => name;

  /// JSON 역직렬화를 위한 문자열 파싱
  static MemoryCategory fromJson(String json) {
    return MemoryCategory.values.firstWhere(
      (e) => e.name == json,
      orElse: () => MemoryCategory.friend,
    );
  }
}
