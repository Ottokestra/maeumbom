import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../ui/app_ui.dart';
import '../../../providers/target_events_provider.dart';
import '../../../data/models/target_events/daily_event_model.dart';
import '../../../core/utils/logger.dart';
import '../../../core/services/navigation/navigation_service.dart';
import 'emotion_donut_chart_painter.dart';
import 'home_gauge_section.dart'; // EmotionSegment 임포트

// ----- 컴포넌트 -----

class HomeCardSection extends ConsumerStatefulWidget {
  const HomeCardSection({super.key});

  @override
  ConsumerState<HomeCardSection> createState() => _HomeCardSectionState();
}

class _HomeCardSectionState extends ConsumerState<HomeCardSection> {
  final PageController _pageController = PageController();

  // 상태 데이터
  List<EmotionSegment> _emotionSegments = [];
  String _emotionSummary = '데이터를 분석 중입니다...';
  List<DailyEventModel> _dailyEvents = [];
  bool _isLoading = true;

  // 자동 슬라이드 관련
  Timer? _autoSlideTimer;
  int _currentPage = 0;

  // 시뮬레이션용 날짜 (요청사항: 2025-12-15)
  // 실제 앱에서는 DateTime.now()를 사용하거나 Provider에서 가져와야 함
  final DateTime _targetDate = DateTime(2025, 12, 15);

  @override
  void initState() {
    super.initState();
    _loadData();
    _startAutoSlide();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // 자동 슬라이드 시작
  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        final nextPage = (_currentPage + 1) % 2; // 2개의 카드 순환
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // 페이지 변경 핸들러
  void _handlePageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  Future<void> _loadData() async {
    try {
      final apiClient = ref.read(targetEventsApiClientProvider);

      // 1. 감정 데이터 로드 (주간 데이터)
      // 12/15일 이전 데이터 조회 (User Request: 12/15일 이전으로 조회)
      // HomeGaugeSection과 동일하게 12/14일 기준 과거 60일 데이터 조회
      final emotionEndDate = DateTime(2025, 12, 14);
      final emotionStartDate =
          emotionEndDate.subtract(const Duration(days: 60));

      final weeklyEvents = await apiClient.getWeeklyEvents(
        startDate: emotionStartDate,
        endDate: emotionEndDate,
      );

      // 2. 일간 데이터 로드 (메모리 카드용)
      final dailyResponse = await apiClient.getDailyEvents(
        startDate: _targetDate,
        endDate: _targetDate,
        // eventType 필터 제거하여 모든 타입 조회
      );

      if (mounted) {
        setState(() {
          // 감정 데이터 처리
          if (weeklyEvents.isNotEmpty) {
            final firstEvent = weeklyEvents.first;
            _emotionSegments =
                _convertToSegments(firstEvent.emotionDistribution);
            _emotionSummary = _generateEmotionSummary(_emotionSegments);
          } else {
            _emotionSummary = '분석할 감정 데이터가 부족해요';
          }

          // 일간 데이터 처리
          _dailyEvents = dailyResponse.dailyEvents;

          _isLoading = false;
        });
      }
    } catch (e) {
      appLogger.e('HomeCardSection load failed', error: e);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _emotionSummary = '데이터를 불러오는데 실패했어요';
        });
      }
    }
  }

  // 감정 데이터 변환 로직
  List<EmotionSegment> _convertToSegments(
      Map<String, dynamic> emotionDistribution) {
    if (emotionDistribution.isEmpty) return [];

    final entries = emotionDistribution.entries.toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value as num));

    final top5 = entries.take(5);

    return top5.map((entry) {
      return EmotionSegment(
        label: entry.key,
        percentage: (entry.value as num).toDouble(),
        color: _getEmotionColor(entry.key),
      );
    }).toList();
  }

  // 감정 색상 (HomeGaugeSection 로직 복사)
  Color _getEmotionColor(String emotion) {
    final emotionLower = emotion.toLowerCase();

    // joy/happiness
    if (emotionLower.contains('joy') || emotionLower.contains('기쁨'))
      return AppColors.weeklyJoy;
    if (emotionLower.contains('happiness') || emotionLower.contains('행복'))
      return AppColors.weeklyHappiness;

    // excitement
    if (emotionLower.contains('excitement') || emotionLower.contains('흥분'))
      return AppColors.weeklyExcitement;

    // confidence
    if (emotionLower.contains('confidence') || emotionLower.contains('자신감'))
      return AppColors.weeklyConfidence;

    // love
    if (emotionLower.contains('love') || emotionLower.contains('사랑'))
      return AppColors.weeklyLove;

    // relief / stability
    if (emotionLower.contains('relief') ||
        emotionLower.contains('안심') ||
        emotionLower.contains('안정')) return AppColors.weeklyRelief;

    // enlightenment
    if (emotionLower.contains('enlightenment') || emotionLower.contains('깨달음'))
      return AppColors.weeklyEnlightenment;

    // interest / motivation
    if (emotionLower.contains('interest') ||
        emotionLower.contains('흥미') ||
        emotionLower.contains('의욕')) return AppColors.weeklyInterest;

    // discontent
    if (emotionLower.contains('discontent') || emotionLower.contains('불만'))
      return AppColors.weeklyDiscontent;

    // anger
    if (emotionLower.contains('anger') ||
        emotionLower.contains('화') ||
        emotionLower.contains('분노')) return AppColors.weeklyAnger;

    // contempt
    if (emotionLower.contains('contempt') || emotionLower.contains('경멸'))
      return AppColors.weeklyContempt;

    // sadness
    if (emotionLower.contains('sadness') || emotionLower.contains('슬픔'))
      return AppColors.weeklySadness;

    // depression
    if (emotionLower.contains('depression') || emotionLower.contains('우울'))
      return AppColors.weeklyDepression;

    // guilt
    if (emotionLower.contains('guilt') || emotionLower.contains('죄책감'))
      return AppColors.weeklyGuilt;

    // fear/anxiety/worry
    if (emotionLower.contains('fear') ||
        emotionLower.contains('공포') ||
        emotionLower.contains('불안') ||
        emotionLower.contains('걱정')) return AppColors.weeklyFear;

    // shame
    if (emotionLower.contains('shame') || emotionLower.contains('수치'))
      return AppColors.weeklyShame;

    // confusion
    if (emotionLower.contains('confusion') || emotionLower.contains('혼란'))
      return AppColors.weeklyConfusion;

    // boredom
    if (emotionLower.contains('boredom') ||
        emotionLower.contains('무료') ||
        emotionLower.contains('지루')) return AppColors.weeklyBoredom;

    return AppColors.primaryColor;
  }

  // 감정 요약 문구 생성
  String _generateEmotionSummary(List<EmotionSegment> segments) {
    if (segments.isEmpty) return '아직 기록된 감정이 없어요';

    final topEmotion = segments.first;
    return '이번 주는 ${topEmotion.label}이(가) 많이 나오셨네요';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 330, // 카드 높이 증가 (스크롤 여유 공간 확보)
      child: Stack(
        children: [
          // PageView 영역
          PageView(
            controller: _pageController,
            onPageChanged: _handlePageChanged,
            children: [
              _buildEmotionCard(),
              _buildMemoryCard(),
            ],
          ),

          // 상단 페이지 인디케이터 (카드 내부 상단)
          Positioned(
            top: AppSpacing.md,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(2, (index) {
                return Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? AppColors.primaryColor
                        : AppColors.borderLightGray,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // --- 1. 감정 분석 카드 ---
  Widget _buildEmotionCard() {
    return _buildBaseCard(
      title: '이 주의 감정 분석',
      buttonText: '마음 리포트 확인하기',
      onPressed: () {
        NavigationService(context, ref).navigateToRoute('/report');
      },
      child: Column(
        children: [
          // 요약 텍스트
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            child: Text(
              _emotionSummary,
              style: AppTypography.body.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          if (_emotionSegments.isNotEmpty) ...[
            // 차트 영역
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              height: 40,
              width: double.infinity,
              child: CustomPaint(
                painter: EmotionDonutChartPainter(segments: _emotionSegments),
              ),
            ),

            const SizedBox(height: AppSpacing.xxs),

            // 범례 (Full Legend - 1줄 배치)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly, // 균등 배치
                crossAxisAlignment: CrossAxisAlignment.start, // 상단 정렬
                children: _emotionSegments.map((segment) {
                  return _buildLegendItem(
                    label: segment.label,
                    color: segment.color,
                    percentage: segment.percentage,
                  );
                }).toList(),
              ),
            ),
          ] else
            Expanded(
              child: Center(
                child: const Icon(Icons.sentiment_neutral,
                    size: 60, color: AppColors.textSecondary),
              ),
            ),
        ],
      ),
    );
  }

  /// 범례 아이템 빌더 (세로 스택 구조: 색상점 - 타이틀 - 퍼센트)
  Widget _buildLegendItem({
    required String label,
    required Color color,
    required double percentage,
  }) {
    return Column(
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
        const SizedBox(height: 6),

        // 감정 이름
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),

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
    );
  }

  // --- 2. 오늘의 중요 기억 카드 ---
  Widget _buildMemoryCard() {
    return _buildBaseCard(
      title: '오늘의 중요 기억',
      buttonText: '기억서랍으로 이동',
      onPressed: () {
        // 기억서랍(알람화면)으로 이동하며 날짜 컨텍스트 전달 필요 (추후 구현)
        NavigationService(context, ref)
            .navigateToTab(1); // 1번 탭이 기억서랍(AlarmScreen)
      },
      child: _dailyEvents.isEmpty
          ? Center(
              child: Text(
                '오늘의 기록이 없어요',
                style:
                    AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.zero,
              physics:
                  const NeverScrollableScrollPhysics(), // 카드 내 스크롤 방지 (공간 부족시 변경)
              itemCount: _dailyEvents.take(3).length, // 최대 3개까지만 표시
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final event = _dailyEvents[index];
                final time = event.eventTime ?? DateTime.now();
                final timeStr =
                    '${time.hour}:${time.minute.toString().padLeft(2, '0')}';

                // 타입별 설정
                String badgeLabel;
                Color badgeColor;
                Color badgeTextColor = Colors.white;

                switch (event.eventType.toLowerCase()) {
                  case 'alarm':
                    badgeLabel = '알림';
                    badgeColor = const Color(0xFFFFB84C);
                    break;
                  case 'event':
                    badgeLabel = '이벤트';
                    badgeColor = const Color(0xFF6C8CD5);
                    break;
                  case 'memory':
                  default:
                    badgeLabel = '기억';
                    badgeColor = const Color(0xFFFF8A80);
                    break;
                }

                return Row(
                  children: [
                    // 뱃지
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeLabel,
                        style: AppTypography.caption.copyWith(
                          color: badgeTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 시간
                    Text(
                      timeStr,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 내용 (제목)
                    Expanded(
                      child: Text(
                        event.eventSummary,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  // 공통 카드 레이아웃
  Widget _buildBaseCard({
    required String title,
    required String buttonText,
    required VoidCallback onPressed,
    required Widget child,
  }) {
    return Container(
      // 가로 마진 제거하여 하단 버튼과 너비 맞춤 (이미 부모 패딩 존재)
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.xl, // 상단 여백 증가 (인디케이터 공간 확보)
        bottom: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 상단 타이틀
          Text(
            title,
            style: AppTypography.bodyLarge.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          // 메인 컨텐츠
          Expanded(
            child: child,
          ),

          const SizedBox(height: AppSpacing.xs),

          // 하단 버튼
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE54B55), // 붉은색 버튼 (이미지 참조)
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                buttonText,
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
