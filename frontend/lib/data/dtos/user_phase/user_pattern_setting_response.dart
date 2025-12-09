import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_pattern_setting_response.freezed.dart';
part 'user_pattern_setting_response.g.dart';

@freezed
class UserPatternSettingResponse with _$UserPatternSettingResponse {
  const factory UserPatternSettingResponse({
    @JsonKey(name: 'weekday_wake_time') required String weekdayWakeTime,
    @JsonKey(name: 'weekday_sleep_time') required String weekdaySleepTime,
    @JsonKey(name: 'weekend_wake_time') required String weekendWakeTime,
    @JsonKey(name: 'weekend_sleep_time') required String weekendSleepTime,
    @JsonKey(name: 'is_night_worker') required bool isNightWorker,
    @JsonKey(name: 'last_analysis_date') String? lastAnalysisDate,
    @JsonKey(name: 'data_completeness') double? dataCompleteness,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
  }) = _UserPatternSettingResponse;

  factory UserPatternSettingResponse.fromJson(Map<String, dynamic> json) =>
      _$UserPatternSettingResponseFromJson(json);
}

