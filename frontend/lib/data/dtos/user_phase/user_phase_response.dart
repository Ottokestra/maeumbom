import 'package:freezed_annotation/freezed_annotation.dart';
import 'health_data_summary.dart';

part 'user_phase_response.freezed.dart';
part 'user_phase_response.g.dart';

@freezed
class UserPhaseResponse with _$UserPhaseResponse {
  const factory UserPhaseResponse({
    @JsonKey(name: 'current_phase') required String currentPhase,
    @JsonKey(name: 'hours_since_wake') required double hoursSinceWake,
    @JsonKey(name: 'hours_to_sleep') double? hoursToSleep,
    @JsonKey(name: 'data_source') required String dataSource,
    required String message,
    @JsonKey(name: 'health_data') HealthDataSummary? healthData,
  }) = _UserPhaseResponse;

  factory UserPhaseResponse.fromJson(Map<String, dynamic> json) =>
      _$UserPhaseResponseFromJson(json);
}

