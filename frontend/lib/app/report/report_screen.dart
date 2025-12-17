import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui/app_ui.dart';
import '../../ui/components/weekly_calendar_selector.dart';
import '../../core/services/navigation/navigation_service.dart';
import 'pages/report_page1.dart';
import 'pages/report_page2.dart';
import 'pages/report_page3.dart';

/// Report Screen - 마음리포트 화면
class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
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

  /// 날짜 범위 선택기 표시
  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: AppColors.pureWhite,
              onSurface: AppColors.textPrimary,
              surface: AppColors.pureWhite,
            ),
            datePickerTheme: DatePickerThemeData(
              rangeSelectionBackgroundColor: AppColors.accentCoral.withOpacity(0.3),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final navigationService = NavigationService(context, ref);

    return AppFrame(
      statusBarStyle: const SystemUiOverlayStyle(
        statusBarColor: AppColors.primaryColor,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      topBar: null,
      useSafeArea: false,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 상단 영역 (primaryColor 배경)
            Container(
              color: AppColors.primaryColor,
              child: Column(
                children: [
                  // 상단 바
                  TopBar(
                    title: '마음리포트',
                    leftIcon: Icons.arrow_back_ios,
                    rightIcon: Icons.more_horiz,
                    onTapLeft: () => navigationService.navigateToTab(0),
                    onTapRight: () => MoreMenuSheet.show(context),
                    backgroundColor: Colors.transparent,
                    foregroundColor: AppColors.basicColor,
                  ),
                  // 주간 캘린더 선택기
                  WeeklyCalendarSelector(
                    startDate: _startDate,
                    endDate: _endDate,
                    onPreviousWeek: _goToPreviousWeek,
                    onNextWeek: _goToNextWeek,
                    onDateTap: _showDateRangePicker,
                  ),
                ],
              ),
            ),
            // 리포트 컨텐츠 (bgBasic 배경)
            Expanded(
              child: ReportContentBody(
                startDate: _startDate,
                endDate: _endDate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Report Content Body (리포트 본문)
class ReportContentBody extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;

  const ReportContentBody({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgBasic,
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.md),

            // 페이지 1: 이번주 감정 온도
            ReportPage1(
              startDate: startDate,
              endDate: endDate,
            ),

            const SizedBox(height: AppSpacing.xl),

            // 페이지 2: 요일별 감정 캐릭터
            ReportPage2(
              startDate: startDate,
              endDate: endDate,
            ),

            const SizedBox(height: AppSpacing.xl),

            // 페이지 3: 이번주 감정 분석 상세
            ReportPage3(
              startDate: startDate,
              endDate: endDate,
            ),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
