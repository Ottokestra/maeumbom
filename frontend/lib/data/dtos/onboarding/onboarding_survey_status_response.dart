import 'package:freezed_annotation/freezed_annotation.dart';
import 'onboarding_survey_response.dart';

part 'onboarding_survey_status_response.freezed.dart';
part 'onboarding_survey_status_response.g.dart';

@freezed
class OnboardingSurveyStatusResponse with _$OnboardingSurveyStatusResponse {
  const factory OnboardingSurveyStatusResponse({
    @JsonKey(name: 'has_profile') required bool hasProfile,
    OnboardingSurveyResponse? profile,
  }) = _OnboardingSurveyStatusResponse;

  factory OnboardingSurveyStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$OnboardingSurveyStatusResponseFromJson(json);
}

