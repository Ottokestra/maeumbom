import 'package:freezed_annotation/freezed_annotation.dart';

part 'end_game_response.freezed.dart';
part 'end_game_response.g.dart';

@freezed
class EndGameResponse with _$EndGameResponse {
  const factory EndGameResponse({
    @JsonKey(name: 'game_id') required int gameId,
    @JsonKey(name: 'total_questions') required int totalQuestions,
    @JsonKey(name: 'correct_count') required int correctCount,
    @JsonKey(name: 'total_score') required int totalScore,
    @JsonKey(name: 'total_time_seconds') required int? totalTimeSeconds,
    @JsonKey(name: 'questions_summary') required List<QuestionSummary> questionsSummary,
  }) = _EndGameResponse;

  factory EndGameResponse.fromJson(Map<String, dynamic> json) =>
      _$EndGameResponseFromJson(json);
}

@freezed
class QuestionSummary with _$QuestionSummary {
  const factory QuestionSummary({
    @JsonKey(name: 'question_number') required int questionNumber,
    required String word,
    @JsonKey(name: 'is_correct') required bool? isCorrect,
    @JsonKey(name: 'earned_score') required int? earnedScore,
  }) = _QuestionSummary;

  factory QuestionSummary.fromJson(Map<String, dynamic> json) =>
      _$QuestionSummaryFromJson(json);
}

