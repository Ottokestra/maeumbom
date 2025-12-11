// lib/data/dtos/menopause/menopause_question_response.dart

import 'package:json_annotation/json_annotation.dart';

part 'menopause_question_response.g.dart';

@JsonSerializable()
class MenopauseQuestionResponse {
  @JsonKey(name: 'ID')
  final int id;

  @JsonKey(name: 'GENDER')
  final String gender;

  @JsonKey(name: 'CODE')
  final String code;

  @JsonKey(name: 'ORDER_NO')
  final int orderNo;

  @JsonKey(name: 'QUESTION_TEXT')
  final String questionText;

  @JsonKey(name: 'POSITIVE_LABEL')
  final String positiveLabel;

  @JsonKey(name: 'NEGATIVE_LABEL')
  final String negativeLabel;

  @JsonKey(name: 'CHARACTER_KEY')
  final String? characterKey;

  MenopauseQuestionResponse({
    required this.id,
    required this.gender,
    required this.code,
    required this.orderNo,
    required this.questionText,
    required this.positiveLabel,
    required this.negativeLabel,
    this.characterKey,
  });

  factory MenopauseQuestionResponse.fromJson(Map<String, dynamic> json) =>
      _$MenopauseQuestionResponseFromJson(json);
}
