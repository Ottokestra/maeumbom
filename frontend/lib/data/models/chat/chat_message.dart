import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';

@freezed
class ChatMessage with _$ChatMessage {
  const ChatMessage._();

  const factory ChatMessage({
    required String id,
    required String text,
    required bool isUser,
    required DateTime timestamp,
    Map<String, dynamic>? meta,
  }) = _ChatMessage;

  /// response_type 편의 getter
  String? get responseType => meta?['response_type'] as String?;

  /// emotion 편의 getter
  String? get emotion => meta?['emotion'] as String?;

  /// alarm_info 편의 getter
  Map<String, dynamic>? get alarmInfo =>
      meta?['alarm_info'] as Map<String, dynamic>?;
}
