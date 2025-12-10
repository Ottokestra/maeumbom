import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../data/models/report/weekly_mood_report.dart';
import '../../../ui/app_ui.dart';
import 'report_page_utils.dart';

/// 페이지 2: 요일별 감정 캐릭터 스티커
class ReportPage2 extends StatelessWidget {
  const ReportPage2({super.key, required this.report});

  final WeeklyMoodReport report;

  @override
  Widget build(BuildContext context) {
    final List<_DailyEmotionView> weeklyEmotions = report.dailyCharacters
        .map(
          (sticker) => _DailyEmotionView(
            day: formatWeekdayLabel(sticker.weekday),
            date: formatShortDate(sticker.date),
            emotion: sticker.hasRecord
                ? mapEmotionFromCode(
                    sticker.characterCode,
                    emotionLabel: sticker.emotionLabel,
                  )
                : null,
            isCollected: sticker.hasRecord,
          ),
        )
        .toList();

    final int totalDays = weeklyEmotions.isEmpty ? 7 : weeklyEmotions.length;
    final int collectedCount =
        weeklyEmotions.where((e) => e.isCollected).length;
    final double progress =
        totalDays == 0 ? 0 : collectedCount / totalDays.clamp(1, 7);

    final firstRow = weeklyEmotions.take(3).toList();
    final secondRow = weeklyEmotions.skip(3).take(3).toList();
    final thirdRow = weeklyEmotions.skip(6).take(1).toList();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  'Chapter 2',
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
                  '요일별 감정 캐릭터 스티커',
                  style: AppTypography.h3.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // 수집 완료 상태
          Row(
            children: [
              Text(
                '수집 완료',
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '$collectedCount/7',
                style: AppTypography.body.copyWith(
                  color: AppColors.natureGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // 진행 바
              Expanded(
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.natureGreen,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // 감정 원형 그리드 (3-3-1 레이아웃)
          Column(
            children: [
              // 첫 번째 줄 (월, 화, 수)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children:
                    firstRow.map((emotion) => _buildEmotionCircle(emotion)).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),
              // 두 번째 줄 (목, 금, 토)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children:
                    secondRow.map((emotion) => _buildEmotionCircle(emotion)).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),
              // 세 번째 줄 (일)
              thirdRow.isNotEmpty
                  ? _buildEmotionCircle(thirdRow.first)
                  : const SizedBox.shrink(),
            ],
          ),
        ],
      ),
    );
  }

  /// 감정 원형 위젯
  Widget _buildEmotionCircle(_DailyEmotionView emotion) {
    return SizedBox(
      width: 100,
      height: 130,
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: emotion.isCollected
                  ? AppColors.natureGreen.withOpacity(0.1)
                  : AppColors.borderLight.withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(
                color: emotion.isCollected
                    ? AppColors.natureGreen
                    : AppColors.borderLight,
                width: 2,
              ),
            ),
            child: Stack(
              children: [
                // 감정 캐릭터 또는 빈 상태
                if (emotion.isCollected && emotion.emotion != null)
                  Center(
                    child: EmotionCharacter(
                      id: emotion.emotion!,
                      size: 70,
                    ),
                  ),

                // 체크 마크 (수집된 경우)
                if (emotion.isCollected)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.natureGreen,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.pureWhite,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),

                // 체크 마크 (미수집 - 회색)
                if (!emotion.isCollected)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.borderLight,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.pureWhite,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.check,
                        color: AppColors.pureWhite,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            emotion.day,
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: emotion.isCollected
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              fontWeight: emotion.isCollected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyEmotionView {
  _DailyEmotionView({
    required this.day,
    required this.date,
    required this.emotion,
    required this.isCollected,
  });

  final String day;
  final String date;
  final EmotionId? emotion;
  final bool isCollected;
}
