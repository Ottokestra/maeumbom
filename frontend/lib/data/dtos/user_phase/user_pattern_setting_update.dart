import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_pattern_setting_update.freezed.dart';
part 'user_pattern_setting_update.g.dart';

@freezed
class UserPatternSettingUpdate with _$UserPatternSettingUpdate {
  const factory UserPatternSettingUpdate({
    @JsonKey(name: 'weekday_wake_time') required String weekdayWakeTime,
    @JsonKey(name: 'weekday_sleep_time') required String weekdaySleepTime,
    @JsonKey(name: 'weekend_wake_time') required String weekendWakeTime,
    @JsonKey(name: 'weekend_sleep_time') required String weekendSleepTime,
    @JsonKey(name: 'is_night_worker') @Default(false) bool isNightWorker,
  }) = _UserPatternSettingUpdate;

  factory UserPatternSettingUpdate.fromJson(Map<String, dynamic> json) =>
      _$UserPatternSettingUpdateFromJson(json);
}

