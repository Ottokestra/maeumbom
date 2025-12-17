import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../home/components/home_gauge_section.dart';

/// 원형 도넛 차트 Painter
///
/// 감정 분포를 원형 도넛 차트로 시각화합니다.
/// - 중앙이 비어있는 도넛 형태
/// - 각 감정 세그먼트를 색상으로 구분
/// - 12시 방향부터 시계방향으로 360도 원형 배치
class CircularDonutChartPainter extends CustomPainter {
  final List<EmotionSegment> segments;
  final double strokeWidth;

  CircularDonutChartPainter({
    required this.segments,
    this.strokeWidth = 40.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty) {
      _drawEmptyState(canvas, size);
      return;
    }

    // 원형이므로 중심을 정중앙에 배치
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - 10; // 여백 10

    // 원형 도넛 차트 그리기 (12시 방향부터 시계방향)
    double currentAngle = -math.pi / 2; // 12시 방향부터 시작 (-90도)

    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final sweepAngle = (segment.percentage / 100) * 2 * math.pi; // 전체 원(360도)

      // 세그먼트가 너무 작으면 스킵
      if (sweepAngle < 0.01) continue;

      // 도넛 세그먼트 페인트
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth // strokeWidth 파라미터 직접 사용
        ..strokeCap = StrokeCap.butt;

      final rect = Rect.fromCircle(
        center: center,
        radius: radius - (strokeWidth / 2), // 중심 반지름
      );

      // 세그먼트 그리기
      canvas.drawArc(
        rect,
        currentAngle,
        sweepAngle,
        false,
        paint,
      );

      // 세그먼트 간 구분선 (흰색 얇은 선)
      if (i < segments.length - 1) {
        final separatorPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        final endAngle = currentAngle + sweepAngle;
        final arcRadius = radius - (strokeWidth / 2);
        final halfStroke = strokeWidth / 2;

        final x1 = center.dx + (arcRadius - halfStroke) * math.cos(endAngle);
        final y1 = center.dy + (arcRadius - halfStroke) * math.sin(endAngle);
        final x2 = center.dx + (arcRadius + halfStroke) * math.cos(endAngle);
        final y2 = center.dy + (arcRadius + halfStroke) * math.sin(endAngle);

        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), separatorPaint);
      }

      currentAngle += sweepAngle;
    }
  }

  /// 데이터가 없을 때 빈 상태 표시
  void _drawEmptyState(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - 10;

    final emptyPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final rect = Rect.fromCircle(
      center: center,
      radius: radius - (strokeWidth / 2),
    );

    // 원형 빈 상태 그리기
    canvas.drawArc(
      rect,
      -math.pi / 2, // 12시 방향
      2 * math.pi, // 360도 (전체 원)
      false,
      emptyPaint,
    );
  }

  @override
  bool shouldRepaint(CircularDonutChartPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
