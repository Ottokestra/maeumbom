import 'package:freezed_annotation/freezed_annotation.dart';
import '../../models/target_events/daily_event_model.dart';

part 'analyze_daily_response.freezed.dart';
part 'analyze_daily_response.g.dart';

/// 일일 분석 응답 DTO
@freezed
class AnalyzeDailyResponse with _$AnalyzeDailyResponse {
  const factory AnalyzeDailyResponse({
    @JsonKey(name: 'analyzed_date') required DateTime analyzedDate,
    @JsonKey(name: 'events_count') required int eventsCount,
    required List<DailyEventModel> events,
  }) = _AnalyzeDailyResponse;

  factory AnalyzeDailyResponse.fromJson(Map<String, dynamic> json) =>
      _$AnalyzeDailyResponseFromJson(json);
}
