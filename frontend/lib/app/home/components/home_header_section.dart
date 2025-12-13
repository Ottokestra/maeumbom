import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../ui/app_ui.dart';
import '../../../providers/auth_provider.dart';
import '../daily_mood_check_screen.dart';

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
        // 닉네임과 설정 아이콘
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 닉네임 인사
            Text(
              '$nickname,',
              style: AppTypography.h1.copyWith(
                color: contentColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            // 설정 아이콘
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/home_new'),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.settings,
                  size: 24,
                  color: contentColor,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.xxs),

        // 인사말 메시지
        Text(
          '오늘 하루도 응원해!',
          style: AppTypography.h3.copyWith(
            color: contentColor.withValues(alpha: 0.7),
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // 기분 체크 버튼
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DailyMoodCheckScreen(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: contentColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.favorite_rounded,
                  size: 14,
                  color: contentColor,
                ),
                const SizedBox(width: 6),
                Text(
                  '기분 기록하기',
                  style: AppTypography.bodySmall.copyWith(
                    color: contentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
