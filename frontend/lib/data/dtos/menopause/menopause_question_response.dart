// lib/data/dtos/menopause/menopause_question_response.dart

import 'package:json_annotation/json_annotation.dart';

part 'menopause_question_response.g.dart';

@JsonSerializable()
class MenopauseQuestionResponse {
  @JsonKey(name: 'id')
  final int id;

  @JsonKey(name: 'gender')
  final String gender;

  @JsonKey(name: 'code')
  final String code;

  @JsonKey(name: 'order_no')
  final int orderNo;

  @JsonKey(name: 'question_text')
  final String questionText;

  @JsonKey(name: 'positive_label')
  final String positiveLabel;

  @JsonKey(name: 'negative_label')
  final String negativeLabel;

  @JsonKey(name: 'character_key')
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
