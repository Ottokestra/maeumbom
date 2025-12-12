import 'package:flutter/material.dart';
import '../../../../ui/app_ui.dart';

class HomeBannerSlider extends StatefulWidget {
  final VoidCallback onTraining1Tap;
  final VoidCallback onTraining2Tap;

  const HomeBannerSlider({
    super.key,
    required this.onTraining1Tap,
    required this.onTraining2Tap,
  });

  @override
  State<HomeBannerSlider> createState() => _HomeBannerSliderState();
}

class _HomeBannerSliderState extends State<HomeBannerSlider> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 100, // Compact height
          child: PageView(
            controller: _controller,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: [
              _buildBanner(
                title: '관계 연습하기',
                subtitle: '나와 타인의 관계를\n건강하게 만들어봐요',
                color: const Color(0xFFFFE0B2), // Light Orange
                textColor: const Color(0xFFE65100),
                onTap: widget.onTraining1Tap,
              ),
              _buildBanner(
                title: '신조어 퀴즈',
                subtitle: '요즘 유행하는 말,\n얼마나 알고 있나요?',
                color: const Color(0xFFC8E6C9), // Light Green
                textColor: const Color(0xFF2E7D32),
                onTap: widget.onTraining2Tap,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(2, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentIndex == index
                    ? AppColors.textPrimary
                    : AppColors.borderLightGray,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildBanner({
    required String title,
    required String subtitle,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.h3.copyWith(
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: textColor.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: textColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
