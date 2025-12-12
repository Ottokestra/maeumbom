import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../ui/app_ui.dart';
import '../../../../providers/daily_mood_provider.dart';
import '../daily_mood_check_screen.dart';

class DailyMoodCheckWidget extends ConsumerWidget {
  const DailyMoodCheckWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyState = ref.watch(dailyMoodProvider);

    return GestureDetector(
      onTap: dailyState.hasChecked
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DailyMoodCheckScreen(),
                ),
              );
            },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.bgBasic,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              dailyState.hasChecked ? '오늘의 감정 체크 완료!' : '오늘의 감정 캐릭터 선택',
              style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            if (dailyState.hasChecked &&
                dailyState.selectedEmotion != null) ...[
              EmotionCharacter(
                id: dailyState.selectedEmotion!,
                size: 80,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                emotionMetaMap[dailyState.selectedEmotion!]!.nameKo,
                style: AppTypography.body.copyWith(
                  color: AppColors.secondaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ] else ...[
              const Icon(
                Icons.touch_app_rounded,
                size: 48,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '기분을 나타내는 캐릭터를 선택해주세요',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
