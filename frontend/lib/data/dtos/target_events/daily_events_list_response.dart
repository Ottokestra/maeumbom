import 'package:freezed_annotation/freezed_annotation.dart';
import '../../models/target_events/daily_event_model.dart';

part 'daily_events_list_response.freezed.dart';
part 'daily_events_list_response.g.dart';

/// 일일 이벤트 목록 응답 DTO
@freezed
class DailyEventsListResponse with _$DailyEventsListResponse {
  const factory DailyEventsListResponse({
    @JsonKey(name: 'daily_events') required List<DailyEventModel> dailyEvents,
    @JsonKey(name: 'total_count') required int totalCount,
    @JsonKey(name: 'available_tags') required Map<String, List<String>> availableTags,
  }) = _DailyEventsListResponse;

  factory DailyEventsListResponse.fromJson(Map<String, dynamic> json) =>
      _$DailyEventsListResponseFromJson(json);
}
