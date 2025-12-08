import 'package:flutter/material.dart';
import '../../../../ui/app_ui.dart';

class ConversationTemperatureWidget extends StatelessWidget {
  const ConversationTemperatureWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg, 
        vertical: AppSpacing.md
      ),
      decoration: BoxDecoration(
        color: AppColors.natureGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.thermostat, color: AppColors.natureGreen),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '봄이와의 온도',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '36.5°C',
            style: AppTypography.h3.copyWith(
              color: AppColors.natureGreen, 
              fontWeight: FontWeight.bold
            ),
          ),
        ],
      ),
    );
  }
}
