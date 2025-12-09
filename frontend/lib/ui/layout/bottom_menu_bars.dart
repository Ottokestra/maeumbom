import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../tokens/app_tokens.dart';

/// Bottom Menu Bar - 3개 아이콘 네비게이션
///
/// DESIGN_GUIDE.md Option A 구조:
/// [홈]  [🎙️ 중앙 플로팅]  [더보기]
///
/// - 홈: 메인 홈 화면 (index 0)
/// - 마이크: 음성 대화 (index 1)
/// - 더보기: MoreMenuSheet 표시 (index 2)
class BottomMenuBar extends StatelessWidget {
  const BottomMenuBar({
    super.key,
    this.currentIndex = 0,
    this.onTap,
    this.backgroundColor = AppColors.pureWhite,
    this.foregroundColor = AppColors.textPrimary,
    this.accentColor = AppColors.accentRed,
  });

  final int currentIndex;
  final ValueChanged<int>? onTap;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color accentColor;

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
          // 2. 3개 아이콘 (홈 - 마이크 - 더보기)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 100,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 홈 아이콘
                  _MenuItem(
                    index: 0,
                    label: '홈',
                    isSelected: currentIndex == 0,
                    iconAsset: 'assets/images/icons/icon-home.svg',
                    onTap: onTap,
                    foregroundColor: foregroundColor,
                    accentColor: accentColor,
                  ),
                  // 중앙 마이크 버튼 (강조, 크게)
                  _CenterVoiceButton(
                    onTap: () => onTap?.call(1),
                    accentColor: accentColor,
                  ),
                  // 더보기 아이콘
                  _MenuItem(
                    index: 2,
                    label: '더보기',
                    isSelected: currentIndex == 2,
                    iconAsset: 'assets/images/icons/icon-more.svg',
                    onTap: onTap,
                    foregroundColor: foregroundColor,
                    accentColor: accentColor,
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

/// BottomMenuBar용 메뉴 아이템
class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.index,
    required this.label,
    required this.isSelected,
    required this.iconAsset,
    this.onTap,
    required this.foregroundColor,
    required this.accentColor,
  });

  final int index;
  final String label;
  final bool isSelected;
  final String iconAsset;
  final ValueChanged<int>? onTap;
  final Color foregroundColor;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final Color color = isSelected ? accentColor : foregroundColor;

    return GestureDetector(
      onTap: () => onTap?.call(index),
      child: SizedBox(
        width: 72,
        height: 100,
        child: Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 0),
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
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTypography.label.copyWith(
                  color: color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// BottomMenuBar용 중앙 음성 버튼 (크고 강조)
class _CenterVoiceButton extends StatelessWidget {
  const _CenterVoiceButton({
    this.onTap,
    required this.accentColor,
  });

  final VoidCallback? onTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 96,
        height: 100,
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.mic,
                color: AppColors.pureWhite,
                size: 36,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
