import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../ui/app_ui.dart';

/// 반원 진행 바 Painter
class SemicircleProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  SemicircleProgressPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 20;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // 배경 반원 (연한 회색)
    final bgPaint = Paint()
      ..color = const Color(0xFFE8E8E8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      math.pi, // 시작 각도 (9시 방향)
      math.pi, // 반원 (180도)
      false,
      bgPaint,
    );

    // 그라데이션 진행 반원
    final sweepAngle = math.pi * progress;

    // 그라데이션 색상 정의 (빨강 -> 주황 -> 노랑 -> 초록)
    final gradientColors = [
      const Color(0xFFFF6B6B), // 빨강 (저온)
      const Color(0xFFFF9F66), // 주황
      const Color(0xFFFFD666), // 노랑
      const Color(0xFF66D9B8), // 초록 (고온)
    ];

    final progressPaint = Paint()
      ..shader = SweepGradient(
        colors: gradientColors,
        startAngle: math.pi,
        endAngle: 2 * math.pi,
        transform: const GradientRotation(0),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      math.pi, // 시작 각도 (9시 방향)
      sweepAngle,
      false,
      progressPaint,
    );

    // 엔드포인트 포인터 (현재 위치 표시)
    if (progress > 0) {
      final endAngle = math.pi + sweepAngle;
      final endPointX = center.dx + radius * math.cos(endAngle);
      final endPointY = center.dy + radius * math.sin(endAngle);
      final endPoint = Offset(endPointX, endPointY);

      // 외곽 원 (현재 감정 색상)
      final outerCirclePaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(endPoint, 12, outerCirclePaint);

      // 내부 원 (흰색)
      final innerCirclePaint = Paint()
        ..color = AppColors.basicColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(endPoint, 8, innerCirclePaint);
    }
  }

  @override
  bool shouldRepaint(SemicircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
