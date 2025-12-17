import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../ui/app_ui.dart';
import '../../../providers/target_events_provider.dart';
import '../../../core/utils/logger.dart';
import 'emotion_donut_chart_painter.dart';

/// 감정 세그먼트 데이터 모델
class EmotionSegment {
  final String label;
  final double percentage;
  final Color color;

  const EmotionSegment({
    required this.label,
    required this.percentage,
    required this.color,
  });
}

class HomeGaugeSection extends ConsumerStatefulWidget {
  final double temperaturePercentage;
  final Color emotionColor;

  const HomeGaugeSection({
    super.key,
    required this.temperaturePercentage,
    required this.emotionColor,
  });

  @override
  ConsumerState<HomeGaugeSection> createState() => _HomeGaugeSectionState();
}

class _HomeGaugeSectionState extends ConsumerState<HomeGaugeSection> {
  @override
  void initState() {
    super.initState();
    // 컴포넌트 마운트 시 주간 이벤트 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 12/15일 이전 데이터 조회 (12/14까지)
      final endDate = DateTime(2025, 12, 14);
      final startDate = endDate.subtract(const Duration(days: 60)); // 60일 전부터
      
      appLogger.d('📊 [HomeGaugeSection] Loading weekly events from $startDate to $endDate');
      ref.read(weeklyEventsProvider.notifier).loadWeeklyEvents(
        startDate: startDate,
        endDate: endDate,
      );
    });
  }

  static Color getWeeklyReportEmotionColor(String emotion) {
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
    if (emotionLower.contains('relief') || emotionLower.contains('안심') ||
        emotionLower.contains('안정')) {
      return AppColors.weeklyRelief;
    }

    // enlightenment
    if (emotionLower.contains('enlightenment') || emotionLower.contains('깨달음')) {
      return AppColors.weeklyEnlightenment;
    }

    // interest / motivation
    if (emotionLower.contains('interest') || emotionLower.contains('흥미') ||
        emotionLower.contains('의욕')) {
      return AppColors.weeklyInterest;
    }

    // discontent
    if (emotionLower.contains('discontent') || emotionLower.contains('불만')) {
      return AppColors.weeklyDiscontent;
    }

    // anger
    if (emotionLower.contains('anger') || emotionLower.contains('화') ||
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
    if (emotionLower.contains('fear') || emotionLower.contains('공포') ||
        emotionLower.contains('불안') || emotionLower.contains('걱정')) {
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
    if (emotionLower.contains('boredom') || emotionLower.contains('무료') ||
        emotionLower.contains('지루')) {
      return AppColors.weeklyBoredom;
    }

    return AppColors.primaryColor;
  }

  /// API 데이터를 EmotionSegment 리스트로 변환
  List<EmotionSegment> _convertToSegments(Map<String, dynamic> emotionDistribution) {
    if (emotionDistribution.isEmpty) {
      return [];
    }

    // Map을 List로 변환하고 퍼센트 기준 내림차순 정렬
    final entries = emotionDistribution.entries.toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value as num));

    // 상위 5개만 선택
    final top5 = entries.take(5);

    return top5.map((entry) {
      final emotion = entry.key;
      final percentage = (entry.value as num).toDouble();
      final color = getWeeklyReportEmotionColor(emotion);

      return EmotionSegment(
        label: emotion,
        percentage: percentage,
        color: color,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final weeklyEventsState = ref.watch(weeklyEventsProvider);

    return weeklyEventsState.when(
      data: (weeklyEvents) {
        appLogger.d('📊 [HomeGaugeSection] Weekly events count: ${weeklyEvents.length}');
        
        // 데이터가 있으면 첫 번째 주간 이벤트 사용
        List<EmotionSegment> segments;
        
        if (weeklyEvents.isNotEmpty) {
          final firstEvent = weeklyEvents.first;
          appLogger.d('📊 [HomeGaugeSection] First event emotion_distribution: ${firstEvent.emotionDistribution}');
          appLogger.d('📊 [HomeGaugeSection] Primary emotion: ${firstEvent.primaryEmotion}');
          appLogger.d('📊 [HomeGaugeSection] Sentiment: ${firstEvent.sentimentOverall}');
          
          if (firstEvent.emotionDistribution.isNotEmpty) {
            segments = _convertToSegments(firstEvent.emotionDistribution);
            appLogger.d('📊 [HomeGaugeSection] Converted segments count: ${segments.length}');
            for (var segment in segments) {
              appLogger.d('  - ${segment.label}: ${segment.percentage}%');
            }
          } else {
            appLogger.w('⚠️ [HomeGaugeSection] emotion_distribution is empty');
            segments = [];
          }
        } else {
          appLogger.w('⚠️ [HomeGaugeSection] No weekly events data');
          segments = [];
        }

        return _buildContent(segments);
      },
      loading: () => _buildContent([]), // 로딩 중에는 빈 상태 표시
      error: (error, stack) => _buildContent([]), // 에러 시에도 빈 상태 표시
    );
  }

  Widget _buildContent(List<EmotionSegment> segments) {
    final hasData = segments.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.basicColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 4),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 10),
            spreadRadius: -3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타이틀
          Text(
            '이번 달 기록한 감정',
            style: AppTypography.body.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          if (hasData) ...[
            // 가로형 막대 차트
            SizedBox(
              width: double.infinity,
              height: 40,
              child: CustomPaint(
                painter: EmotionDonutChartPainter(segments: segments),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // 범례 (Legend)
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              alignment: WrapAlignment.center,
              children: segments.map((segment) {
                return _buildLegendItem(
                  label: segment.label,
                  color: segment.color,
                  percentage: segment.percentage,
                );
              }).toList(),
            ),
          ] else ...[
            // 데이터 없을 때 표시
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text(
                  '아직 기록된 감정이 없어요',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 범례 아이템 빌더 (Chip 스타일 개선)
  Widget _buildLegendItem({
    required String label,
    required Color color,
    required double percentage,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1), // 연한 배경
        borderRadius: BorderRadius.circular(20), // 둥근 모서리
        border: Border.all(
          color: color.withOpacity(0.2), // 연한 테두리
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 색상 인디케이터
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          
          // 감정 이름
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          
          // 퍼센트
          Text(
            '${percentage.toInt()}%',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
