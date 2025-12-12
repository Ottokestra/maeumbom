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
class ReportContent extends StatelessWidget {
  const ReportContent({super.key});

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
                  onPressed: () {
                    // TODO: 이전 주로 이동
                  },
                ),

                // 중앙 날짜 표시
                Text(
                  '2025년 1월 1주차',
                  style: AppTypography.h3.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                // 오른쪽 화살표
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  color: AppColors.textSecondary,
                  onPressed: () {
                    // TODO: 다음 주로 이동
                  },
                ),
              ],
            ),
          ),

          // 페이지 1: 이번주 감정 온도
          const ReportPage1(),

          const SizedBox(height: AppSpacing.xl),

          // 페이지 2: 요일별 감정 캐릭터
          const ReportPage2(),

          const SizedBox(height: AppSpacing.xl),

          // 페이지 3: 이번주 감정 분석 상세
          const ReportPage3(),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}