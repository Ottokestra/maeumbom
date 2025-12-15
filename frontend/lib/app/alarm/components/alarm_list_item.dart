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
    this.isHighlighted = false,
  });

  /// 알림 데이터
  final AlarmModel alarm;

  /// 강조 표시 여부 (테두리 primaryColor 적용)
  final bool isHighlighted;

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

  /// content에서 태그와 본문을 분리
  Map<String, dynamic> get _parsedContent {
    if (alarm.content == null || alarm.content!.isEmpty) {
      return {'text': '', 'tags': <String>[]};
    }

    final lines = alarm.content!.split('\n');
    final text = <String>[];
    final tags = <String>[];

    for (final line in lines) {
      if (line.trim().startsWith('#')) {
        // 태그 라인
        tags.addAll(
          line.split(' ').where((word) => word.startsWith('#')),
        );
      } else {
        // 일반 텍스트
        text.add(line);
      }
    }

    return {
      'text': text.join('\n').trim(),
      'tags': tags,
    };
  }

  /// 태그 색상 생성 (키워드 기반 + 해시 기반)
  Color _getTagColor(String tag) {
    // 태그에서 # 제거하고 소문자로 변환
    final keyword = tag.replaceAll('#', '').toLowerCase();

    // 키워드별 색상 매핑
    if (keyword.contains('알람') || keyword.contains('알림')) {
      return const Color(0xFFFFB84C); // 알람 아이콘과 동일한 노랑/오렌지
    } else if (keyword.contains('중요') || keyword.contains('긴급')) {
      return const Color(0xFFD7454D); // 붉은색 계열
    } else if (keyword.contains('약속') ||
        keyword.contains('미팅') ||
        keyword.contains('회의')) {
      return const Color(0xFF7BC67E); // 초록색 계열
    } else if (keyword.contains('기억') || keyword.contains('추억')) {
      return const Color(0xFFFF8A80); // 핑크/산호색
    } else if (keyword.contains('이벤트') || keyword.contains('행사')) {
      return const Color(0xFF6C8CD5); // 파랑색
    }

    // 기타 태그는 해시 기반 색상
    final hash = tag.hashCode;
    final colors = [
      const Color(0xFF64B5F6), // 하늘
      const Color(0xFFB47AEA), // 보라
      const Color(0xFFFFD54F), // 금색
      const Color(0xFF81C784), // 연두
      const Color(0xFFFF8A65), // 주황
      const Color(0xFF9575CD), // 연보라
    ];
    return colors[hash.abs() % colors.length];
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
            color: isHighlighted ? AppColors.primaryColor : AppColors.borderLightGray,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1줄: 아이콘 + 타입 배지 + 시간 + 토글
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 타입별 아이콘 (왼쪽으로 이동)
                Container(
                  width: 36,
                  height: 36,
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
                    size: 18,
                  ),
                ),

                const SizedBox(width: AppSpacing.sm),

                // 타입 배지
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
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

                const SizedBox(width: AppSpacing.xs),

                // 시간
                Text(
                  alarm.timeString,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),

                const Spacer(),

                // 토글 (알림 타입만)
                if (alarm.itemType.needsToggle)
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

            const SizedBox(height: AppSpacing.sm),

            // 2줄: 내용 텍스트 + 태그 (전체 너비 사용)
            () {
              final parsed = _parsedContent;
              final text = parsed['text'] as String;
              final tags = parsed['tags'] as List<String>;

              if (text.isEmpty && tags.isEmpty) {
                return Text(
                  '내용 없음',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 본문 텍스트
                  if (text.isNotEmpty)
                    Text(
                      text,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  // 태그들
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: tags.map((tag) {
                        final color = _getTagColor(tag);
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: color.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            tag,
                            style: AppTypography.caption.copyWith(
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              );
            }(),
          ],
        ),
      ),
    );
  }
}
