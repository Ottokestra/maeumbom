import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/dtos/menopause/menopause_survey_response.dart';
import '../../ui/characters/app_characters.dart';
import '../../ui/components/app_button.dart';
import '../../ui/components/buttons.dart';
import '../../ui/tokens/colors.dart';
import '../../ui/tokens/typography.dart';

class MenopauseDiagnosisResultScreen extends ConsumerWidget {
  final MenopauseSurveyResponse result;

  const MenopauseDiagnosisResultScreen({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Map Risk Level to Emotion & Color
    final (emotionId, riskColor, riskLabel) = _getRiskAttributes(result.riskLevel.name);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('진단 결과'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Hide back button
        titleTextStyle: AppTypography.h3.copyWith(color: Colors.black),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              
              // 1. Header Text
              Text(
                '나의 갱년기 건강 상태는?',
                style: AppTypography.h2.copyWith(
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // 2. Character
              Center(
                child: EmotionCharacter(
                  id: emotionId,
                  size: 180,
                  use2d: false,
                ),
              ),
              const SizedBox(height: 40),

              // 3. Result Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: riskColor.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      riskLabel,
                      style: AppTypography.h3.copyWith(
                        color: riskColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '총점 ${result.totalScore}점',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      result.comment,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // 4. Confirm Button
              AppButton(
                text: '확인',
                variant: ButtonVariant.primaryRed,
                onTap: () {
                  // Pop until home or appropriate screen
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  (EmotionId, Color, String) _getRiskAttributes(String riskLevel) {
    switch (riskLevel.toUpperCase()) {
      case 'LOW':
        return (
          EmotionId.relief,
          AppColors.natureGreen,
          '양호',
        );
      case 'MID':
        return (
          EmotionId.sadness,
          AppColors.homeGoodYellow, // Use yellow/orange for Warning
          '주의',
        );
      case 'HIGH':
        return (
          EmotionId.fear,
          AppColors.accentRed,
          '관리 필요',
        );
      default:
        return (
          EmotionId.confusion,
          AppColors.textSecondary,
          '분석 불가',
        );
    }
  }
}
