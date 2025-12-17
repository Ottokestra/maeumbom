import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/app_ui.dart';
import '../../core/services/navigation/navigation_service.dart';
import 'pages/report_page1.dart';
import 'pages/report_page2.dart';
import 'pages/report_page3.dart';

/// Report Screen - 마음리포트 화면
class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationService = NavigationService(context, ref);

    return AppFrame(
      topBar: TopBar(
        title: '마음리포트',
        leftIcon: Icons.arrow_back_ios,
        rightIcon: Icons.more_horiz,
        onTapLeft: () => navigationService.navigateToTab(0),
        onTapRight: () => MoreMenuSheet.show(context),
      ),
      bottomBar: BottomMenuBar(
        currentIndex: 3,
        onTap: (index) {
          navigationService.navigateToTab(index);
        },
      ),
      body: const ReportContent(),
    );
  }
}

/// Report Content with Vertical Scroll
class ReportContent extends StatefulWidget {
  const ReportContent({super.key});

  @override
  State<ReportContent> createState() => _ReportContentState();
}

class _ReportContentState extends State<ReportContent> {
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // 이번 주 월요일 계산
    final weekday = now.weekday; // 1=월요일, 7=일요일
    _startDate = now.subtract(Duration(days: weekday - 1));
    _endDate = _startDate.add(const Duration(days: 6)); // 일요일
  }

  /// 이전 주차로 이동
  void _goToPreviousWeek() {
    setState(() {
      _startDate = _startDate.subtract(const Duration(days: 7));
      _endDate = _endDate.subtract(const Duration(days: 7));
    });
  }

  /// 다음 주차로 이동
  void _goToNextWeek() {
    setState(() {
      _startDate = _startDate.add(const Duration(days: 7));
      _endDate = _endDate.add(const Duration(days: 7));
    });
  }

  /// 주차 라벨 포맷팅 (예: "2025년 1월 1주차")
  String _formatWeekLabel() {
    final year = _startDate.year;
    final month = _startDate.month;
    final weekOfMonth = ((_startDate.day - 1) ~/ 7) + 1;
    return '$year년 $month월 ${weekOfMonth}주차';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 날짜 표시 헤더 (화살표 네비게이션)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 왼쪽 화살표
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  color: AppColors.textSecondary,
                  onPressed: _goToPreviousWeek,
                ),

                // 중앙 날짜 표시
                Text(
                  _formatWeekLabel(),
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                // 오른쪽 화살표
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  color: AppColors.textSecondary,
                  onPressed: _goToNextWeek,
                ),
              ],
            ),
          ),

          // 페이지 1: 이번주 감정 온도
          ReportPage1(
            startDate: _startDate,
            endDate: _endDate,
          ),

          const SizedBox(height: AppSpacing.md),

          // 페이지 2: 요일별 감정 캐릭터
          ReportPage2(
            startDate: _startDate,
            endDate: _endDate,
          ),

          const SizedBox(height: AppSpacing.md),

          // 페이지 3: 이번주 감정 분석 상세
          ReportPage3(
            startDate: _startDate,
            endDate: _endDate,
          ),

          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
