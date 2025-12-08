import 'package:freezed_annotation/freezed_annotation.dart';

part 'weekday_pattern.freezed.dart';
part 'weekday_pattern.g.dart';

@freezed
class WeekdayPattern with _$WeekdayPattern {
  const factory WeekdayPattern({
    @JsonKey(name: 'avg_wake_time') required String avgWakeTime,
    @JsonKey(name: 'avg_sleep_time') required String avgSleepTime,
    @JsonKey(name: 'avg_sleep_duration') double? avgSleepDuration,
  }) = _WeekdayPattern;

  factory WeekdayPattern.fromJson(Map<String, dynamic> json) =>
      _$WeekdayPatternFromJson(json);
}

