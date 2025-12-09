import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../ui/app_ui.dart';
import '../../../../core/services/navigation/navigation_service.dart';

class HomeMenuGrid extends ConsumerWidget {
  const HomeMenuGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationService = NavigationService(context, ref);

    final menus = [
      _MenuData(
        title: '봄이 채팅',
        emotionId: EmotionId.joy,
        onTap: () => navigationService.navigateToRoute('/bomi'),
      ),
      _MenuData(
        title: '똑똑 알람',
        emotionId: EmotionId.enlightenment,
        onTap: () => navigationService.navigateToRoute('/alarm'),
      ),
      _MenuData(
        title: '마음리포트',
        emotionId: EmotionId.interest,
        onTap: () => navigationService.navigateToRoute('/report'),
      ),
      _MenuData(
        title: '마음연습실',
        emotionId: EmotionId.relief,
        onTap: () => navigationService.navigateToRoute('/training'),
      ),
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.1, // 정사각형 비율 (오버플로우 방지를 위해 높이 확보)
      ),
      itemCount: menus.length,
      itemBuilder: (context, index) {
        final menu = menus[index];
        return _buildMenuCard(context, menu);
      },
    );
  }

  Widget _buildMenuCard(BuildContext context, _MenuData menu) {
    return GestureDetector(
      onTap: menu.onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.bgBasic,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 타이틀 (위, 왼쪽 정렬)
            Text(
              menu.title,
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            // 캐릭터 이미지 (아래, 오른쪽 정렬)
            Align(
              alignment: Alignment.bottomRight,
              child: EmotionCharacter(
                id: menu.emotionId,
                size: 60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuData {
  final String title;
  final EmotionId emotionId;
  final VoidCallback onTap;

  _MenuData({
    required this.title,
    required this.emotionId,
    required this.onTap,
  });
}
