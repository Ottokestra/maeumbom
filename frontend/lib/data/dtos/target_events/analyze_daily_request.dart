import 'package:freezed_annotation/freezed_annotation.dart';

part 'analyze_daily_request.freezed.dart';
part 'analyze_daily_request.g.dart';

/// 일일 분석 요청 DTO
@freezed
class AnalyzeDailyRequest with _$AnalyzeDailyRequest {
  const factory AnalyzeDailyRequest({
    @JsonKey(name: 'target_date') required DateTime targetDate,
  }) = _AnalyzeDailyRequest;

  factory AnalyzeDailyRequest.fromJson(Map<String, dynamic> json) =>
      _$AnalyzeDailyRequestFromJson(json);
}
