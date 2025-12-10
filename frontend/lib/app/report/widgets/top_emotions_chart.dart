import 'package:flutter/material.dart';

import '../../../data/dtos/report/user_report_response.dart';
import '../../../ui/app_ui.dart';

class TopEmotionsChart extends StatelessWidget {
  const TopEmotionsChart({
    super.key,
    required this.emotions,
  });

  final List<TopEmotionItem> emotions;

  @override
  Widget build(BuildContext context) {
    if (emotions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text(
          '최근 감정 데이터가 아직 없어요.',
          style: AppTypography.body.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    final maxRatio = emotions.map((e) => e.ratio).fold<double>(0, (a, b) {
      return b > a ? b : a;
    });

    return Column(
      children: emotions.map((emotion) {
        return _EmotionBar(
          label: emotion.label,
          ratio: emotion.ratio,
          count: emotion.count,
          maxRatio: maxRatio == 0 ? 1 : maxRatio,
        );
      }).toList(),
    );
  }
}

class _EmotionBar extends StatelessWidget {
  const _EmotionBar({
    required this.label,
    required this.ratio,
    required this.count,
    required this.maxRatio,
  });

  final String label;
  final double ratio;
  final int count;
  final double maxRatio;

  @override
  Widget build(BuildContext context) {
    final percentage = (ratio * 100).clamp(0, 100);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTypography.bodyBold,
              ),
              Text(
                '${percentage.toStringAsFixed(0)}% · ${count}회',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          LayoutBuilder(
            builder: (context, constraints) {
              final normalizedRatio = ratio / maxRatio;
              final barWidth = constraints.maxWidth * normalizedRatio;

              return Stack(
                children: [
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 12,
                    width: barWidth,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.accentRed, AppColors.accentCoral],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
