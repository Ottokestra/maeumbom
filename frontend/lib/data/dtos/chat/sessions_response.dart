import 'package:freezed_annotation/freezed_annotation.dart';

part 'sessions_response.freezed.dart';
part 'sessions_response.g.dart';

@freezed
class SessionsResponse with _$SessionsResponse {
  const factory SessionsResponse({
    @JsonKey(name: 'user_id') required int userId,
    @JsonKey(name: 'session_count') required int sessionCount,
    required List<SessionItem> sessions,
  }) = _SessionsResponse;

  factory SessionsResponse.fromJson(Map<String, dynamic> json) =>
      _$SessionsResponseFromJson(json);
}

@freezed
class SessionItem with _$SessionItem {
  const factory SessionItem({
    @JsonKey(name: 'session_id') required String sessionId,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'message_count') required int messageCount,
  }) = _SessionItem;

  factory SessionItem.fromJson(Map<String, dynamic> json) =>
      _$SessionItemFromJson(json);
}

