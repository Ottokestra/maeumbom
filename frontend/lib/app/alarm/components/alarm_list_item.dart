import 'package:flutter/material.dart';
import '../../../ui/tokens/app_tokens.dart';
import '../../../data/models/alarm/alarm_model.dart';

/// 알람 리스트 아이템
///
/// 기억/알림/이벤트 세 가지 타입을 지원하며
/// 미래 일정(오늘 이후)만 표시합니다.
/// 알림 타입만 토글 스위치를 제공합니다.
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

  /// 날짜 표시 문자열 (MM/DD 형식)
  String get _dateString {
    return '${alarm.month.toString().padLeft(2, '0')}/${alarm.day.toString().padLeft(2, '0')}';
  }

  /// 요일 표시 문자열 (한글 단일 문자)
  String get _weekdayString {
    final date = DateTime(alarm.year, alarm.month, alarm.day);
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return weekdays[date.weekday - 1];
  }

  /// 아이콘 선택
  IconData get _typeIcon {
    switch (alarm.itemType) {
      case ItemType.memory:
        return Icons.favorite_outline;
      case ItemType.alarm:
        return Icons.notifications_outlined;
      case ItemType.event:
        return Icons.event_outlined;
    }
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
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.basicColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.borderLight,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 왼쪽: 날짜 + 요일
            Column(
              children: [
                Text(
                  _dateString,
                  style: AppTypography.bodyBold.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _weekdayString,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(width: AppSpacing.sm),

            // 중앙: 아이콘 + 내용
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 타입별 아이콘 배경
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: alarm.itemType.backgroundColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: alarm.itemType.textColor,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      _typeIcon,
                      color: alarm.itemType.textColor,
                      size: 20,
                    ),
                  ),

                  const SizedBox(width: AppSpacing.sm),

                  // 내용 영역
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 타입 배지
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: alarm.itemType.backgroundColor,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            alarm.itemType.label,
                            style: AppTypography.caption.copyWith(
                              color: alarm.itemType.textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),

                        // 시간 표시
                        Text(
                          alarm.timeString,
                          style: AppTypography.body.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 4),

                        // 내용 텍스트
                        if (alarm.content != null && alarm.content!.isNotEmpty)
                          Text(
                            alarm.content!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 오른쪽: 토글 (알림 타입만)
            if (alarm.itemType.needsToggle) ...[
              const SizedBox(width: AppSpacing.xs),
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
          ],
        ),
      ),
    );
  }
}
