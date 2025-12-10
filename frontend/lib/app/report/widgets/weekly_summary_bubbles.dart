import 'package:flutter/material.dart';

import '../../../data/report/models/weekly_emotion_report.dart';
import '../../../ui/app_ui.dart';

class WeeklySummaryBubbles extends StatelessWidget {
  const WeeklySummaryBubbles({
    super.key,
    required this.summaryBubbles,
  });

  final List<SummaryBubble> summaryBubbles;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '이번 주 대화 요약',
          style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (summaryBubbles.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.bgWarm,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Text(
              '이번 주 대화 기록이 아직 없어요. 봄이와 대화를 시작해보세요!',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final bubble = summaryBubbles[index];
              return _SummaryBubbleTile(bubble: bubble);
            },
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
            itemCount: summaryBubbles.length,
          ),
      ],
    );
  }
}

class _SummaryBubbleTile extends StatelessWidget {
  const _SummaryBubbleTile({required this.bubble});

  final SummaryBubble bubble;

  @override
  Widget build(BuildContext context) {
    final isUser = bubble.role == 'user';
    final alignment =
        isUser ? MainAxisAlignment.start : MainAxisAlignment.end;
    final bubbleColor = isUser
        ? AppColors.pureWhite
        : AppColors.accentRed.withOpacity(0.08);
    final borderColor = isUser
        ? AppColors.borderLight
        : AppColors.accentRed.withOpacity(0.2);

    return Row(
      mainAxisAlignment: alignment,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(AppRadius.lg),
                topRight: const Radius.circular(AppRadius.lg),
                bottomLeft: Radius.circular(
                  isUser ? AppRadius.lg : AppRadius.sm,
                ),
                bottomRight: Radius.circular(
                  isUser ? AppRadius.sm : AppRadius.lg,
                ),
              ),
              border: Border.all(color: borderColor),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.accentRedShadow,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Text(
                  bubble.emotionLabel,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  bubble.text,
                  style: AppTypography.body,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
