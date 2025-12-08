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
          onNavigateHome();
        } catch (e, st) {
          if (kOnboardingStubMode) {
            debugPrint('Onboarding submit error (stub mode): $e');
            debugPrint('$st');
            onNavigateHome();
          } else {
            if (onError != null) {
              onError!(e);
              return;
            }

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('프로필을 찾을 수 없습니다.'),
              ),
            );
          }
        }
      },
      child: Text(label ?? '시작하기'),
    );
  }
}
