import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../ui/app_ui.dart';
import '../../../providers/auth_provider.dart';

/// 홈 화면 헤더 섹션
///
/// 사용자 닉네임, 인사말, 설문 버튼을 표시합니다.
class HomeHeaderSection extends ConsumerWidget {
  const HomeHeaderSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final nickname = user?.nickname ?? '봄이';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 닉네임 인사
        Text(
          '$nickname님,',
          style: AppTypography.h1.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: AppSpacing.xxs),

        // 인사말 메시지
        Text(
          '오늘 하루도 응원해요!',
          style: AppTypography.h3.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        // 설문 버튼
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/menopause_survey'),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '나는 어떤 상태일까?',
                  style: AppTypography.body.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpacing.xxs),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
