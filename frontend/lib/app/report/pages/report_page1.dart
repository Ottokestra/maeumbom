import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../ui/app_ui.dart';
import '../../home/components/home_gauge_section.dart';
import '../components/circular_donut_chart_painter.dart';
import '../../../providers/target_events_provider.dart';
import '../../../core/utils/logger.dart';

/// 페이지 1: 이번주 감정 온도
class ReportPage1 extends ConsumerWidget {
  final DateTime startDate;
  final DateTime endDate;

  const ReportPage1({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  /// API 데이터를 EmotionSegment 리스트로 변환
  List<EmotionSegment> _convertToSegments(
      Map<String, dynamic> emotionDistribution) {
    if (emotionDistribution.isEmpty) {
      return [];
    }

    // 퍼센트 기준 내림차순 정렬
    final entries = emotionDistribution.entries.toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value as num));

    return entries.map((entry) {
      final emotion = entry.key;
      final percentage = (entry.value as num).toDouble();
      final color = _getWeeklyReportEmotionColor(emotion);

      return EmotionSegment(
        label: _getEmotionKoreanName(emotion),
        percentage: percentage,
        color: color,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 날짜 범위를 기반으로 주간 이벤트 provider 사용
    final weeklyEventsAsync = ref.watch(
      weeklyEventsProviderFamily((startDate, endDate)),
    );

    return weeklyEventsAsync.when(
      data: (weeklyEvents) {
        // 감정 데이터 변환
        final emotionSegments = weeklyEvents.isNotEmpty
            ? _convertToSegments(weeklyEvents.first.emotionDistribution)
            : <EmotionSegment>[];

        return _buildContent(emotionSegments, isLoading: false);
      },
      loading: () => _buildContent([], isLoading: true),
      error: (error, stack) {
        appLogger.e('❌ [ReportPage1] Failed to load data', error: error);
        return _buildContent([], isLoading: false);
      },
    );
  }

  Widget _buildContent(List<EmotionSegment> emotionSegments,
      {required bool isLoading}) {
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
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Chapter 1',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.basicColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                  ),
                ),
              ),
              const SizedBox(height: 8),
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

          const SizedBox(height: AppSpacing.md),

          // 감정 도넛 차트 섹션
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.basicColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                  spreadRadius: -4,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 10),
                  spreadRadius: -3,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 타이틀
                Text(
                  '이번 주 기록한 감정',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),

                // 로딩 상태 또는 차트 표시
                if (isLoading)
                  const SizedBox(
                    height: 180,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    ),
                  )
                else if (emotionSegments.isEmpty)
                  SizedBox(
                    height: 180,
                    child: Center(
                      child: Text(
                        '아직 기록된 감정이 없어요',
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                else ...[
                  // 원형 도넛 차트
                  SizedBox(
                    width: double.infinity,
                    height: 210,
                    child: CustomPaint(
                      painter: CircularDonutChartPainter(
                        segments: emotionSegments,
                        strokeWidth: 50,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // 범례 (Legend) - 세로 레이아웃
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: emotionSegments.map((segment) {
                      return _buildLegendItem(
                        label: segment.label,
                        color: segment.color,
                        percentage: segment.percentage,
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // 요약 코멘트
          if (!isLoading && emotionSegments.isNotEmpty)
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
                    '이번 주에는 ${emotionSegments.first.label} 감정을 가장 많이 느끼셨네요! 전체 감정 중 ${emotionSegments.first.percentage.toInt()}%를 차지하며 안정적인 상태를 유지하고 있습니다.',
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

  /// 범례 아이템 빌더 (세로 레이아웃)
  Widget _buildLegendItem({
    required String label,
    required Color color,
    required double percentage,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 색상 원형
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),

        // 감정 이름
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),

        // 퍼센트
        Text(
          '${percentage.toInt()}%',
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  /// 감정 영문명을 한글명으로 변환
  String _getEmotionKoreanName(String emotion) {
    final emotionLower = emotion.toLowerCase();

    // 긍정 감정
    if (emotionLower == 'joy') return '기쁨';
    if (emotionLower == 'happiness') return '행복';
    if (emotionLower == 'excitement') return '흥분';
    if (emotionLower == 'confidence') return '자신감';
    if (emotionLower == 'love') return '사랑';
    if (emotionLower == 'relief') return '안심';
    if (emotionLower == 'enlightenment') return '깨달음';
    if (emotionLower == 'interest') return '흥미';

    // 부정 감정
    if (emotionLower == 'discontent') return '불만';
    if (emotionLower == 'anger') return '화';
    if (emotionLower == 'contempt') return '경멸';
    if (emotionLower == 'sadness') return '슬픔';
    if (emotionLower == 'depression') return '우울';
    if (emotionLower == 'guilt') return '죄책감';
    if (emotionLower == 'fear') return '공포';
    if (emotionLower == 'shame') return '수치';
    if (emotionLower == 'confusion') return '혼란';
    if (emotionLower == 'boredom') return '무료';

    return emotion; // 기본값: 원본 반환
  }

  /// 감정 이름에 따른 색상 매핑 (HomeGaugeSection과 동일한 로직)
  Color _getWeeklyReportEmotionColor(String emotion) {
    final emotionLower = emotion.toLowerCase();

    // joy/happiness
    if (emotionLower.contains('joy') || emotionLower.contains('기쁨')) {
      return AppColors.weeklyJoy;
    }
    if (emotionLower.contains('happiness') || emotionLower.contains('행복')) {
      return AppColors.weeklyHappiness;
    }

    // excitement
    if (emotionLower.contains('excitement') || emotionLower.contains('흥분')) {
      return AppColors.weeklyExcitement;
    }

    // confidence
    if (emotionLower.contains('confidence') || emotionLower.contains('자신감')) {
      return AppColors.weeklyConfidence;
    }

    // love
    if (emotionLower.contains('love') || emotionLower.contains('사랑')) {
      return AppColors.weeklyLove;
    }

    // relief / stability
    if (emotionLower.contains('relief') ||
        emotionLower.contains('안심') ||
        emotionLower.contains('안정')) {
      return AppColors.weeklyRelief;
    }

    // enlightenment
    if (emotionLower.contains('enlightenment') ||
        emotionLower.contains('깨달음')) {
      return AppColors.weeklyEnlightenment;
    }

    // interest / motivation
    if (emotionLower.contains('interest') ||
        emotionLower.contains('흥미') ||
        emotionLower.contains('의욕')) {
      return AppColors.weeklyInterest;
    }

    // discontent
    if (emotionLower.contains('discontent') || emotionLower.contains('불만')) {
      return AppColors.weeklyDiscontent;
    }

    // anger
    if (emotionLower.contains('anger') ||
        emotionLower.contains('화') ||
        emotionLower.contains('분노')) {
      return AppColors.weeklyAnger;
    }

    // contempt
    if (emotionLower.contains('contempt') || emotionLower.contains('경멸')) {
      return AppColors.weeklyContempt;
    }

    // sadness
    if (emotionLower.contains('sadness') || emotionLower.contains('슬픔')) {
      return AppColors.weeklySadness;
    }

    // depression
    if (emotionLower.contains('depression') || emotionLower.contains('우울')) {
      return AppColors.weeklyDepression;
    }

    // guilt
    if (emotionLower.contains('guilt') || emotionLower.contains('죄책감')) {
      return AppColors.weeklyGuilt;
    }

    // fear/anxiety/worry
    if (emotionLower.contains('fear') ||
        emotionLower.contains('공포') ||
        emotionLower.contains('불안') ||
        emotionLower.contains('걱정')) {
      return AppColors.weeklyFear;
    }

    // shame
    if (emotionLower.contains('shame') || emotionLower.contains('수치')) {
      return AppColors.weeklyShame;
    }

    // confusion
    if (emotionLower.contains('confusion') || emotionLower.contains('혼란')) {
      return AppColors.weeklyConfusion;
    }

    // boredom
    if (emotionLower.contains('boredom') ||
        emotionLower.contains('무료') ||
        emotionLower.contains('지루')) {
      return AppColors.weeklyBoredom;
    }

    return AppColors.primaryColor;
  }
}
