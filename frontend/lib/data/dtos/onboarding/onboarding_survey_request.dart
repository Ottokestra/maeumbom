import 'package:freezed_annotation/freezed_annotation.dart';

part 'onboarding_survey_request.freezed.dart';
part 'onboarding_survey_request.g.dart';

@freezed
class OnboardingSurveyRequest with _$OnboardingSurveyRequest {
  const factory OnboardingSurveyRequest({
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
    @Default([]) List<String> atmosphere,
  }) = _OnboardingSurveyRequest;

  factory OnboardingSurveyRequest.fromJson(Map<String, dynamic> json) =>
      _$OnboardingSurveyRequestFromJson(json);
}

