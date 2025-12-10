import 'package:freezed_annotation/freezed_annotation.dart';

part 'text_chat_response.freezed.dart';
part 'text_chat_response.g.dart';

@freezed
class TextChatResponse with _$TextChatResponse {
  const factory TextChatResponse({
    @JsonKey(name: 'reply_text') required String replyText,
    @JsonKey(name: 'input_text') required String inputText,
    String? emotion, // ✅ sadness, happiness, anger, fear
    @JsonKey(name: 'response_type') String? responseType, // ✅ list, normal
    Map<String, dynamic>? meta,
  }) = _TextChatResponse;

  factory TextChatResponse.fromJson(Map<String, dynamic> json) =>
      _$TextChatResponseFromJson(json);
}
