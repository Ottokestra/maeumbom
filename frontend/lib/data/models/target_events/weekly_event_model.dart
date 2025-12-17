import 'package:freezed_annotation/freezed_annotation.dart';

part 'weekly_event_model.freezed.dart';
part 'weekly_event_model.g.dart';

@freezed
class WeeklyEventModel with _$WeeklyEventModel {
  const factory WeeklyEventModel({
    @JsonKey(name: 'ID') int? id,
    @JsonKey(name: 'USER_ID') int? userId,
    @JsonKey(name: 'WEEK_START') DateTime? weekStart,
    @JsonKey(name: 'WEEK_END') DateTime? weekEnd,
    @JsonKey(name: 'TARGET_TYPE') String? targetType,
    @JsonKey(name: 'EVENTS_SUMMARY') @Default([]) List<Map<String, dynamic>> eventsSummary,
    @JsonKey(name: 'TOTAL_EVENTS') int? totalEvents,
    @JsonKey(name: 'TAGS') @Default([]) List<String> tags,
    @JsonKey(name: 'CREATED_AT') DateTime? createdAt,
    @JsonKey(name: 'UPDATED_AT') DateTime? updatedAt,
    // 감정 분포 데이터 - 백엔드 응답과 일치하도록 소문자 사용
    @JsonKey(name: 'EMOTION_DISTRIBUTION') @Default({}) Map<String, dynamic> emotionDistribution,
    @JsonKey(name: 'PRIMARY_EMOTION') String? primaryEmotion,
    @JsonKey(name: 'SENTIMENT_OVERALL') String? sentimentOverall,
  }) = _WeeklyEventModel;

  factory WeeklyEventModel.fromJson(Map<String, dynamic> json) =>
      _$WeeklyEventModelFromJson(json);
}
