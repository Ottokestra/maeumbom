import 'package:freezed_annotation/freezed_annotation.dart';

part 'weekly_event_model.freezed.dart';
part 'weekly_event_model.g.dart';

@freezed
class WeeklyEventModel with _$WeeklyEventModel {
  const factory WeeklyEventModel({
    @JsonKey(name: 'ID') required int id,
    @JsonKey(name: 'USER_ID') required int userId,
    @JsonKey(name: 'WEEK_START') required DateTime weekStart,
    @JsonKey(name: 'WEEK_END') required DateTime weekEnd,
    @JsonKey(name: 'TARGET_TYPE') required String targetType,
    @JsonKey(name: 'EVENTS_SUMMARY') @Default([]) List<Map<String, dynamic>> eventsSummary,
    @JsonKey(name: 'TOTAL_EVENTS') required int totalEvents,
    @JsonKey(name: 'TAGS') @Default([]) List<String> tags,
    @JsonKey(name: 'CREATED_AT') required DateTime createdAt,
    @JsonKey(name: 'UPDATED_AT') required DateTime updatedAt,
  }) = _WeeklyEventModel;

  factory WeeklyEventModel.fromJson(Map<String, dynamic> json) =>
      _$WeeklyEventModelFromJson(json);
}
