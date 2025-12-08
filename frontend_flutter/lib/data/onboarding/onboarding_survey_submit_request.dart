/// Request model representing the onboarding survey answers.
class OnboardingSurveySubmitRequest {
  OnboardingSurveySubmitRequest({
    required this.userId,
    required this.answers,
  });

  final String userId;
  final Map<String, dynamic> answers;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'answers': answers,
      };
}
