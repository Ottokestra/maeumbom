import 'package:flutter/material.dart';
import 'package:frontend/ui/tokens/app_tokens.dart';

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
class MoreMenuSheet extends StatelessWidget {
  const MoreMenuSheet({super.key});

  /// BottomSheet 표시
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      builder: (context) => const MoreMenuSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
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

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 제목
            Text(
              '마음봄 메뉴',
              style: AppTypography.h3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 2열 그리드 메뉴
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.7,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
              ),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return _buildGridMenuItem(
                  icon: item.icon,
                  title: item.title,
                  onTap: item.onTap,
                );
              },
            ),

            // 하단 여백 (홈 인디케이터 대응)
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  /// 그리드 메뉴 항목 빌더
  Widget _buildGridMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.borderLight,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: AppColors.accentRed,
              size: 28,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              title,
              style: AppTypography.body.copyWith(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
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
