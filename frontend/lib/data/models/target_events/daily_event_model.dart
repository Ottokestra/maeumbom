import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_event_model.freezed.dart';
part 'daily_event_model.g.dart';

/// 일일 이벤트 모델
/// 백엔드 DailyEventResponse와 매칭
@freezed
class DailyEventModel with _$DailyEventModel {
  const factory DailyEventModel({
    required int id,
    @JsonKey(name: 'user_id') required int userId,
    @JsonKey(name: 'event_date') required DateTime eventDate,
    @JsonKey(name: 'event_type') required String eventType, // alarm/event/memory
    @JsonKey(name: 'target_type') required String targetType, // husband/son/daughter 등
    @JsonKey(name: 'event_summary') required String eventSummary,
    @JsonKey(name: 'event_time') DateTime? eventTime,
    required int importance,
    @JsonKey(name: 'is_future_event') required bool isFutureEvent,
    @Default([]) List<String> tags,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _DailyEventModel;

  factory DailyEventModel.fromJson(Map<String, dynamic> json) =>
      _$DailyEventModelFromJson(json);
}
