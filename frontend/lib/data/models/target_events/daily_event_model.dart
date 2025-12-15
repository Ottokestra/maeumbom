import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_event_model.freezed.dart';
part 'daily_event_model.g.dart';

/// 일일 이벤트 모델
/// 백엔드 DailyEventResponse와 매칭
@freezed
class DailyEventModel with _$DailyEventModel {
  const factory DailyEventModel({
    @JsonKey(name: 'ID') required int id,
    @JsonKey(name: 'USER_ID') required int userId,
    @JsonKey(name: 'EVENT_DATE') required DateTime eventDate,
    @JsonKey(name: 'EVENT_TYPE') required String eventType, // alarm/event/memory
    @JsonKey(name: 'TARGET_TYPE') required String targetType, // husband/son/daughter 등
    @JsonKey(name: 'EVENT_SUMMARY') required String eventSummary,
    @JsonKey(name: 'EVENT_TIME') DateTime? eventTime,
    @JsonKey(name: 'IMPORTANCE', defaultValue: 3) int? importance,
    @JsonKey(name: 'IS_FUTURE_EVENT') required bool isFutureEvent,
    @JsonKey(name: 'TAGS', defaultValue: []) List<String>? tags,
    @JsonKey(name: 'CREATED_AT') required DateTime createdAt,
    @JsonKey(name: 'UPDATED_AT') required DateTime updatedAt,
  }) = _DailyEventModel;

  factory DailyEventModel.fromJson(Map<String, dynamic> json) =>
      _$DailyEventModelFromJson(json);
}
