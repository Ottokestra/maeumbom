import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../ui/app_ui.dart';

/// 페이지 2: 요일별 감정 캐릭터 스티커
class ReportPage2 extends StatelessWidget {
  const ReportPage2({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: API에서 데이터 가져오기
    final List<DailyEmotion> weeklyEmotions = [
      DailyEmotion(
        day: '월요일',
        date: '1/1',
        emotion: EmotionId.joy,
        isCollected: true,
      ),
      DailyEmotion(
        day: '화요일',
        date: '1/2',
        emotion: EmotionId.love,
        isCollected: true,
      ),
      DailyEmotion(
        day: '수요일',
        date: '1/3',
        emotion: EmotionId.relief,
        isCollected: false,
      ),
      DailyEmotion(
        day: '목요일',
        date: '1/4',
        emotion: EmotionId.excitement,
        isCollected: false,
      ),
      DailyEmotion(
        day: '금요일',
        date: '1/5',
        emotion: EmotionId.interest,
        isCollected: false,
      ),
      DailyEmotion(
        day: '토요일',
        date: '1/6',
        emotion: EmotionId.sadness,
        isCollected: false,
      ),
      DailyEmotion(
        day: '일요일',
        date: '1/7',
        emotion: EmotionId.anger,
        isCollected: false,
      ),
    ];

    final int collectedCount = weeklyEmotions.where((e) => e.isCollected).length;
    final double progress = collectedCount / 7;

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
                children: weeklyEmotions
                    .sublist(0, 3)
                    .map((emotion) => _buildEmotionCircle(emotion))
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.lg),
              // 두 번째 줄 (목, 금, 토)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: weeklyEmotions
                    .sublist(3, 6)
                    .map((emotion) => _buildEmotionCircle(emotion))
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.lg),
              // 세 번째 줄 (일)
              weeklyEmotions.length > 6
                  ? _buildEmotionCircle(weeklyEmotions[6])
                  : const SizedBox.shrink(),
            ],
          ),
        ],
      ),
    );
  }

  /// 감정 원형 위젯
  Widget _buildEmotionCircle(DailyEmotion emotion) {
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

/// 일일 감정 데이터 모델
class DailyEmotion {
  final String day;
  final String date;
  final EmotionId? emotion;
  final bool isCollected;

  DailyEmotion({
    required this.day,
    required this.date,
    required this.emotion,
    required this.isCollected,
  });
}