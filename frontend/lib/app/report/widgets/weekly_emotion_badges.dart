import 'package:flutter/material.dart';

import '../../../data/report/models/weekly_emotion_report.dart';
import '../../../ui/app_ui.dart';

class WeeklyEmotionBadges extends StatelessWidget {
  const WeeklyEmotionBadges({
    super.key,
    required this.badge,
    required this.mainEmotion,
  });

  final EmotionBadge badge;
  final MainEmotion mainEmotion;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '이번 주 감정 뱃지',
          style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.bgWarm,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _BadgePill(text: badge.code),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      badge.label,
                      style: AppTypography.h3.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                badge.description,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Divider(color: AppColors.borderLight),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '대표 감정',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.bgLightPink,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: const Icon(
                      Icons.emoji_emotions_outlined,
                      color: AppColors.accentRed,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mainEmotion.label,
                          style: AppTypography.bodyBold,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '신뢰도 ${(mainEmotion.confidence * 100).toStringAsFixed(0)}%',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BadgePill extends StatelessWidget {
  const _BadgePill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.accentRed.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.accentRed.withOpacity(0.12)),
      ),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(
          color: AppColors.accentRed,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
