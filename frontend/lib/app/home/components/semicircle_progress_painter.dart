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

    // 배경 반원
    final bgPaint = Paint()
      ..color = AppColors.borderLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi, // 시작 각도 (9시 방향)
      math.pi, // 반원 (180도)
      false,
      bgPaint,
    );

    // 진행 반원
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    final sweepAngle = math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi, // 시작 각도 (9시 방향)
      sweepAngle,
      false,
      progressPaint,
    );

    // 엔드포인트 원형 표시
    if (progress > 0) {
      final endAngle = math.pi + sweepAngle;
      final endPointX = center.dx + radius * math.cos(endAngle);
      final endPointY = center.dy + radius * math.sin(endAngle);
      final endPoint = Offset(endPointX, endPointY);

      // 외곽 원 (색상)
      final outerCirclePaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(endPoint, 14, outerCirclePaint);

      // 내부 원 (흰색)
      final innerCirclePaint = Paint()
        ..color = AppColors.basicColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(endPoint, 10, innerCirclePaint);
    }
  }

  @override
  bool shouldRepaint(SemicircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
