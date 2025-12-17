import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../ui/app_ui.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/daily_mood_provider.dart';
import '../daily_mood_check_screen.dart';
import 'home_notice_banner.dart';

/// 홈 화면 헤더 섹션
///
/// 사용자 닉네임, 인사말, 설정 아이콘을 표시합니다.
class HomeHeaderSection extends ConsumerWidget {
  final Color contentColor;

  const HomeHeaderSection({
    super.key,
    this.contentColor = Colors.white,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final nickname = user?.nickname ?? '봄이';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 공지사항 배너
        const HomeNoticeBanner(),
        
        const SizedBox(height: AppSpacing.sm),
        
        // 2x3 그리드 레이아웃
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 왼쪽 열 (닉네임, 메시지, 버튼)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1행: 닉네임
                  Text(
                    '$nickname,',
                    style: AppTypography.h1.copyWith(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.xxs),
                  
                  // 2행: 인사말 메시지
                  Text(
                    '오늘 하루 어떠셨나요?',
                    style: AppTypography.h3.copyWith(
                      color: AppColors.textWhite,
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.sm),
                  
                  // 3행: 봄이와 대화하기 버튼
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/bomi');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.textWhite.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '봄이와 대화하기',
                            style: AppTypography.body.copyWith(
                              color: AppColors.textWhite,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: AppColors.textWhite,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: AppSpacing.sm),

            // 오른쪽 열 (캐릭터)
            Consumer(
              builder: (context, ref, child) {
                final dailyState = ref.watch(dailyMoodProvider);
                final currentEmotion = dailyState.selectedEmotion ?? EmotionId.joy;

                return SizedBox(
                  width: 100,
                  height: 100,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(3.14159), // 180도 좌우 반전 (π 라디안)
                    child: EmotionCharacter(
                      id: currentEmotion,
                      size: 100,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
