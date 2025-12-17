import 'package:flutter/material.dart';
import '../../../ui/app_ui.dart';

/// 홈 화면 추천 카드 섹션
///
/// 기억서랍, 마음연습실, 신조어 퀴즈 3개 기능 카드를 표시합니다.
class HomeRecommendationCards extends StatelessWidget {
  const HomeRecommendationCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 추천 카드들
        _buildRecommendationCard(
          context: context,
          icon: '💝',
          title: '감정 루틴 시작하기',
          description: '매일 감정을 기록하고 분석해보세요',
          onTap: () {
            Navigator.pushNamed(context, '/alarm');
          },
        ),

        const SizedBox(height: AppSpacing.sm),

        _buildRecommendationCard(
          context: context,
          icon: '💬',
          title: '마음연습실',
          description: '다양한 상황의 대화 방법을 연습해요',
          onTap: () {
            Navigator.pushNamed(context, '/training');
          },
        ),

        const SizedBox(height: AppSpacing.sm),

        _buildRecommendationCard(
          context: context,
          icon: '🎯',
          title: '신조어 퀴즈',
          description: '자녀의 신조어를 퀴즈로 배워보세요',
          onTap: () {
            Navigator.pushNamed(context, '/slang_quiz');
          },
        ),
      ],
    );
  }

  Widget _buildRecommendationCard({
    required BuildContext context,
    required String icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.lightPink,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단: 배지와 이모지
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 오늘의 추천 배지
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentCoral,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '오늘의 추천',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.basicColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                
                // 이모지
                Text(
                  icon,
                  style: const TextStyle(fontSize: 48),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.sm),
            
            // 제목
            Text(
              title,
              style: AppTypography.h3.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            
            const SizedBox(height: 4),
            
            // 설명
            Text(
              description,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            
            const SizedBox(height: AppSpacing.xs),
            
            // 화살표 링크
            Row(
              children: [
                Text(
                  '지금 바로 시작하기',
                  style: AppTypography.body.copyWith(
                    color: AppColors.accentCoral,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward,
                  color: AppColors.accentCoral,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
