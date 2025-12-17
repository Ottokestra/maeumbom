import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../home/components/home_gauge_section.dart';

/// 반원형 도넛 차트 Painter
///
/// 감정 분포를 반원형 도넛 차트로 시각화합니다.
/// - 중앙이 비어있는 도넛 형태
/// - 각 감정 세그먼트를 색상으로 구분
/// - 9시 방향부터 3시 방향까지 반원형으로 배치
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

    // 반원형이므로 중심을 하단에 배치
    final center = Offset(size.width / 2, size.height);
    final strokeHalfWidth = strokeWidth / 2;
    final radius = (size.width / 2) - strokeHalfWidth - 10; // stroke 절반 + 여백 10
    final innerRadius = radius * 0.65; // 도넛 내부 구멍 크기 (65%)

    // 반원 도넛 차트 그리기 (9시 방향부터 3시 방향까지)
    double currentAngle = math.pi; // 9시 방향부터 시작

    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final sweepAngle = (segment.percentage / 100) * math.pi; // 반원이므로 π만큼만 사용

      // 세그먼트가 너무 작으면 스킵
      if (sweepAngle < 0.01) continue;

      // 도넛 세그먼트 페인트
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius - innerRadius
        ..strokeCap = StrokeCap.butt;

      final rect = Rect.fromCircle(
        center: center,
        radius: (radius + innerRadius) / 2,
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
        final arcRadius = (radius + innerRadius) / 2;
        final halfStroke = (radius - innerRadius) / 2;

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
    final center = Offset(size.width / 2, size.height);
    final strokeHalfWidth = strokeWidth / 2;
    final radius = (size.width / 2) - strokeHalfWidth - 10; // stroke 절반 + 여백 10
    final innerRadius = radius * 0.65;

    final emptyPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius - innerRadius
      ..strokeCap = StrokeCap.butt;

    final rect = Rect.fromCircle(
      center: center,
      radius: (radius + innerRadius) / 2,
    );

    // 반원형 빈 상태 그리기
    canvas.drawArc(
      rect,
      math.pi, // 9시 방향
      math.pi, // 180도 (반원)
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
