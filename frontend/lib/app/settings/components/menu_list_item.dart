import 'package:flutter/material.dart';
import '../../../ui/app_ui.dart';

/// Menu List Item - 마이페이지 메뉴 항목 컴포넌트
///
/// 아이콘, 라벨, 뱃지, 화살표를 포함한 표준 메뉴 항목
class MenuListItem extends StatelessWidget {
  const MenuListItem({
    super.key,
    required this.icon,
    required this.label,
    this.badgeCount,
    required this.onTap,
  });

  /// 메뉴 아이콘
  final IconData icon;

  /// 메뉴 라벨
  final String label;

  /// 뱃지 숫자 (선택사항)
  final int? badgeCount;

  /// 탭 콜백
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 왼쪽: 아이콘 + 라벨
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            // 오른쪽: 뱃지 + 화살표
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (badgeCount != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      badgeCount.toString(),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textWhite,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
