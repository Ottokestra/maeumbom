import 'package:flutter/material.dart';
import '../../../../ui/app_ui.dart';

class HomeMainButtons extends StatelessWidget {
  final VoidCallback onChatTap;
  final VoidCallback onAlarmTap;

  const HomeMainButtons({
    super.key,
    required this.onChatTap,
    required this.onAlarmTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildButton(
            context: context,
            title: '봄이 대화',
            subtitle: '오늘 하루\n어떠셨나요?',
            icon: Icons.chat_bubble_outline,
            iconColor: const Color(0xFF6C8CD5), // Soft Blue
            onTap: onChatTap,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildButton(
            context: context,
            title: '똑똑 알림',
            subtitle: '약 먹을 시간\n잊지 마세요',
            icon: Icons.notifications_none,
            iconColor: const Color(0xFFFF7A5C), // Soft Red/Orange
            onTap: onAlarmTap,
          ),
        ),
      ],
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const Spacer(),
            // Title
            Text(
              title,
              style: AppTypography.h3.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            // Subtitle
            Text(
              subtitle,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
