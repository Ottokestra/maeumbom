import 'package:freezed_annotation/freezed_annotation.dart';

part 'health_sync_request.freezed.dart';
part 'health_sync_request.g.dart';

@freezed
class HealthSyncRequest with _$HealthSyncRequest {
  const factory HealthSyncRequest({
    @JsonKey(name: 'log_date') required String logDate,
    @JsonKey(name: 'sleep_start_time') String? sleepStartTime,
    @JsonKey(name: 'sleep_end_time') String? sleepEndTime,
    @JsonKey(name: 'step_count') int? stepCount,
    @JsonKey(name: 'sleep_duration_hours') double? sleepDurationHours,
    @JsonKey(name: 'heart_rate_avg') int? heartRateAvg,
    @JsonKey(name: 'heart_rate_resting') int? heartRateResting,
    @JsonKey(name: 'heart_rate_variability') double? heartRateVariability,
    @JsonKey(name: 'active_minutes') int? activeMinutes,
    @JsonKey(name: 'exercise_minutes') int? exerciseMinutes,
    @JsonKey(name: 'calories_burned') int? caloriesBurned,
    @JsonKey(name: 'distance_km') double? distanceKm,
    @JsonKey(name: 'source_type') required String sourceType,
    @JsonKey(name: 'raw_data') Map<String, dynamic>? rawData,
  }) = _HealthSyncRequest;

  factory HealthSyncRequest.fromJson(Map<String, dynamic> json) =>
      _$HealthSyncRequestFromJson(json);
}

