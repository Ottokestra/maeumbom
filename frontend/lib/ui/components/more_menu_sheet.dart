import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/ui/tokens/app_tokens.dart';
import '../../providers/auth_provider.dart';
import '../../providers/daily_mood_provider.dart';
import '../../core/utils/emotion_classifier.dart';
import '../characters/app_characters.dart';

/// 더보기 메뉴 BottomSheet
///
/// 네비게이션 단순화를 위해 부가 기능들을 모아둔 더보기 메뉴입니다.
/// - 알람 설정
/// - 리포트 보기
/// - 마이페이지
/// - 설정
/// - 도움말
///
/// 사용 예시:
/// ```dart
/// MoreMenuSheet.show(context);
/// ```
class MoreMenuSheet extends ConsumerWidget {
  const MoreMenuSheet({super.key});

  /// 사이드 메뉴 표시
  static void show(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height: MediaQuery.of(context).size.height,
              decoration: const BoxDecoration(
                color: AppColors.bgBasic,
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(AppRadius.lg),
                ),
              ),
              child: const MoreMenuSheet(),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final nickname = user?.nickname ?? '봄이';

    final dailyState = ref.watch(dailyMoodProvider);
    final currentEmotion = dailyState.selectedEmotion ?? EmotionId.joy;
    final moodCategory = EmotionClassifier.classify(currentEmotion);

    final menuItems = [
      _MenuItemData(
        icon: Icons.alarm,
        title: '똑똑 알람',
        onTap: () => _navigateToAlarm(context),
      ),
      _MenuItemData(
        icon: Icons.bar_chart,
        title: '마음연습실',
        onTap: () => _navigateToTraining(context),
      ),
      _MenuItemData(
        icon: Icons.assessment,
        title: '마음리포트',
        onTap: () => _navigateToReport(context),
      ),
      _MenuItemData(
        icon: Icons.person,
        title: '마이페이지',
        onTap: () => _navigateToMyPage(context),
      ),
      _MenuItemData(
        icon: Icons.settings,
        title: '설정',
        onTap: () => _navigateToSettings(context),
      ),
      _MenuItemData(
        icon: Icons.help,
        title: '도움말',
        onTap: () => _navigateToHelp(context),
      ),
    ];

    return Column(
      children: [
        // 상단 사용자 정보 영역
        _buildUserInfoSection(context, nickname, moodCategory),

        // 메뉴 리스트
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                ...menuItems.map((item) => _buildListMenuItem(
                      icon: item.icon,
                      title: item.title,
                      onTap: item.onTap,
                      moodCategory: moodCategory,
                    )),
                // 하단 여백 (홈 인디케이터 대응)
                SizedBox(
                    height:
                        MediaQuery.of(context).padding.bottom + AppSpacing.md),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 상단 사용자 정보 섹션
  Widget _buildUserInfoSection(
    BuildContext context,
    String nickname,
    MoodCategory moodCategory,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.accentRed,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppRadius.lg),
        ),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: MediaQuery.of(context).padding.top + AppSpacing.md,
        bottom: AppSpacing.lg,
      ),
      child: Column(
        children: [
          // 프로필 아이콘
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sentiment_satisfied_alt,
              size: 28,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // 사용자 이름
          Text(
            '$nickname님',
            style: AppTypography.body.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // 마이페이지 바로가기
          InkWell(
            onTap: () => _navigateToMyPage(context),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '마이페이지',
                    style: AppTypography.body.copyWith(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 기분 카테고리에 따른 배경색 반환
  Color _getMoodColor(MoodCategory category) {
    switch (category) {
      case MoodCategory.good:
        return AppColors.homeGoodYellow;
      case MoodCategory.neutral:
        return AppColors.homeNormalGreen;
      case MoodCategory.bad:
        return AppColors.homeBadBlue;
    }
  }

  /// 리스트 메뉴 항목 빌더
  Widget _buildListMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required MoodCategory moodCategory,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
        ),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.borderLight,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.accentRed,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  // ============ Navigation Methods ============

  static void _navigateToAlarm(BuildContext context) {
    Navigator.pop(context);
    Navigator.pushNamed(context, '/alarm');
  }

  static void _navigateToReport(BuildContext context) {
    Navigator.pop(context);
    Navigator.pushNamed(context, '/report');
  }

  static void _navigateToMyPage(BuildContext context) {
    Navigator.pop(context);
    Navigator.pushNamed(context, '/mypage');
  }

  static void _navigateToSettings(BuildContext context) {
    Navigator.pop(context);
    Navigator.pushNamed(context, '/settings');
  }

  static void _navigateToTraining(BuildContext context) {
    Navigator.pop(context);
    Navigator.pushNamed(context, '/training');
  }

  static void _navigateToHelp(BuildContext context) {
    Navigator.pop(context);
    // TODO: 도움말 화면 구현
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('도움말 화면은 준비중입니다'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

/// 메뉴 항목 데이터 모델
class _MenuItemData {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuItemData({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}
