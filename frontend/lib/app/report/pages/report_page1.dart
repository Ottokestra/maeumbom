import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../data/models/report/weekly_mood_report.dart';
import '../../../ui/app_ui.dart';
import 'report_page_utils.dart';

/// 페이지 1: 이번주 감정 온도
class ReportPage1 extends StatelessWidget {
  const ReportPage1({super.key, required this.report});

  final WeeklyMoodReport report;

  @override
  Widget build(BuildContext context) {
    final double temperaturePercentage =
        (report.overallScorePercent.clamp(0, 100)) / 100;
    final EmotionId mainEmotion = mapEmotionFromCode(
      report.dominantEmotion.characterCode,
      emotionLabel: report.dominantEmotion.label,
    );
    final Color emotionColor = getEmotionPrimaryColor(mainEmotion);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          // Chapter 헤더
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Chapter 배지 (가운데 정렬)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Chapter 1',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.pureWhite,
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 타이틀 (가운데 정렬)
              Center(
                child: Text(
                  '이번 주 감정 온도',
                  style: AppTypography.h3.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // 반원 그래프 + 캐릭터
          SizedBox(
            width: 320,
            height: 240,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // 반원 그래프
                Positioned(
                  bottom: 60,
                  child: CustomPaint(
                    size: const Size(320, 160),
                    painter: SemicircleProgressPainter(
                      progress: temperaturePercentage,
                      color: emotionColor,
                    ),
                  ),
                ),

                // 중앙 캐릭터 (그래프 아래)
                Positioned(
                  bottom: 0,
                  child: EmotionCharacter(
                    id: mainEmotion,
                    size: 150,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // 이번 주 감정 라벨
          Text(
            '이번 주 감정',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          // 퍼센트 표시
          Text(
            '${(temperaturePercentage * 100).toInt()}%',
            style: AppTypography.h1.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 80,
              height: 1.0,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // 감정 이름 배지
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: emotionColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              report.dominantEmotion.label,
              style: AppTypography.h3.copyWith(
                color: emotionColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // 요약 코멘트
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.bgWarm,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.accentRed,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '이번 주 감정 요약',
                      style: AppTypography.body.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  report.analysisText.isNotEmpty
                      ? report.analysisText
                      : '이번 주에는 ${report.dominantEmotion.label} 감정을 가장 많이 느끼셨네요! 감정 온도가 ${(temperaturePercentage * 100).toInt()}%로 안정적인 상태를 유지하고 있습니다.',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.5,
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
        ..color = AppColors.pureWhite
        ..style = PaintingStyle.fill;

      canvas.drawCircle(endPoint, 10, innerCirclePaint);
    }
  }

  @override
  bool shouldRepaint(SemicircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
