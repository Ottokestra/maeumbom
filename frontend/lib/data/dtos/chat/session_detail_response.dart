import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_detail_response.freezed.dart';
part 'session_detail_response.g.dart';

@freezed
class SessionDetailResponse with _$SessionDetailResponse {
  const factory SessionDetailResponse({
    @JsonKey(name: 'session_id') required String sessionId,
    @JsonKey(name: 'user_id') required int userId,
    required Map<String, dynamic> metadata,
    @JsonKey(name: 'message_count') required int messageCount,
    required List<ChatMessage> messages,
  }) = _SessionDetailResponse;

  factory SessionDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$SessionDetailResponseFromJson(json);
}

@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    String? role, // "user" | "assistant"
    String? content,
    String? timestamp, // ISO format datetime string
    @JsonKey(name: 'created_at') String? createdAt, // For backward compatibility
    @JsonKey(name: 'message_id') int? messageId,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
}

