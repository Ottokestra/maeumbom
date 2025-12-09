import 'package:freezed_annotation/freezed_annotation.dart';

part 'weekend_pattern.freezed.dart';
part 'weekend_pattern.g.dart';

@freezed
class WeekendPattern with _$WeekendPattern {
  const factory WeekendPattern({
    @JsonKey(name: 'avg_wake_time') required String avgWakeTime,
    @JsonKey(name: 'avg_sleep_time') required String avgSleepTime,
    @JsonKey(name: 'avg_sleep_duration') double? avgSleepDuration,
  }) = _WeekendPattern;

  factory WeekendPattern.fromJson(Map<String, dynamic> json) =>
      _$WeekendPatternFromJson(json);
}

