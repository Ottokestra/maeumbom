import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../config/dev_flags.dart';
import '../../data/onboarding/onboarding_survey_repository.dart';
import '../../data/onboarding/onboarding_survey_submit_request.dart';

/// "시작하기" 버튼 that submits the onboarding survey and proceeds to the
/// home/report screen.
class OnboardingFinishButton extends StatelessWidget {
  const OnboardingFinishButton({
    super.key,
    required this.repository,
    required this.request,
    required this.onNavigateHome,
    this.onError,
    this.label,
  });

  final OnboardingSurveyRepository repository;
  final OnboardingSurveySubmitRequest request;
  final VoidCallback onNavigateHome;
  final void Function(Object error)? onError;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        try {
          await repository.submit(request);
        } catch (e, st) {
          debugPrint('submitOnboardingSurvey error: $e\n$st');

          if (onError != null) {
            onError!(e);
          } else {
            final message = kOnboardingStubMode
                ? '테스트 모드: 오류가 발생했지만 계속 진행합니다.'
                : '오류: $e';

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
              ),
            );
          }
        } finally {
          onNavigateHome();
        }
      },
      child: Text(label ?? '시작하기'),
    );
  }
}
