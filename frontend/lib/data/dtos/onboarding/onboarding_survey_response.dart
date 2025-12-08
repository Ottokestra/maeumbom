import 'package:freezed_annotation/freezed_annotation.dart';

part 'onboarding_survey_response.freezed.dart';
part 'onboarding_survey_response.g.dart';

@freezed
class OnboardingSurveyResponse with _$OnboardingSurveyResponse {
  const factory OnboardingSurveyResponse({
    required int id,
    @JsonKey(name: 'user_id') required int userId,
    required String nickname,
    @JsonKey(name: 'age_group') required String ageGroup,
    required String gender,
    @JsonKey(name: 'marital_status') required String maritalStatus,
    @JsonKey(name: 'children_yn') required String childrenYn,
    @JsonKey(name: 'living_with') required List<String> livingWith,
    @JsonKey(name: 'personality_type') required String personalityType,
    @JsonKey(name: 'activity_style') required String activityStyle,
    @JsonKey(name: 'stress_relief') required List<String> stressRelief,
    required List<String> hobbies,
    required List<String> atmosphere,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
  }) = _OnboardingSurveyResponse;

  factory OnboardingSurveyResponse.fromJson(Map<String, dynamic> json) =>
      _$OnboardingSurveyResponseFromJson(json);
}

