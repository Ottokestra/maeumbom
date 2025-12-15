import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'home_gauge_section.dart';

/// 감정 반원 도넛 차트 Painter (백업)
class EmotionDonutChartPainterBackup extends CustomPainter {
  final List<EmotionSegment> segments;

  EmotionDonutChartPainterBackup({
    required this.segments,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 20;
    final innerRadius = radius * 0.65; // 도넛 내부 구멍 크기 (65%)

    // 반원 도넛 차트 그리기 (9시 방향부터 3시 방향까지)
    double startAngle = math.pi; // 9시 방향부터 시작

    for (final segment in segments) {
      final sweepAngle = (segment.percentage / 100) * math.pi; // 반원이므로 π만큼만 사용

      // 도넛 세그먼트
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius - innerRadius
        ..strokeCap = StrokeCap.butt;

      final rect = Rect.fromCircle(
        center: center,
        radius: (radius + innerRadius) / 2,
      );

      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(EmotionDonutChartPainterBackup oldDelegate) {
    return oldDelegate.segments != segments;
  }
}
