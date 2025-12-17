import 'package:flutter/material.dart';
import 'home_gauge_section.dart';
import '../../../ui/app_ui.dart';

/// 감정 가로형 막대 차트 Painter
/// 
/// HomeGaugeSection과 동일한 색상 시스템을 사용하여 감정 분포를 시각화합니다.
/// - API 연동: weeklyEventsProvider를 통해 감정 분포 데이터 수신
/// - 색상 매핑: HomeGaugeSection.getWeeklyReportEmotionColor() 사용
/// - 상위 5개 감정을 퍼센트 기준 내림차순으로 표시
class EmotionDonutChartPainter extends CustomPainter {
  final List<EmotionSegment> segments;

  EmotionDonutChartPainter({
    required this.segments,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty) {
      _drawEmptyState(canvas, size);
      return;
    }

    const barHeight = 24.0; // 막대 높이
    const barRadius = 12.0; // 막대 모서리 둥글기
    const segmentGap = 1.0; // 세그먼트 간 간격 (미세한 구분선)

    double currentX = 0;

    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final barWidth = (segment.percentage / 100) * size.width;

      // 세그먼트가 너무 작으면 스킵 (1% 미만)
      if (barWidth < 2) continue;

      // 그라데이션 효과
      final gradientPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            segment.color.withValues(alpha: 0.95),
            segment.color,
          ],
        ).createShader(
          Rect.fromLTWH(
            currentX,
            (size.height - barHeight) / 2,
            barWidth,
            barHeight,
          ),
        )
        ..style = PaintingStyle.fill;

      // 세그먼트 모양 결정
      RRect rRect;
      if (i == 0 && i == segments.length - 1) {
        // 단일 세그먼트: 양쪽 둥글게
        rRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(currentX, (size.height - barHeight) / 2, barWidth, barHeight),
          const Radius.circular(barRadius),
        );
      } else if (i == 0) {
        // 첫 번째: 왼쪽만 둥글게
        rRect = RRect.fromRectAndCorners(
          Rect.fromLTWH(currentX, (size.height - barHeight) / 2, barWidth - segmentGap, barHeight),
          topLeft: const Radius.circular(barRadius),
          bottomLeft: const Radius.circular(barRadius),
        );
      } else if (i == segments.length - 1) {
        // 마지막: 오른쪽만 둥글게
        rRect = RRect.fromRectAndCorners(
          Rect.fromLTWH(currentX, (size.height - barHeight) / 2, barWidth, barHeight),
          topRight: const Radius.circular(barRadius),
          bottomRight: const Radius.circular(barRadius),
        );
      } else {
        // 중간: 직사각형 (간격 적용)
        rRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(currentX, (size.height - barHeight) / 2, barWidth - segmentGap, barHeight),
          Radius.zero,
        );
      }

      // 메인 세그먼트 그리기 (그라데이션 사용)
      canvas.drawRRect(rRect, gradientPaint);

      currentX += barWidth;
    }
  }

  /// 데이터가 없을 때 빈 상태 표시
  void _drawEmptyState(Canvas canvas, Size size) {
    const barHeight = 24.0;
    const barRadius = 12.0;

    final emptyPaint = Paint()
      ..color = AppColors.borderLightGray.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final emptyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, (size.height - barHeight) / 2, size.width, barHeight),
      const Radius.circular(barRadius),
    );

    canvas.drawRRect(emptyRect, emptyPaint);
  }

  @override
  bool shouldRepaint(EmotionDonutChartPainter oldDelegate) {
    return oldDelegate.segments != segments;
  }
}
