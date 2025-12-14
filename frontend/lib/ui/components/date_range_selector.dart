import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

/// 날짜 범위 선택 컴포넌트
/// 
/// 알람 화면 상단에 표시되는 날짜 범위 선택기
/// 탭하면 날짜 선택 다이얼로그가 열림
class DateRangeSelector extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final VoidCallback onTap;

  const DateRangeSelector({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onTap,
  });

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final startStr = _formatDate(startDate);
    final endStr = _formatDate(endDate);

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
          children: [
            // 캘린더 아이콘
            Icon(
              Icons.calendar_today,
              size: 20,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            
            // 날짜 범위 텍스트
            Text(
              '$startStr - $endStr',
              style: AppTypography.body.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const Spacer(),
            
            // 화살표 아이콘
            Icon(
              Icons.keyboard_arrow_down,
              size: 24,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
