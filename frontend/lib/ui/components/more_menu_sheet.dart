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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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

          // 메뉴 항목들
          _buildMenuItem(
            context: context,
            icon: Icons.alarm,
            title: '알람 설정',
            onTap: () => _navigateToAlarm(context),
          ),
          _buildMenuItem(
            context: context,
            icon: Icons.bar_chart,
            title: '리포트 보기',
            onTap: () => _navigateToReport(context),
          ),
          _buildMenuItem(
            context: context,
            icon: Icons.person,
            title: '마이페이지',
            onTap: () => _navigateToMyPage(context),
          ),
          _buildMenuItem(
            context: context,
            icon: Icons.settings,
            title: '설정',
            onTap: () => _navigateToSettings(context),
          ),
          _buildMenuItem(
            context: context,
            icon: Icons.help,
            title: '도움말',
            onTap: () => _navigateToHelp(context),
          ),

          // 하단 여백 (홈 인디케이터 대응)
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  /// 메뉴 항목 빌더
  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppColors.accentRed,
        size: 28,
      ),
      title: Text(
        title,
        style: AppTypography.body.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.textSecondary,
      ),
      onTap: onTap,
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
