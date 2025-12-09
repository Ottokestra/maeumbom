import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../ui/app_ui.dart';
import '../../../core/services/navigation/navigation_service.dart';

/// 홈 화면 하단 메뉴 (4개 버튼)
///
/// 봄이 채팅, 똑똑 알람, 마음리포트, 마음연습실로 이동하는 메뉴입니다.
class HomeBottomMenu extends ConsumerWidget {
  const HomeBottomMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationService = NavigationService(context, ref);

    final menuItems = [
      _MenuItemData(
        label: '봄이 채팅',
        icon: Icons.chat_bubble_outline,
        onTap: () => navigationService.navigateToRoute('/bomi'),
      ),
      _MenuItemData(
        label: '똑똑 알람',
        icon: Icons.notifications_none,
        onTap: () => navigationService.navigateToRoute('/alarm'),
      ),
      _MenuItemData(
        label: '마음리포트',
        icon: Icons.assessment_outlined,
        onTap: () => navigationService.navigateToRoute('/report'),
      ),
      _MenuItemData(
        label: '마음연습실',
        icon: Icons.self_improvement,
        onTap: () => navigationService.navigateToRoute('/training'),
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: menuItems.map((item) => _buildMenuItem(item)).toList(),
    );
  }

  /// 메뉴 아이템 빌더
  Widget _buildMenuItem(_MenuItemData item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 원형 아이콘 컨테이너
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.icon,
              size: 28,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          // 라벨
          Text(
            item.label,
            style: AppTypography.caption.copyWith(
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// 메뉴 아이템 데이터 클래스
class _MenuItemData {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  _MenuItemData({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}
