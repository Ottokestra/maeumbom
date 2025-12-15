import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../ui/app_ui.dart';
import '../../../providers/daily_mood_provider.dart';
import '../../../core/services/navigation/navigation_service.dart';
import '../../../core/utils/emotion_classifier.dart';
import '../../../core/utils/mood_color_helper.dart';

/// Home Main Buttons - 2x3 Grid Layout
/// 첫 번째 셀: 사용자 감정 캐릭터
/// 나머지 5개: 기능 버튼 (봄이와 대화, 기억 서랍, 마음리포트, 마음연습실, 신조어퀴즈)
class HomeMainButtons extends ConsumerWidget {
  const HomeMainButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyState = ref.watch(dailyMoodProvider);
    final navigationService = NavigationService(context, ref);

    // 현재 감정 가져오기 (기본값: 기쁨)
    final currentEmotion = dailyState.selectedEmotion ?? EmotionId.joy;
    
    // Mood 카테고리 가져오기
    final moodCategory = EmotionClassifier.classify(currentEmotion);
    
    // 메인 컬러와 bg 컬러 가져오기
    final moodMainColor = MoodColorHelper.getBackgroundColor(moodCategory); // 메인 컬러 (진한색)
    final moodBgColor = MoodColorHelper.getSecondaryColor(moodCategory); // bg 컬러 (연한색)

    // 그리드 아이템 정의
    final gridItems = _buildGridItems(navigationService, moodMainColor, moodBgColor);

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.3,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        // 첫 번째 셀: 캐릭터 표시
        if (index == 0) {
          return _buildCharacterCell(currentEmotion);
        }

        // 나머지 셀: 기능 버튼
        final item = gridItems[index - 1];
        return _buildFunctionButton(
          context: context,
          item: item,
        );
      },
    );
  }

  /// 그리드 아이템 리스트 생성 (5개)
  List<_GridItem> _buildGridItems(NavigationService navigationService, Color moodMainColor, Color moodBgColor) {
    return [
      _GridItem(
        title: '봄이와 대화',
        subtitle: '내가 다 들어줄게!',
        icon: Icons.mic, // 마이크 아이콘으로 변경
        onTap: () => navigationService.navigateToRoute('/bomi'),
        useMoodColor: true, // mood 색상 사용
        moodMainColor: moodBgColor,
        moodBgColor: moodMainColor,
      ),
      _GridItem(
        title: '기억 서랍',
        subtitle: '봄이가 기억해줄게!',
        icon: Icons.folder_outlined,
        onTap: () => navigationService.navigateToRoute('/alarm'),
        iconColor: const Color(0xFFFF7A5C),
      ),
      _GridItem(
        title: '마음리포트',
        subtitle: "한 주의 감정 요약.\n확인해볼까?",
        icon: Icons.assessment_outlined,
        onTap: () => navigationService.navigateToRoute('/report'),
        iconColor: const Color(0xFFFFA726),
      ),
      _GridItem(
        title: '마음연습실',
        subtitle: '관계 개선\n테스트해볼래?',
        icon: Icons.self_improvement,
        onTap: () => navigationService.navigateToRoute('/training'),
        iconColor: const Color(0xFF42A5F5),
      ),
      _GridItem(
        title: '신조어퀴즈',
        subtitle: '요즘 애들이\n많이 쓰는 말은?',
        icon: Icons.quiz_outlined,
        onTap: () => navigationService.navigateToRoute('/training/slang-quiz/start'),
        iconColor: const Color(0xFFAB47BC),
      ),
    ];
  }

  /// 캐릭터 표시 셀
  Widget _buildCharacterCell(EmotionId currentEmotion) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxs),
      decoration: BoxDecoration(
        color: Colors.transparent, // 투명 배경
      ),
      child: Center(
        child: EmotionCharacter(
          id: currentEmotion,
          size: 120,
          use2d: false,
        ),
      ),
    );
  }

  /// 기능 버튼 셀
  Widget _buildFunctionButton({
    required BuildContext context,
    required _GridItem item,
  }) {
    // 감정 색상 사용 여부에 따른 색상 설정
    final Color backgroundColor;
    final Color textColor;
    final Color subtitleColor;
    final Color iconColor;

    if (item.useMoodColor && item.moodMainColor != null) {
      // mood 색상 사용: 배경은 흰색, 아이콘은 메인 컬러
      backgroundColor = AppColors.basicColor; // 흰색 배경으로 화면 배경과 구분
      textColor = AppColors.textPrimary;
      subtitleColor = AppColors.textPrimary.withValues(alpha: 0.8);
      iconColor = item.moodMainColor!; // 메인 컬러로 강조
    } else if (item.isPrimary) {
      // 기존 primaryColor 사용
      backgroundColor = AppColors.primaryColor;
      textColor = AppColors.basicColor;
      subtitleColor = AppColors.basicColor.withValues(alpha: 0.9);
      iconColor = AppColors.basicColor;
    } else {
      // 기본 흰색 배경
      backgroundColor = AppColors.basicColor;
      textColor = AppColors.textPrimary;
      subtitleColor = AppColors.textSecondary;
      iconColor = item.iconColor ?? AppColors.primaryColor;
    }

    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 아이콘 (오른쪽 정렬)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.useMoodColor && item.moodMainColor != null
                        ? item.moodMainColor!.withValues(alpha: 0.15)
                        : item.isPrimary
                            ? AppColors.basicColor.withValues(alpha: 0.2)
                            : iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.icon,
                    color: iconColor,
                    size: AppTypography.bodyLarge.fontSize,
                  ),
                ),
              ],
            ),
            // 타이틀
            Text(
              item.title,
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            if (item.subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                item.subtitle!,
                style: AppTypography.caption.copyWith(
                  color: subtitleColor,
                  height: 1.0,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 그리드 아이템 데이터 모델
class _GridItem {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;
  final Color? iconColor;
  final bool useMoodColor; // mood 색상 사용 여부
  final Color? moodMainColor; // mood 메인 색상 (아이콘용)
  final Color? moodBgColor; // mood 배경 색상 (버튼 배경용)

  const _GridItem({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
    this.iconColor,
    this.useMoodColor = false,
    this.moodMainColor,
    this.moodBgColor,
  });
}
