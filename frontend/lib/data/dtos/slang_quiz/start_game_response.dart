import 'package:freezed_annotation/freezed_annotation.dart';

part 'start_game_response.freezed.dart';
part 'start_game_response.g.dart';

@freezed
class StartGameResponse with _$StartGameResponse {
  const factory StartGameResponse({
    @JsonKey(name: 'game_id') required int gameId,
    @JsonKey(name: 'total_questions') required int totalQuestions,
    @JsonKey(name: 'current_question') required int currentQuestion,
    required QuestionData question,
  }) = _StartGameResponse;

  factory StartGameResponse.fromJson(Map<String, dynamic> json) =>
      _$StartGameResponseFromJson(json);
}

@freezed
class QuestionData with _$QuestionData {
  const factory QuestionData({
    @JsonKey(name: 'question_number') required int questionNumber,
    required String word,
    required String question,
    required List<String> options,
    @JsonKey(name: 'time_limit') required int timeLimit,
  }) = _QuestionData;

  factory QuestionData.fromJson(Map<String, dynamic> json) =>
      _$QuestionDataFromJson(json);
}

