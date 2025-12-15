import 'package:flutter/material.dart';
import '../../../ui/app_ui.dart';
import 'emotion_donut_chart_painter.dart';

/// 감정 세그먼트 데이터 모델
class EmotionSegment {
  final String label;
  final double percentage;
  final Color color;

  const EmotionSegment({
    required this.label,
    required this.percentage,
    required this.color,
  });
}

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
    // TODO: 실제 데이터는 provider에서 가져와야 함
    final segments = [
      const EmotionSegment(
        label: '안정',
        percentage: 35,
        color: Color(0xFF66D9B8), // 초록
      ),
      const EmotionSegment(
        label: '기쁨',
        percentage: 25,
        color: Color(0xFFFFD666), // 노랑
      ),
      const EmotionSegment(
        label: '사랑',
        percentage: 20,
        color: Color(0xFFFF9F9F), // 분홍
      ),
      const EmotionSegment(
        label: '분노',
        percentage: 12,
        color: Color(0xFFFF6B6B), // 빨강
      ),
      const EmotionSegment(
        label: '걱정/우울',
        percentage: 8,
        color: Color(0xFF9E9E9E), // 회색
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.basicColor,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 타이틀
          Text(
            '이번 주 감정 기록',
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          // 가로형 막대 차트
          SizedBox(
            width: double.infinity,
            height: 40,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: CustomPaint(
                painter: EmotionDonutChartPainter(segments: segments),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          // 범례 (Legend)
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            alignment: WrapAlignment.center,
            children: segments.map((segment) {
              return _buildLegendItem(
                label: segment.label,
                color: segment.color,
                percentage: segment.percentage,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// 범례 아이템 빌더
  Widget _buildLegendItem({
    required String label,
    required Color color,
    required double percentage,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 6,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 색상 인디케이터
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          // 라벨 및 퍼센트
          Text(
            '$label ${percentage.toInt()}%',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
