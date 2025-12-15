import 'package:flutter/material.dart';
import 'home_gauge_section.dart';

/// 감정 가로형 막대 차트 Painter
class EmotionDonutChartPainter extends CustomPainter {
  final List<EmotionSegment> segments;

  EmotionDonutChartPainter({
    required this.segments,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const barHeight = 24.0; // 막대 높이
    const barRadius = 12.0; // 막대 모서리 둥글기

    double currentX = 0;

    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final barWidth = (segment.percentage / 100) * size.width;

      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.fill;

      // 첫 번째 세그먼트: 왼쪽만 둥글게
      // 마지막 세그먼트: 오른쪽만 둥글게
      // 중간 세그먼트: 직사각형
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
          Rect.fromLTWH(currentX, (size.height - barHeight) / 2, barWidth, barHeight),
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
        // 중간: 직사각형
        rRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(currentX, (size.height - barHeight) / 2, barWidth, barHeight),
          Radius.zero,
        );
      }

      canvas.drawRRect(rRect, paint);
      currentX += barWidth;
    }
  }

  @override
  bool shouldRepaint(EmotionDonutChartPainter oldDelegate) {
    return oldDelegate.segments != segments;
  }
}
