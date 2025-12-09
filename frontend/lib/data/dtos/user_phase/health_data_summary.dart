import 'package:freezed_annotation/freezed_annotation.dart';

part 'health_data_summary.freezed.dart';
part 'health_data_summary.g.dart';

@freezed
class HealthDataSummary with _$HealthDataSummary {
  const factory HealthDataSummary({
    @JsonKey(name: 'sleep_duration_hours') double? sleepDurationHours,
    @JsonKey(name: 'heart_rate_avg') int? heartRateAvg,
    @JsonKey(name: 'heart_rate_resting') int? heartRateResting,
    @JsonKey(name: 'heart_rate_variability') double? heartRateVariability,
    @JsonKey(name: 'step_count') int? stepCount,
    @JsonKey(name: 'active_minutes') int? activeMinutes,
  }) = _HealthDataSummary;

  factory HealthDataSummary.fromJson(Map<String, dynamic> json) =>
      _$HealthDataSummaryFromJson(json);
}

