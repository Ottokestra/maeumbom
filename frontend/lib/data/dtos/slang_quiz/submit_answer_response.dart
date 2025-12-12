import 'package:freezed_annotation/freezed_annotation.dart';

part 'submit_answer_response.freezed.dart';
part 'submit_answer_response.g.dart';

@freezed
class SubmitAnswerResponse with _$SubmitAnswerResponse {
  const factory SubmitAnswerResponse({
    @JsonKey(name: 'is_correct') required bool isCorrect,
    @JsonKey(name: 'correct_answer_index') required int correctAnswerIndex,
    @JsonKey(name: 'earned_score') required int earnedScore,
    required String explanation,
    @JsonKey(name: 'reward_card') required RewardCard rewardCard,
  }) = _SubmitAnswerResponse;

  factory SubmitAnswerResponse.fromJson(Map<String, dynamic> json) =>
      _$SubmitAnswerResponseFromJson(json);
}

@freezed
class RewardCard with _$RewardCard {
  const factory RewardCard({
    required String message,
    @JsonKey(name: 'background_mood') required String backgroundMood,
  }) = _RewardCard;

  factory RewardCard.fromJson(Map<String, dynamic> json) =>
      _$RewardCardFromJson(json);
}

