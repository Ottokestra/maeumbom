// lib/data/dtos/menopause/menopause_survey_request.dart

import 'package:json_annotation/json_annotation.dart';

part 'menopause_survey_request.g.dart';

@JsonEnum(alwaysCreate: true)
enum MenopauseGender {
  @JsonValue('FEMALE')
  female,

  @JsonValue('MALE')
  male,
}

@JsonSerializable()
class MenopauseSurveyRequest {
  final MenopauseGender gender;
  final List<MenopauseAnswerItem> answers;

  MenopauseSurveyRequest({
    required this.gender,
    required this.answers,
  });

  factory MenopauseSurveyRequest.fromJson(Map<String, dynamic> json)
    => _$MenopauseSurveyRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MenopauseSurveyRequestToJson(this);
}

@JsonSerializable()
class MenopauseAnswerItem {
  @JsonKey(name: 'question_id')
  final int questionId;

  @JsonKey(name: 'answer_value')
  final int answerValue;

  MenopauseAnswerItem({
    required this.questionId,
    required this.answerValue,
  });

  factory MenopauseAnswerItem.fromJson(Map<String, dynamic> json)
    => _$MenopauseAnswerItemFromJson(json);

  Map<String, dynamic> toJson() => _$MenopauseAnswerItemToJson(this);
}
