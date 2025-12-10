import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/report/models/weekly_emotion_report.dart';
import '../../../ui/app_ui.dart';

class WeeklyTemperatureGauge extends StatelessWidget {
  const WeeklyTemperatureGauge({
    super.key,
    required this.temperature,
    required this.mainEmotion,
  });

  final TemperatureInfo temperature;
  final MainEmotion mainEmotion;

  @override
  Widget build(BuildContext context) {
    final progress = temperature.score.clamp(0, 100) / 100;
    final gradientColors =
        _levelGradients[temperature.level] ?? _levelGradients['neutral']!;
    final levelLabel = _levelLabels[temperature.level] ?? '보통';
    final emoji = _characterEmoji[mainEmotion.characterCode] ?? '🙂';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '주간 감정 온도',
          style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.sm),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: progress),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: CircularProgressIndicator(
                      value: 1,
                      strokeWidth: 14,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.borderLight,
                      ),
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                  ShaderMask(
                    shaderCallback: (Rect rect) {
                      return SweepGradient(
                        startAngle: -math.pi / 2,
                        endAngle: 3 * math.pi / 2,
                        colors: gradientColors,
                      ).createShader(rect);
                    },
                    child: SizedBox(
                      width: 220,
                      height: 220,
                      child: CircularProgressIndicator(
                        value: value,
                        strokeWidth: 14,
                        strokeCap: StrokeCap.round,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  ),
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: AppColors.pureWhite,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.accentRedShadow,
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          emoji,
                          style: const TextStyle(fontSize: 42),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${temperature.score}',
                          style: AppTypography.h2.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          mainEmotion.label,
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '분위기 · $levelLabel',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _RatioChip(
              label: '긍정',
              value: temperature.positiveRatio,
              color: AppColors.natureGreen,
            ),
            const SizedBox(width: AppSpacing.sm),
            _RatioChip(
              label: '부정',
              value: temperature.negativeRatio,
              color: AppColors.accentRed,
            ),
          ],
        ),
      ],
    );
  }
}

class _RatioChip extends StatelessWidget {
  const _RatioChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).clamp(0, 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$percent%',
            style: AppTypography.bodySmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

const Map<String, List<Color>> _levelGradients = {
  'cold': [Color(0xFF8EC5FC), Color(0xFF56A8F7)],
  'neutral': [Color(0xFFA9ADC1), Color(0xFF7885A1)],
  'warm': [AppColors.accentCoral, AppColors.accentRed],
  'hot': [Color(0xFFFF8F8F), Color(0xFFD8454D)],
};

const Map<String, String> _levelLabels = {
  'cold': '차가움',
  'neutral': '보통',
  'warm': '따뜻함',
  'hot': '뜨거움',
};

const Map<String, String> _characterEmoji = {
  'HAPPY_BIRD': '🐦',
  'BRIGHT_DEER': '🦌',
  'SPARK_RABBIT': '🐰',
  'GRATEFUL_DOG': '🐶',
  'BLUE_WHALE': '🐳',
  'ANXIOUS_CAT': '🐱',
  'ANGRY_BEAR': '🐻',
  'BALANCED_FRIEND': '🙂',
};
