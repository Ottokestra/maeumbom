import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';

@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String text,
    required bool isUser,
    required DateTime timestamp,
    Map<String, dynamic>? meta,
  }) = _ChatMessage;
}
