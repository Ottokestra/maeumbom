import 'package:flutter/material.dart';
import '../../../ui/tokens/app_tokens.dart';
import '../../../data/models/alarm/alarm_model.dart';

/// 알람 리스트 아이템 (간소화 버전)
///
/// 알람 화면 전용 간소화 디자인
/// - 고정 높이 122px
/// - 3줄 레이아웃: 날짜/시간 → 제목 → 키워드 태그
class AlarmListItemSimple extends StatelessWidget {
  const AlarmListItemSimple({
    super.key,
    required this.alarm,
    this.isHighlighted = false,
  });

  /// 알림 데이터
  final AlarmModel alarm;

  /// 오늘 날짜 강조 표시 여부
  final bool isHighlighted;

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
    final parsed = _parsedContent;
    final text = parsed['text'] as String;
    final tags = parsed['tags'] as List<String>;

    return Container(
      width: double.infinity,
      height: 122,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.only(
        top: 17,
        left: 17,
        right: 17,
        bottom: 1,
      ),
      decoration: ShapeDecoration(
        color: isHighlighted ? AppColors.lightPink : const Color(0xFFF9F9F9),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: isHighlighted ? AppColors.errorRed : const Color(0xFFF0F0F0),
          ),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: 날짜 + 시간
            SizedBox(
              width: double.infinity,
              height: 20,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 날짜
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        clipBehavior: Clip.antiAlias,
                        decoration: const BoxDecoration(),
                        child: const Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${alarm.month}월 ${alarm.day}일',
                        style: const TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 14,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w500,
                          height: 1.43,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // 시간
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        clipBehavior: Clip.antiAlias,
                        decoration: const BoxDecoration(),
                        child: const Icon(
                          Icons.access_time,
                          size: 12,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        alarm.timeString,
                        style: const TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 14,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w500,
                          height: 1.43,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Row 2: 제목
            SizedBox(
              width: double.infinity,
              height: 24,
              child: Text(
                text.isNotEmpty ? text : '제목 없음',
                style: const TextStyle(
                  color: Color(0xFF243447),
                  fontSize: 16,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  height: 1.50,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 12),

            // Row 3: 키워드 태그
            SizedBox(
              width: double.infinity,
              height: 24,
              child: tags.isNotEmpty
                  ? Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          clipBehavior: Clip.antiAlias,
                          decoration: const BoxDecoration(),
                          child: const Icon(
                            Icons.tag,
                            size: 12,
                            color: Color(0xFF666666),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: tags.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 4),
                            itemBuilder: (context, index) {
                              final tag = tags[index];
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
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 11,
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w600,
                                    height: 1.33,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
  }
}
