import 'package:flutter/material.dart';
import '../../../ui/tokens/app_tokens.dart';
import '../../../data/models/alarm/alarm_model.dart';

/// 알람 리스트 아이템
///
/// 개별 알람 정보를 표시하고 토글 및 삭제 기능을 제공하는 컴포넌트
/// Dismissible을 사용하여 왼쪽 스와이프로 삭제할 수 있습니다.
class AlarmListItem extends StatelessWidget {
  const AlarmListItem({
    super.key,
    required this.alarm,
    required this.onToggle,
    required this.onDelete,
  });

  /// 알람 데이터
  final AlarmModel alarm;

  /// 토글 스위치 변경 콜백
  final ValueChanged<bool> onToggle;

  /// 삭제 콜백
  final VoidCallback onDelete;

  /// 요일 표시 문자열 (매일 또는 개별 요일)
  String get _weekDisplayString {
    if (alarm.week.isEmpty) return '';
    
    // 7개 요일이 모두 선택된 경우 "매일"로 표시
    if (alarm.week.length == 7) {
      return '매일';
    }
    
    // 개별 요일 표시
    const weekMap = {
      'Monday': '월',
      'Tuesday': '화',
      'Wednesday': '수',
      'Thursday': '목',
      'Friday': '금',
      'Saturday': '토',
      'Sunday': '일',
    };
    
    return alarm.week.map((w) => weekMap[w] ?? w).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(alarm.id.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.md),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.errorRed,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: const Icon(
          Icons.delete,
          color: AppColors.basicColor,
          size: 28,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.basicColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.borderLight,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 알람 정보 영역
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 시간 (크게 표시)
                  Text(
                    alarm.timeString,
                    style: AppTypography.h2.copyWith(
                      color: alarm.isEnabled
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 제목 (추후 API에서 세팅 예정)
                  if (alarm.title != null && alarm.title!.isNotEmpty) ...[
                    Text(
                      alarm.title!,
                      style: AppTypography.body.copyWith(
                        color: alarm.isEnabled
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  // 요일 표시
                  if (alarm.week.isNotEmpty)
                    Text(
                      _weekDisplayString,
                      style: AppTypography.caption.copyWith(
                        color: alarm.isEnabled
                            ? AppColors.textSecondary
                            : AppColors.disabledText,
                      ),
                    ),
                ],
              ),
            ),

            // 토글 스위치
            Transform.scale(
              scale: ToggleTokens.defaultScale,
              child: Switch(
                value: alarm.isEnabled,
                onChanged: onToggle,
                activeThumbColor: ToggleTokens.primaryActiveThumb,
                activeTrackColor: ToggleTokens.primaryActiveTrack,
                inactiveThumbColor: ToggleTokens.primaryInactiveThumb,
                inactiveTrackColor: ToggleTokens.primaryInactiveTrack,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
