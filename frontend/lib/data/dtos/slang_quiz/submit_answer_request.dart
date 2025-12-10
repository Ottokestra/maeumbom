import 'package:freezed_annotation/freezed_annotation.dart';

part 'submit_answer_request.freezed.dart';
part 'submit_answer_request.g.dart';

@freezed
class SubmitAnswerRequest with _$SubmitAnswerRequest {
  const factory SubmitAnswerRequest({
    @JsonKey(name: 'question_number') required int questionNumber,
    @JsonKey(name: 'user_answer_index') required int userAnswerIndex,
    @JsonKey(name: 'response_time_seconds') required int responseTimeSeconds,
  }) = _SubmitAnswerRequest;

  factory SubmitAnswerRequest.fromJson(Map<String, dynamic> json) =>
      _$SubmitAnswerRequestFromJson(json);
}

