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
          color: AppColors.pureWhite,
          size: 28,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.borderLight,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // 알람 정보 영역
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 시간
                  Text(
                    alarm.timeString,
                    style: AppTypography.h3.copyWith(
                      color: alarm.isEnabled
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  // 날짜
                  Text(
                    alarm.dateString,
                    style: AppTypography.body.copyWith(
                      color: alarm.isEnabled
                          ? AppColors.textSecondary
                          : AppColors.disabledText,
                    ),
                  ),
                  // 요일 (있을 때만 표시)
                  if (alarm.week.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      alarm.weekString,
                      style: AppTypography.caption.copyWith(
                        color: alarm.isEnabled
                            ? AppColors.textSecondary
                            : AppColors.disabledText,
                      ),
                    ),
                  ],
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
