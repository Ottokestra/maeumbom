import 'package:flutter/material.dart';
import '../tokens/app_tokens.dart';

/// 공통 Top Bar 위젯
/// - title : 중앙 타이틀
/// - leftIcon / onTapLeft : 좌측 버튼
/// - rightIcon / onTapRight : 우측 버튼
class TopBar extends StatelessWidget implements PreferredSizeWidget {
  const TopBar({
    super.key,
    required this.title,
    this.leftIcon,
    this.rightIcon,
    this.leftAction,
    this.rightAction,
    this.onTapLeft,
    this.onTapRight,
    this.height = 60,
    this.backgroundColor = AppColors.basicColor,
    this.foregroundColor = AppColors.textPrimary,
  });

  final String title;
  final IconData? leftIcon;
  final IconData? rightIcon;
  final Widget? leftAction;
  final Widget? rightAction;
  final VoidCallback? onTapLeft;
  final VoidCallback? onTapRight;
  final double height;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      color: backgroundColor,
      child: Row(
        children: [
          _buildIconSlot(
            icon: leftIcon,
            action: leftAction,
            onTap: onTapLeft,
          ),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: AppTypography.h3.copyWith(
                  color: foregroundColor,
                ),
              ),
            ),
          ),
          _buildIconSlot(
            icon: rightIcon,
            action: rightAction,
            onTap: onTapRight,
          ),
        ],
      ),
    );
  }

  Widget _buildIconSlot({
    IconData? icon,
    Widget? action,
    VoidCallback? onTap,
  }) {
    if (action != null) {
      return SizedBox(
        width: 48,
        height: 48,
        child: Center(child: action),
      );
    }
    
    if (icon == null) {
      return const SizedBox(
        width: 48,
        height: 48,
      );
    }

    return SizedBox(
      width: 48,
      height: 48,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.translucent,
        child: Icon(
          icon,
          color: foregroundColor,
          size: 24,
        ),
      ),
    );
  }
}
