import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../ui/app_ui.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../core/utils/emotion_mapper.dart';
import '../../../data/models/dashboard/emotion_history_model.dart';

// DateRange를 사용하기 위한 export
export '../../../providers/dashboard_provider.dart' show DateRange;

/// 페이지 2: 요일별 감정 캐릭터 스티커
class ReportPage2 extends ConsumerWidget {
  final DateTime startDate;
  final DateTime endDate;

  const ReportPage2({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  /// 요일 이름 반환 (월~일)
  String _getDayName(int weekday) {
    const days = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
    return days[weekday - 1];
  }

  /// 날짜 포맷팅 (M/d)
  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }

  /// API 데이터를 DailyEmotion 리스트로 변환
  List<DailyEmotion> _convertToWeeklyEmotions(List<Map<String, dynamic>> dailyEmotions) {
    // startDate ~ endDate 범위의 날짜 생성 (월요일 ~ 일요일)
    final weekDates = List.generate(7, (index) {
      return startDate.add(Duration(days: index));
    });

    // 날짜별 감정 데이터 매핑
    final emotionMap = <String, Map<String, dynamic>>{};
    for (final emotion in dailyEmotions) {
      final dateKey = emotion['date'] as String;
      emotionMap[dateKey] = emotion;
    }

    // 요일별 DailyEmotion 생성
    return weekDates.map((date) {
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final emotionData = emotionMap[dateKey];
      
      EmotionId? emotionId;
      // primaryEmotion이 있을 때만 매핑
      if (emotionData != null) {
        final primaryEmotion = emotionData['primary_emotion'] as Map<String, dynamic>?;
        if (primaryEmotion != null && primaryEmotion['code'] != null) {
          emotionId = EmotionMapper.fromCode(primaryEmotion['code'] as String);
        }
      }

      return DailyEmotion(
        day: _getDayName(date.weekday),
        date: _formatDate(date),
        emotion: emotionId,
        isCollected: emotionData != null,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateRange = DateRange(startDate, endDate);
    final emotionsAsync = ref.watch(dailyEmotionsProvider(dateRange));

    return emotionsAsync.when(
      data: (emotions) {
        final weeklyEmotions = _convertToWeeklyEmotions(emotions);
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
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Chapter 2',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.basicColor,
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
                      color: AppColors.secondaryColor,
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
                            color: AppColors.secondaryColor,
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
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryColor,
        ),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '감정 데이터를 불러오는데 실패했습니다',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                error.toString(),
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
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
                  ? AppColors.secondaryColor.withOpacity(0.1)
                  : AppColors.borderLight.withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(
                color: emotion.isCollected
                    ? AppColors.secondaryColor
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
                        color: AppColors.secondaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.basicColor,
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
                          color: AppColors.basicColor,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.check,
                        color: AppColors.basicColor,
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