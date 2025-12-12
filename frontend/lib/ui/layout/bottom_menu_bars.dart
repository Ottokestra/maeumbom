import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../tokens/app_tokens.dart';

/// Bottom Bar - Menu Bar (네비게이션)
class BottomMenuBar extends StatelessWidget {
  const BottomMenuBar({
    super.key,
    this.currentIndex = 0,
    this.onTap,
    this.backgroundColor = AppColors.pureWhite,
    this.foregroundColor = AppColors.textPrimary,
    this.primaryColor = AppColors.primaryColor,
  });

  final int currentIndex;
  final ValueChanged<int>? onTap;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final totalHeight = 100 + bottomPadding;

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Background (80px + bottom padding, top border 포함)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 80 + bottomPadding,
              decoration: BoxDecoration(
                color: backgroundColor,
                border: Border(
                  top: BorderSide(
                    width: 1,
                    color: AppColors.borderLight,
                  ),
                ),
              ),
            ),
          ),
          // 2. 메뉴 아이콘들 (100px 높이로 중앙 버튼 포함)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 100,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _MenuItem(
                    index: 0,
                    label: '홈',
                    isSelected: currentIndex == 0,
                    iconAsset: 'assets/images/icons/icon-home.svg',
                    onTap: onTap,
                    foregroundColor: foregroundColor,
                    primaryColor: primaryColor,
                  ),
                  _MenuItem(
                    index: 1,
                    label: '마음서랍',
                    isSelected: currentIndex == 1,
                    iconAsset: 'assets/images/icons/icon-report.svg',
                    onTap: onTap,
                    foregroundColor: foregroundColor,
                    primaryColor: primaryColor,
                  ),
                  _CenterRecordButton(
                    onTap: () => onTap?.call(2),
                    primaryColor: primaryColor,
                  ),
                  _MenuItem(
                    index: 3,
                    label: '마음연습실',
                    isSelected: currentIndex == 3,
                    iconAsset: 'assets/images/icons/icon-apps.svg',
                    onTap: onTap,
                    foregroundColor: foregroundColor,
                    primaryColor: primaryColor,
                  ),
                  _MenuItem(
                    index: 4,
                    label: '마이페이지',
                    isSelected: currentIndex == 4,
                    iconAsset: 'assets/images/icons/icon-mypage.svg',
                    onTap: onTap,
                    foregroundColor: foregroundColor,
                    primaryColor: primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.index,
    required this.label,
    required this.isSelected,
    required this.iconAsset,
    this.onTap,
    required this.foregroundColor,
    required this.primaryColor,
  });

  final int index;
  final String label;
  final bool isSelected;
  final String iconAsset;
  final ValueChanged<int>? onTap;
  final Color foregroundColor;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final Color color =
        isSelected ? primaryColor : foregroundColor;

    return GestureDetector(
      onTap: () => onTap?.call(index),
      child: SizedBox(
        width: 52,
        height: 80,
        child: Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.fromSize(
                size: AppIconSizes.mdSize,
                child: SvgPicture.asset(
                  iconAsset,
                  fit: BoxFit.contain,
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTypography.label.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterRecordButton extends StatelessWidget {
  const _CenterRecordButton({
    this.onTap,
    required this.primaryColor,
  });

  final VoidCallback? onTap;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 80,
        height: 100,
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 19),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SizedBox.fromSize(
                  size: AppIconSizes.xxlSize,
                  child: SvgPicture.asset(
                    'assets/images/icons/icon-mic.svg',
                    colorFilter: const ColorFilter.mode(
                      AppColors.basicColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
