import 'package:freezed_annotation/freezed_annotation.dart';

part 'text_chat_request.freezed.dart';
part 'text_chat_request.g.dart';

@freezed
class TextChatRequest with _$TextChatRequest {
  const factory TextChatRequest({
    @JsonKey(name: 'user_text') required String userText,
    @JsonKey(name: 'session_id') String? sessionId,
    @JsonKey(name: 'stt_quality') String? sttQuality,
    @JsonKey(name: 'tts_enabled') bool? ttsEnabled, // ✅ TTS 활성화 여부
  }) = _TextChatRequest;

  factory TextChatRequest.fromJson(Map<String, dynamic> json) =>
      _$TextChatRequestFromJson(json);
}
