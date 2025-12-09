import 'package:json_annotation/json_annotation.dart';

part 'menopause_survey_response.g.dart';

/// 위험도 등급 (LOW / MID / HIGH)
@JsonEnum(alwaysCreate: true)
enum MenopauseRiskLevel {
  @JsonValue('LOW')
  low,

  @JsonValue('MID')
  mid,

  @JsonValue('HIGH')
  high,
}

/// 갱년기 설문 응답 Response
///
/// JSON 예시:
/// {
///   "id": 123,
///   "total_score": 17,
///   "risk_level": "MID",
///   "comment": "갱년기 관련 신호가 보입니다..."
/// }
@JsonSerializable()
class MenopauseSurveyResponse {
  final int id;

  @JsonKey(name: 'total_score')
  final int totalScore;

  @JsonKey(name: 'risk_level')
  final MenopauseRiskLevel riskLevel;

  final String comment;

  MenopauseSurveyResponse({
    required this.id,
    required this.totalScore,
    required this.riskLevel,
    required this.comment,
  });

  factory MenopauseSurveyResponse.fromJson(Map<String, dynamic> json) =>
      _$MenopauseSurveyResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MenopauseSurveyResponseToJson(this);
}
