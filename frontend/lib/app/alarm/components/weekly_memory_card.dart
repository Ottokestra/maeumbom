import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/target_events/weekly_event_model.dart';
import '../../../ui/app_ui.dart';

/// 주간 기억 카드 컴포넌트
/// 
/// 주간 이벤트 요약을 관계별로 그룹화하여 표시
class WeeklyMemoryCard extends StatefulWidget {
  final WeeklyEventModel event;
  final VoidCallback? onTap;

  const WeeklyMemoryCard({
    super.key,
    required this.event,
    this.onTap,
  });

  @override
  State<WeeklyMemoryCard> createState() => _WeeklyMemoryCardState();
}

class _WeeklyMemoryCardState extends State<WeeklyMemoryCard> {
  bool _isExpanded = false;

  /// 관계 타입에 따른 색상 반환
  Color _getTargetColor(String targetType) {
    switch (targetType) {
      case 'SELF':
        return const Color(0xFFD7454D); // 빨강
      case 'HUSBAND':
        return const Color(0xFF9B59B6); // 보라
      case 'FRIEND':
        return const Color(0xFFFFB84C); // 오렌지
      case 'CHILD':
        return const Color(0xFF3498DB); // 파랑
      default:
        return AppColors.textSecondary;
    }
  }

  /// 관계 타입 한글 라벨
  String _getTargetLabel(String targetType) {
    switch (targetType) {
      case 'SELF':
        return '나';
      case 'HUSBAND':
        return '가족';
      case 'FRIEND':
        return '친구';
      case 'CHILD':
        return '자녀';
      default:
        return targetType;
    }
  }

  /// 날짜 포맷팅 (월.일)
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.month}.${date.day}';
    } catch (e) {
      return dateStr;
    }
  }

  /// 주간 범위 포맷팅
  String _formatWeekRange() {
    final dateFormat = DateFormat('M월 dd일', 'ko_KR');
    final weekStart = widget.event.weekStart;
    final weekEnd = widget.event.weekEnd;
    
    if (weekStart == null || weekEnd == null) {
      return '날짜 정보 없음';
    }
    
    return '${dateFormat.format(weekStart)} ~ ${dateFormat.format(weekEnd)}';
  }

  @override
  Widget build(BuildContext context) {
    final targetColor = _getTargetColor(widget.event.targetType ?? '');
    final targetLabel = _getTargetLabel(widget.event.targetType ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x19000000),
            blurRadius: 2,
            offset: Offset(0, 1),
            spreadRadius: -1,
          ),
          BoxShadow(
            color: Color(0x19000000),
            blurRadius: 3,
            offset: Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더 (항상 표시)
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
              widget.onTap?.call();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 주간 범위
                        Text(
                          _formatWeekRange(),
                          style: const TextStyle(
                            color: Color(0xFF243447),
                            fontSize: 16,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w700,
                            height: 1.50,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // 관계별 배지
                        Row(
                          children: [
                            Container(
                              height: 24,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: ShapeDecoration(
                                color: targetColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16777200),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '$targetLabel ${widget.event.totalEvents}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w600,
                                    height: 1.33,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // 확장 아이콘
                  Transform.rotate(
                    angle: _isExpanded ? 3.14 : 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      child: Icon(
                        Icons.expand_more,
                        size: 20,
                        color: const Color(0xFF666666),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 확장된 내용
          if (_isExpanded) ...[
            Container(
              width: double.infinity,
              decoration: const ShapeDecoration(
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    width: 1,
                    color: Color(0xFFF2F4F6),
                  ),
                ),
              ),
              child: Column(
                children: [
                  // 일자별 요약 목록 (회색 배경)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 16),
                    decoration: const BoxDecoration(color: Color(0xFFF9F9F9)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: widget.event.eventsSummary.map((summary) {
                        final dateStr = summary['date'] as String;
                        final text = summary['summary'] as String;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 40,
                                child: Text(
                                  _formatDate(dateStr),
                                  style: TextStyle(
                                    color: targetColor,
                                    fontSize: 14,
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w700,
                                    height: 1.43,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  text,
                                  style: const TextStyle(
                                    color: Color(0xFF666666),
                                    fontSize: 14,
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w400,
                                    height: 1.43,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  
                  // 태그 표시 (있는 경우)
                  if (widget.event.tags.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.event.tags.map((tag) {
                          return Container(
                            height: 24,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: ShapeDecoration(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16777200),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '#$tag',
                                style: const TextStyle(
                                  color: Color(0xFF666666),
                                  fontSize: 12,
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w500,
                                  height: 1.33,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

