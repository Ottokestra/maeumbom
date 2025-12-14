import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/common/onboarding/onboarding_survey_controller.dart';
import '../core/services/api_client.dart';
import '../data/api/onboarding/onboarding_survey_api_client.dart';
import '../data/repository/onboarding/onboarding_survey_repository.dart';
import 'api_client_provider.dart';

final onboardingSurveyApiClientProvider =
    Provider<OnboardingSurveyApiClient>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OnboardingSurveyApiClient(apiClient);
});

final onboardingSurveyRepositoryProvider =
    Provider<OnboardingSurveyRepository>((ref) {
  final apiClient = ref.watch(onboardingSurveyApiClientProvider);
  return OnboardingSurveyRepository(apiClient);
});

final onboardingSurveyControllerProvider =
    ChangeNotifierProvider<OnboardingSurveyController>((ref) {
  final repository = ref.watch(onboardingSurveyRepositoryProvider);
  return OnboardingSurveyController(repository);
});
