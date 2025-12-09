import 'package:freezed_annotation/freezed_annotation.dart';
import 'weekday_pattern.dart';
import 'weekend_pattern.dart';

part 'user_pattern_response.freezed.dart';
part 'user_pattern_response.g.dart';

@freezed
class UserPatternResponse with _$UserPatternResponse {
  const factory UserPatternResponse({
    required WeekdayPattern weekday,
    WeekendPattern? weekend, // 주말 데이터가 있을 때만
    @JsonKey(name: 'last_analysis_date') String? lastAnalysisDate,
    @JsonKey(name: 'data_completeness') double? dataCompleteness,
    @JsonKey(name: 'analysis_period_days') required int analysisPeriodDays,
    String? insight,
  }) = _UserPatternResponse;

  factory UserPatternResponse.fromJson(Map<String, dynamic> json) =>
      _$UserPatternResponseFromJson(json);
}

