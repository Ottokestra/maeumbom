import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// 날짜 선택 컴포넌트 (화살표 네비게이션)
/// 
/// 알람 화면 상단에 표시되는 날짜 선택기
/// 좌우 화살표로 날짜를 변경할 수 있음
class DateRangeSelector extends StatelessWidget {
  final DateTime selectedDate;
  final DateTime? endDate; // 종료일 (옵션)
  final VoidCallback? onPreviousDay;
  final VoidCallback? onNextDay;
  final VoidCallback? onDateTap; // 날짜 텍스트 탭 콜백

  const DateRangeSelector({
    super.key,
    required this.selectedDate,
    this.endDate,
    this.onPreviousDay,
    this.onNextDay,
    this.onDateTap,
  });

  /// 날짜 포맷팅
  String _formatDate(DateTime date) {
    final dateFormat = DateFormat('yyyy-MM-dd', 'ko_KR');
    final weekdayFormat = DateFormat('EEEE', 'ko_KR');
    return '${dateFormat.format(date)} ${weekdayFormat.format(date)}';
  }

  /// 날짜 범위 포맷팅
  String _formatDateRange() {
    final dateFormat = DateFormat('yyyy-MM-dd', 'ko_KR');
    // 종료일이 있고 시작일과 다르면 범위 표시
    if (endDate != null && !isSameDay(selectedDate, endDate!)) {
      return '${dateFormat.format(selectedDate)} ~ ${dateFormat.format(endDate!)}';
    }
    // 단일 날짜 표시 (요일 포함)
    return _formatDate(selectedDate);
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 이전 날짜 버튼
          IconButton(
            icon: const Icon(Icons.chevron_left),
            iconSize: 28,
            color: AppColors.textPrimary,
            onPressed: onPreviousDay,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
          ),
          
          const SizedBox(width: AppSpacing.sm),
          
          // 날짜 텍스트
          Expanded(
            child: GestureDetector(
              onTap: onDateTap,
              behavior: HitTestBehavior.opaque,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatDateRange(),
                      style: AppTypography.body.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 24,
                      ),
                      textAlign: TextAlign.center,
                    ),

                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(width: AppSpacing.sm),
          
          // 다음 날짜 버튼
          IconButton(
            icon: const Icon(Icons.chevron_right),
            iconSize: 28,
            color: AppColors.textPrimary,
            onPressed: onNextDay,
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
