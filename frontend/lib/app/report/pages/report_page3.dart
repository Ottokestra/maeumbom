import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../ui/app_ui.dart';
import '../../../providers/target_events_provider.dart';
import '../../../providers/routine_recommendations_provider.dart';
import '../services/emotion_analysis_service.dart';
import '../services/emotion_insight_generator.dart';
import '../services/routine_extractor.dart';

/// 페이지 3: 이번주 감정 분석 상세
class ReportPage3 extends ConsumerWidget {
  final DateTime startDate;
  final DateTime endDate;

  const ReportPage3({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 날짜 범위를 기반으로 주간 이벤트 provider 생성
    // 이렇게 하면 날짜가 변경될 때만 새로 로드됨
    final weeklyEventsAsync = ref.watch(
      weeklyEventsProviderFamily((startDate, endDate)),
    );

    // 루틴 추천 데이터 가져오기
    final routineRecsAsync = ref.watch(
      routineRecommendationsProviderFamily((startDate, endDate)),
    );

    return weeklyEventsAsync.when(
      data: (weeklyEvents) {
        // 감정 데이터 분석
        final analysisResult =
            EmotionAnalysisService.analyzeWeeklyEmotions(weeklyEvents);

        // 데이터가 없는 경우
        if (analysisResult.topEmotion == null ||
            analysisResult.allEmotions.isEmpty) {
          return _buildEmptyState();
        }

        final topEmotion = analysisResult.topEmotion!;
        final allEmotions = analysisResult.allEmotions;

        // 감정 분석 텍스트 생성
        final sentimentOverall = weeklyEvents.isNotEmpty
            ? weeklyEvents.first.sentimentOverall
            : null;

        // 주요 감정에 맞는 루틴 추출
        final recommendedRoutines = routineRecsAsync.maybeWhen(
          data: (routineData) => RoutineExtractor.extractRoutinesForEmotion(
            recommendations: routineData.recommendations,
            primaryEmotion: topEmotion.emotion,
          ),
          orElse: () => null,
        );

        final insightText = EmotionInsightGenerator.generate(
          primaryEmotion: topEmotion.emotion,
          sentimentOverall: sentimentOverall,
          topEmotionPercentage: topEmotion.percentage.toDouble(),
          recommendedRoutines: recommendedRoutines,
        );

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
                      'Chapter 3',
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
                      '상세 마음 리포트',
                      style: AppTypography.h3.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // 상위 감정 카드
              _buildTopEmotionCard(topEmotion),

              const SizedBox(height: AppSpacing.xl),

              // 전체 감정 분포
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.bgBasic,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: AppColors.borderLight,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: allEmotions.skip(1).map((emotion) {
                    final emotionColor =
                        getEmotionPrimaryColor(emotion.emotion);
                    final isFirst = emotion.rank == 2; // 2위가 리스트의 첫 번째
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: emotion.rank == allEmotions.length
                            ? 0
                            : AppSpacing.sm,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: isFirst
                              ? emotionColor.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Row(
                          children: [
                            // 순위 배지
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isFirst
                                    ? emotionColor
                                    : AppColors.borderLight,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${emotion.rank}',
                                style: AppTypography.caption.copyWith(
                                  color: isFirst
                                      ? AppColors.basicColor
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),

                            const SizedBox(width: AppSpacing.sm),

                            // 감정 캐릭터
                            EmotionCharacter(
                              id: emotion.emotion,
                              use2d: true,
                              size: 32,
                            ),

                            const SizedBox(width: AppSpacing.sm),

                            // 감정 이름
                            Text(
                              emotion.emotionName,
                              style: AppTypography.body.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight:
                                    isFirst ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),

                            const Spacer(),

                            // 퍼센트
                            Text(
                              '${emotion.percentage}%',
                              style: AppTypography.body.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // 감정 분석 설명
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
                          color: AppColors.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '이번 주 감정 분석',
                          style: AppTypography.body.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      insightText,
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
      },
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  /// 빈 상태 위젯
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          Icon(
            Icons.sentiment_neutral,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '아직 이번 주 감정 데이터가 충분하지 않아요',
            style: AppTypography.h3.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '봄이와 더 많은 대화를 나누면\n상세한 감정 분석을 볼 수 있어요',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 로딩 상태 위젯
  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: CircularProgressIndicator(
          color: AppColors.primaryColor,
        ),
      ),
    );
  }

  /// 에러 상태 위젯
  Widget _buildErrorState(String error) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          Icon(
            Icons.error_outline,
            size: 80,
            color: AppColors.error,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '감정 데이터를 불러오는데 실패했습니다',
            style: AppTypography.h3.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            error,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 상위 감정 카드
  Widget _buildTopEmotionCard(EmotionRank emotion) {
    final Color emotionColor = getEmotionPrimaryColor(emotion.emotion);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.basicColor,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 캐릭터 (가운데 정렬)
          Center(
            child: EmotionCharacter(
              id: emotion.emotion,
              size: 120,
              use2d: true,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // 감정 정보 박스 (불투명한 감정 색상)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: emotionColor,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '이번 주 가장 많이 느낀 감정',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.basicColor.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  emotion.emotionName,
                  style: AppTypography.h1.copyWith(
                    color: AppColors.basicColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 32,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${emotion.count}회 기록됨',
                      style: AppTypography.body.copyWith(
                        color: AppColors.basicColor.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${emotion.percentage}%',
                      style: AppTypography.h1.copyWith(
                        color: AppColors.basicColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 감정 순위 데이터 모델
class EmotionRank {
  final int rank;
  final EmotionId emotion;
  final String emotionName;
  final int percentage;
  final int count;

  EmotionRank({
    required this.rank,
    required this.emotion,
    required this.emotionName,
    required this.percentage,
    required this.count,
  });
}
