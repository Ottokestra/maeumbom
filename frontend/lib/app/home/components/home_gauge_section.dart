import 'package:flutter/material.dart';
import '../../../ui/app_ui.dart';
import 'semicircle_progress_painter.dart';

class HomeGaugeSection extends StatelessWidget {
  final double temperaturePercentage;
  final Color emotionColor;

  const HomeGaugeSection({
    super.key,
    required this.temperaturePercentage,
    required this.emotionColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.basicColor,
        borderRadius: BorderRadius.circular(32), // More rounded as per image
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Semicircle Gauge
          SizedBox(
            width: 320,
            height: 150,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                CustomPaint(
                  size: const Size(320, 150),
                  painter: SemicircleProgressPainter(
                    progress: temperaturePercentage,
                    color: emotionColor,
                  ),
                ),
                // Percentage Text centered in the gauge roughly
                Positioned(
                  bottom: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(temperaturePercentage * 100).toInt()}%',
                        style: AppTypography.h1.copyWith( // Using a very large font for the number
                          fontSize: 60,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textBlack,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                         padding: const EdgeInsets.symmetric(
                           horizontal: 16,
                           vertical: 8,
                         ),
                         decoration: BoxDecoration(
                           color: emotionColor.withValues(alpha: 0.2),
                           borderRadius: BorderRadius.circular(AppRadius.pill),
                         ),
                         child: Text(
                           '두려움', // TODO: Dynamic label based on dominant emotion in that range
                           style: AppTypography.body.copyWith(
                             color: emotionColor,
                             fontWeight: FontWeight.w700,
                           ),
                         ),
                      ),
                    ],
                  ),
                ),
                
                 // Labels (Roughly positioned based on image)
                 // This is static for now as per the image reference "Frustration", "Sadness", "Joy"
                Positioned(
                  left: 30,
                  bottom: 40,
                  child: Text(
                    '좌절',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ),
                Positioned(
                  top: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 30), // Offset slightly
                      child: Text(
                        '슬픔',
                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 30,
                  bottom: 40,
                  child: Text(
                    '기쁨',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          
        ],
      ),
    );
  }
}
