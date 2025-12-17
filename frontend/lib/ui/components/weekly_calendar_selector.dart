import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// 주간 캘린더 선택 컴포넌트
/// 
/// 리포트 화면 상단에 표시되는 주간 캘린더
/// 좌우 화살표로 주차를 변경할 수 있음
/// "12월 1주차" 형식으로 표시
class WeeklyCalendarSelector extends StatelessWidget {
  final DateTime startDate; // 주의 시작일 (월요일)
  final DateTime endDate; // 주의 종료일 (일요일)
  final VoidCallback? onPreviousWeek;
  final VoidCallback? onNextWeek;
  final VoidCallback? onDateTap; // 날짜 텍스트 탭 콜백

  const WeeklyCalendarSelector({
    super.key,
    required this.startDate,
    required this.endDate,
    this.onPreviousWeek,
    this.onNextWeek,
    this.onDateTap,
  });

  /// 주차 라벨 포맷팅 (예: "12월 1주차")
  String _formatWeekLabel() {
    final month = startDate.month;
    final weekOfMonth = ((startDate.day - 1) ~/ 7) + 1;
    return '$month월 ${weekOfMonth}주차';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.basicColor,
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 이전 주 버튼
          IconButton(
            icon: const Icon(Icons.chevron_left),
            iconSize: 28,
            color: AppColors.textPrimary,
            onPressed: onPreviousWeek,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
          ),

          // 중앙 주차 표시
          GestureDetector(
            onTap: onDateTap,
            child: Text(
              _formatWeekLabel(),
              style: AppTypography.h3.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // 다음 주 버튼
          IconButton(
            icon: const Icon(Icons.chevron_right),
            iconSize: 28,
            color: AppColors.textPrimary,
            onPressed: onNextWeek,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
          ),
        ],
      ),
    );
  }
}
