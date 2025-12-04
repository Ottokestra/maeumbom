import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_session.freezed.dart';

@freezed
class ChatSession with _$ChatSession {
  const factory ChatSession({
    required String sessionId,
    required int userId,
    required DateTime createdAt,
    DateTime? lastMessageAt,
  }) = _ChatSession;
}
